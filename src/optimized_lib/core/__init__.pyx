# src/optimized_lib/core/__init__.pyx
from libc.math cimport round as c_round
from cython.parallel import prange
cimport numpy as cnp
import numpy as np
from optimized_lib.types cimport PredictResponse
from optimized_lib.types.coordinates cimport (
    is_valid_coordinate,
    LAT_MIN, LAT_MAX, LON_MIN, LON_MAX,
    create_unsafe as create_coordinates_unsafe
)
from optimized_lib.types.search_result cimport (
    create_unsafe as create_search_result_unsafe
)
from optimized_lib.types.predict_response cimport (
    create_unsafe as create_predict_response_unsafe,
    create_not_found as create_not_found_response
)

# Earth radius in meters for haversine distance calculations.
# Standard value used in geodetic computations.
cdef const float EARTH_RADIUS_METERS = 6371000.0

# Mathematical constants for coordinate conversion.
cdef const float PI = 3.1415926
cdef const float DEG_TO_RAD = PI / 180.0


cdef inline void transform_coordinate_fast(
    float lat_deg, float lon_deg,
    float* lat_rad, float* lon_rad
) noexcept nogil:
    """
    Convert a single (lat, lon) coordinate pair from degrees to radians.

    Parameters
    ----------
    lat_deg : float
        Latitude in decimal degrees.
    lon_deg : float
        Longitude in decimal degrees.
    lat_rad : float*
        Pointer to store resulting latitude in radians.
    lon_rad : float*
        Pointer to store resulting longitude in radians.

    Notes
    -----
    The function is accessible from Cython code only. It is declared with:
    - ``inline`` — allows the Cython compiler to embed the function body directly 
        at the call site to eliminate call overhead 
        (which increases execution speed at the cost of larger code size).
    - ``noexcept`` — guarantees that the function never raises Python exceptions 
        (some form of except-modifier should usually be added for Cython compiler).
    - ``nogil`` — allows execution without holding the Python Global Interpreter Lock.
    - Uses pointer outputs to avoid struct/tuple overhead in tight loops.
    """

    lat_rad[0] = lat_deg * DEG_TO_RAD
    lon_rad[0] = lon_deg * DEG_TO_RAD


cpdef cnp.float32_t[:, ::1] transform_coordinates_fast(cnp.float32_t[:, ::1] coords):
    """
    Convert a batch of geographic coordinates from degrees to radians.

    Parameters
    ----------
    coords : cnp.float32_t[:, ::1]
        Two-dimensional typed memoryview of coordinates in degrees with shape (n_samples, 2).
        Each row contains [latitude, longitude] in decimal degrees.
        The ``::1`` indicates C-contiguous memory layout for optimal performance.

    Returns
    -------
    cnp.float32_t[:, ::1]
        Two-dimensional typed memoryview of coordinates in radians with shape (n_samples, 2).
        Each row contains [latitude_rad, longitude_rad].

    Notes
    -----
    The function is accessible from both Python and Cython code. It is optimized for performance through:
    - Direct use of typed memoryviews which provide C-level array access 
        without Python object overhead.
    - C-contiguous memory layout (``::1``) ensures optimal cache performance 
        and allows the compiler to generate more efficient machine code.
    - OpenMP-based parallelization via ``prange`` for large inputs (n_samples > 10,000).
    - Release of the Global Interpreter Lock (GIL) during the main computation loop,
        allowing true parallel execution if called from multiple threads.
    - Pre-allocated result array to avoid dynamic memory allocation overhead.

    The function assumes input coordinates are already validated and within valid ranges.
    """
    
    cdef Py_ssize_t n_samples = coords.shape[0]
    if n_samples == 0:
        return np.empty((0, 2), dtype=np.float32)

    cdef cnp.float32_t[:, ::1] result = np.empty((n_samples, 2), dtype=np.float32)
    
    # Parallel execution strategy:
    # - Static scheduling is used because the total number of iterations (n_samples) 
    #   is known in advance, allowing optimal work distribution across threads.
    # - Conditional threading via use_threads_if=n_samples > 10_000 avoids the overhead of
    #   thread pool creation for small arrays, where parallelization would be counterproductive
    #   (thread creation cost would exceed computation time savings).
    # - Thread count limited to 4 (via num_threads=4) to prevent oversubscription:
    #     * Prevents the transformation from monopolizing all CPU cores.
    #     * Leaves resources for other system tasks (e.g., HTTP request handling, OS processes).
    #     * Balances parallelism benefits with context switching overhead.
    for i in prange(
        n_samples,
        nogil=True,
        schedule='static',
        use_threads_if=n_samples > 10_000,
        num_threads=4
    ):
        transform_coordinate_fast(
            coords[i, 0], coords[i, 1],
            &result[i, 0], &result[i, 1]
        )

    return result


cpdef tuple[bint, str] validate_coordinates_fast(
    cnp.float32_t[::1] latitudes,
    cnp.float32_t[::1] longitudes
):
    """
    Validate arrays of geographic coordinates for correctness.

    Parameters
    ----------
    latitudes : cnp.float32_t[::1]
        One-dimensional typed memoryview of latitude values in decimal degrees.
        The ``::1`` indicates C-contiguous memory layout.
    longitudes : cnp.float32_t[::1]
        One-dimensional typed memoryview of longitude values in decimal degrees.
        The ``::1`` indicates C-contiguous memory layout.

    Returns
    -------
    tuple[bint, str]
        A tuple containing:
        - bint: ``True`` if all coordinates are valid, ``False`` otherwise.
        - str: Empty string if valid, otherwise an error message describing the first invalid coordinate found.

    Notes
    -----
    The function is accessible from both Python and Cython code. It is optimized for performance through:
    - Direct use of typed memoryviews which provide C-level array access 
        without Python object overhead.
    - C-contiguous memory layout (``::1``) ensures optimal cache performance 
        and allows the compiler to generate more efficient machine code.
    - Release of the Global Interpreter Lock (GIL) during the main computation loop,
        allowing true parallel execution if called from multiple threads.
    - Pre-allocated result array to avoid dynamic memory allocation overhead.
    - Use of ``.shape[0]`` attribute which is more efficient than Python-level size access.

    Validation checks include:
    - Array length consistency (both arrays must have the same length).
    - Latitude values must be finite and within [-90.0, 90.0] range.
    - Longitude values must be finite and within [-180.0, 180.0] range.

    The function stops at the first validation error encountered and returns immediately,
    providing the index and value of the problematic coordinate.
    """

    cdef Py_ssize_t n = latitudes.shape[0]
    cdef Py_ssize_t i
    cdef float lat, lon
    
    if n != longitudes.shape[0]:
        return (False, "Arrays must have same length")
    
    # Sequential loop is required to preserve input order for early-exit semantics:
    # prange executes iterations in non-deterministic order and cannot guarantee
    # that the "first" invalid index (in original array order) will be reported.
    #
    # nogil is retained to allow concurrent execution of multiple validation calls
    # in multi-threaded environments (e.g., WSGI servers or async apps using run_in_executor).
    # The validation loop uses only C-level operations and so releasing the GIL is safe and beneficial.
    with nogil:
        for i in range(n):
            lat = latitudes[i]
            lon = longitudes[i]
            
            if not is_valid_coordinate(lat, LAT_MIN, LAT_MAX):
                with gil:
                    return (False, f"Invalid latitude at index {i}: {lat}")
            
            if not is_valid_coordinate(lon, LON_MIN, LON_MAX):
                with gil:
                    return (False, f"Invalid longitude at index {i}: {lon}")
    
    return (True, "")

cpdef PredictResponse predict_fast(
    object nn_model,
    object data_df,
    float query_lat,
    float query_lon,
    float radius_meters,
    str description_col,
    str latitude_col,
    str longitude_col
):
    """
    Perform fast geographic nearest-neighbor search within a specified radius.

    Parameters
    ----------
    nn_model : object
        A fitted scikit-learn nearest-neighbor model (e.g., ``GeographicNearestNeighbors``)
        with haversine metric. The model must be trained on coordinates in radians.
    data_df : object
        Pandas DataFrame containing the source data with geographic coordinates
        and descriptions. Must include columns specified by ``description_col``,
        ``latitude_col``, and ``longitude_col``.
    query_lat : float
        Query latitude in decimal degrees. Must be within [-90.0, 90.0].
    query_lon : float
        Query longitude in decimal degrees. Must be within [-180.0, 180.0].
    radius_meters : float
        Search radius in meters. Only results within this distance from the query point
        will be considered.
    description_col : str
        Name of the DataFrame column containing result descriptions.
    latitude_col : str
        Name of the DataFrame column containing latitude values in decimal degrees.
    longitude_col : str
        Name of the DataFrame column containing longitude values in decimal degrees.

    Returns
    -------
    PredictResponse
        A response object containing either:
        - The closest search result within the specified radius (if found), or
        - A "not found" response (if no results within radius).

    Notes
    -----
    The function is accessible from both Python and Cython code. It is optimized for single-query latency:
    - Uses the inline ``transform_coordinate_fast`` function (nogil, C-level) to convert
      a single (lat, lon) pair from degrees to radians.
    - Leverages scikit-learn's highly optimized ``radius_neighbors``.
    - Assumes inputs are pre-validated (no runtime checks for coordinate ranges or model state).
    - Uses unsafe creation helpers to bypass validations and minimize object construction overhead.
    - Results from ``radius_neighbors`` are guaranteed to be sorted by distance when
      ``sort_results=True``, so the first match is always the closest.
    """

    # Convert single query point from degrees to radians using optimized inline function.
    cdef float query_lat_rad, query_lon_rad
    transform_coordinate_fast(query_lat, query_lon, &query_lat_rad, &query_lon_rad)

    # Wrap as 2D array expected by scikit-learn (shape: (1, 2))
    # Use stack-allocated C array to avoid Python object creation where possible.
    cdef cnp.ndarray[cnp.float32_t, ndim=2] query_rad = np.empty((1, 2), dtype=np.float32)
    query_rad[0, 0] = <double>query_lat_rad
    query_rad[0, 1] = <double>query_lon_rad

    # Convert radius to radians (haversine works in radians)
    cdef float radius_rad = radius_meters / EARTH_RADIUS_METERS

    # Query the model
    distances_rad, indices = nn_model.radius_neighbors(
        query_rad,
        radius=radius_rad,
        return_distance=True,
        sort_results=True
    )

    # No results found
    if len(indices[0]) == 0:
        return create_not_found_response()

    # Extract closest result (first = closest thanks to sort_results=True)
    cdef Py_ssize_t closest_idx = indices[0][0]
    cdef float distance_rad = distances_rad[0][0]
    cdef float distance_m = distance_rad * EARTH_RADIUS_METERS

    # Fetch result data from DataFrame (minimal overhead)
    row = data_df.iloc[closest_idx]
    cdef str description = str(row[description_col])
    cdef float result_lat = float(row[latitude_col])
    cdef float result_lon = float(row[longitude_col])

    # Construct response without validation (unsafe but fast)
    return create_predict_response_unsafe(
        result=create_search_result_unsafe(
            description=description,
            coordinates=create_coordinates_unsafe(
                latitude=result_lat,
                longitude=result_lon
            ),
            geo_distance=c_round(distance_m)
        )
    )
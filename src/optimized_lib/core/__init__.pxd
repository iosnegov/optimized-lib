# src/optimized_lib/core/__init__.pxd
cimport numpy as cnp
from optimized_lib.types cimport PredictResponse

# Module-level constants
cdef float EARTH_RADIUS_METERS
cdef float PI
cdef float DEG_TO_RAD

cdef inline void transform_coordinate_fast(
    float lat_deg, float lon_deg,
    float* lat_rad, float* lon_rad
) noexcept nogil

cpdef cnp.float32_t[:, ::1] transform_coordinates_fast(cnp.float32_t[:, ::1] coords)

cpdef tuple[bint, str] validate_coordinates_fast(
    cnp.float32_t[::1] latitudes,
    cnp.float32_t[::1] longitudes
)

cpdef PredictResponse predict_fast(
    object nn_model,
    object data_df,
    float query_lat,
    float query_lon,
    float radius_meters,
    str description_col,
    str latitude_col,
    str longitude_col
)
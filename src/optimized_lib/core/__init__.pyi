# src/optimized_lib/core/__init__.pyi
import numpy as np
from numpy.typing import NDArray
import pandas as pd
from sklearn.neighbors import NearestNeighbors
from optimized_lib.types import PredictResponse

def transform_coordinates_fast(coords: NDArray[np.float32]) -> NDArray[np.float32]:
    """
    Convert a batch of geographic coordinates from degrees to radians.

    Parameters
    ----------
    coords : numpy.ndarray (shape: (n_samples, 2), dtype=np.float32)
        Two-dimensional array of coordinates in degrees.
        Each row contains [latitude, longitude] in decimal degrees.
        The function expects a C-contiguous 2D array for best performance.

    Returns
    -------
    numpy.ndarray (shape: (n_samples, 2), dtype=np.float32)
        Two-dimensional array of coordinates in radians.
        Each row contains [latitude_rad, longitude_rad].
    
    Notes
    -----
    The function is optimized for performance using Cython and OpenMP, 
    which enables true parallel execution across multiple CPU cores.

    The function assumes input coordinates are already validated and within valid ranges.
    """
    ...


def validate_coordinates_fast(
    latitudes: NDArray[np.float32],
    longitudes: NDArray[np.float32]
) -> tuple[bool, str]:
    """
    Validate arrays of geographic coordinates for correctness.

    Parameters
    ----------
    latitudes : numpy.ndarray (shape: (n,), dtype=np.float32)
        One-dimensional array of latitude values in decimal degrees.
    longitudes : numpy.ndarray (shape: (n,), dtype=np.float32)
        One-dimensional array of longitude values in decimal degrees.

    Returns
    -------
    tuple[bool, str]
        A tuple containing:
        - bool: ``True`` if all coordinates are valid, ``False`` otherwise.
        - str: Empty string if valid, otherwise an error message describing the first invalid coordinate found.

    Notes
    -----
    The function is optimized for performance using Cython, allowing true parallel execution when called from multiple threads.

    Validation checks include:
    - Array length consistency (both arrays must have the same length).
    - Latitude values must be finite and within [-90.0, 90.0] range.
    - Longitude values must be finite and within [-180.0, 180.0] range.

    The function stops at the first validation error encountered and returns immediately,
    providing the index and value of the problematic coordinate.
    """
    ...


def predict_fast(
    nn_model: NearestNeighbors,
    data_df: pd.DataFrame,
    query_lat: float,
    query_lon: float,
    radius_meters: float,
    description_col: str,
    latitude_col: str,
    longitude_col: str
) -> PredictResponse:
    """
    Perform fast geographic nearest-neighbor search within a specified radius.

    Parameters
    ----------
    nn_model : sklearn.neighbors.NearestNeighbors
        A fitted scikit-learn nearest-neighbor model (e.g., ``GeographicNearestNeighbors``)
        with haversine metric. The model must be trained on coordinates in radians.
    data_df : pd.DataFrame
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
    The function is optimized for performance using Cython.

    The function assumes inputs are already validated (no runtime checks for coordinate ranges or model state).
    """
    ...
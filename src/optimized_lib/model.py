# src/optimized_lib/model.py
from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.neighbors import NearestNeighbors
from sklearn.utils.validation import check_is_fitted
from sklearn.exceptions import NotFittedError
import joblib
from huggingface_hub import hf_hub_download

# Import optimized Cython core functions
from .core import (
    transform_coordinates_fast,
    validate_coordinates_fast,
    predict_fast
)
from .types import PredictRequest, PredictResponse


class GeoNearestNeighbor(NearestNeighbors):
    """
    High-performance extension of scikit-learn's NearestNeighbors for geographic data
    using the Haversine metric, accelerated via Cython-optimized core routines.

    Parameters
    ----------
    algorithm : str, optional
        Algorithm used by the underlying NearestNeighbors estimator (default 'ball_tree').
        Must support the 'haversine' metric (e.g., 'ball_tree').
    leaf_size : int, optional
        Leaf size for tree-based algorithms (default 30).
    n_jobs : int or None, optional
        Number of parallel jobs for neighbor search. -1 uses all processors.

    Attributes
    ----------
    METRIC : str
        Fixed to 'haversine' — required for geographic distance computation.
    EARTH_RADIUS_METERS : float
        Earth radius in meters (6371000.0), consistent with core module.
    DEFAULT_FILEPATH : str
        Default path for model persistence via joblib.
    DESCRIPTION_COL, LATITUDE_COL, LONGITUDE_COL : str
        Canonical column names expected in input DataFrame. Enforced for schema stability.

    Notes
    -----
    This class delegates performance-critical operations to Cython-compiled functions:
    - Coordinate validation — ``validate_coordinates_fast``
    - Degree-to-radian conversion — ``transform_coordinates_fast``
    - Single-query prediction — ``predict_fast``

    By doing so, it eliminates Python-level overhead in hot paths while retaining
    full compatibility with scikit-learn's estimator interface (``fit``, ``predict``).
    """

    METRIC: str = 'haversine'
    EARTH_RADIUS_METERS: float = 6371000.0
    DEFAULT_FILEPATH: str = "models/geo_nearest_neighbor.joblib"
    DESCRIPTION_COL: str = 'description'
    LATITUDE_COL: str = 'latitude'
    LONGITUDE_COL: str = 'longitude'

    def __init__(
        self,
        algorithm: str = 'ball_tree',
        leaf_size: int = 30,
        n_jobs: int = -1
    ):
        """
        Initialize the geographic nearest neighbor estimator.

        Parameters
        ----------
        algorithm : str
            Tree algorithm compatible with haversine (e.g., 'ball_tree').
        leaf_size : int
            Affects tree construction speed and query performance.
        n_jobs : int
            Parallelism for neighbor search; passed directly to scikit-learn.

        Notes
        -----
        The metric is hardcoded to 'haversine' and cannot be overridden.
        This ensures correctness for geographic coordinates and enables
        seamless integration with the optimized Cython prediction pipeline.
        """
        
        super().__init__(
            metric=self.METRIC,
            algorithm=algorithm,
            leaf_size=leaf_size,
            n_jobs=n_jobs
        )

    def fit(self, X: pd.DataFrame) -> "GeoNearestNeighbor":
        """
        Fit the model using geographic place data with Cython-accelerated validation.

        Parameters
        ----------
        X : pandas.DataFrame
            Input data with exactly three columns:
            - 'description' (str): human-readable label
            - 'latitude' (float): in decimal degrees [-90, 90]
            - 'longitude' (float): in decimal degrees [-180, 180]

        Returns
        -------
        GeoNearestNeighbor
            Fitted estimator (self).

        Raises
        ------
        ValueError
            If schema is violated or any coordinate is out of valid range.

        Notes
        -----
        Leverages ``validate_coordinates_fast`` for zero-overhead, GIL-released
        validation of latitude/longitude arrays. This is significantly faster than
        row-wise Pydantic validation for large datasets.

        After validation, coordinates are converted to radians using
        ``transform_coordinates_fast`` (parallelized for n > 10,000) and passed
        to the parent ``NearestNeighbors.fit``. The original DataFrame is stored
        in ``self.data_`` for result formatting during prediction.
        """

        required_cols = [self.DESCRIPTION_COL, self.LATITUDE_COL, self.LONGITUDE_COL]
        missing_cols = [col for col in required_cols if col not in X.columns]
        if missing_cols:
            raise ValueError(f"Missing required columns: {missing_cols}")

        # Extract coordinate arrays as contiguous float32 views for Cython
        latitudes = np.asarray(X[self.LATITUDE_COL], dtype=np.float32)
        longitudes = np.asarray(X[self.LONGITUDE_COL], dtype=np.float32)

        # Validate using optimized Cython routine (early exit on first error)
        is_valid, error_msg = validate_coordinates_fast(latitudes, longitudes)
        if not is_valid:
            raise ValueError(error_msg)

        # Store minimal validated data for response formatting
        self.data_ = X[required_cols].copy()

        # Convert to radians using parallel Cython transform
        coords_deg = np.column_stack((latitudes, longitudes)).astype(np.float32)
        coords_rad = np.asarray(transform_coordinates_fast(coords_deg), dtype=np.float64)

        # Fit underlying scikit-learn model on radians
        super().fit(coords_rad)
        return self

    def predict(self, X: PredictRequest) -> PredictResponse:
        """
        Perform single-query geographic nearest-neighbor search using optimized Cython routine.

        Parameters
        ----------
        X : PredictRequest
            Structured request containing:
            - coordinates: latitude/longitude in degrees
            - radius_meters: maximum search distance

        Returns
        -------
        PredictResponse
            Either a valid ``SearchResult`` (if match found within radius)
            or a "not found" response.

        Raises
        ------
        NotFittedError
            If called before ``fit``.

        Notes
        -----
        Delegates the entire prediction pipeline to ``predict_fast``, a Cython function that:
        - Converts query point to radians without Python overhead
        - Queries scikit-learn's ``radius_neighbors`` (highly optimized C++)
        - Constructs response using unsafe creation helpers (bypasses validation for speed)
        - Returns pre-rounded distance (via ``libc.math.round``)

        This design ensures minimal latency for single-query inference,
        crucial for API-serving scenarios.
        """
        
        check_is_fitted(self, ['data_'])
        return predict_fast(
            nn_model=self,
            data_df=self.data_,
            query_lat=X.coordinates.latitude,
            query_lon=X.coordinates.longitude,
            radius_meters=X.radius_meters,
            description_col=self.DESCRIPTION_COL,
            latitude_col=self.LATITUDE_COL,
            longitude_col=self.LONGITUDE_COL
        )

    def __call__(self, X: PredictRequest) -> PredictResponse:
        """
        Enable callable syntax for ergonomic API usage.

        Parameters
        ----------
        X : PredictRequest
            Same as in ``predict``.

        Returns
        -------
        PredictResponse
            Result of the nearest-neighbor search.

        Notes
        -----
        Syntactic sugar to support ``model(request)`` pattern,
        aligning with common machine learning deployment practices.
        """

        return self.predict(X)

    def save_model(self, filepath: str | None = None) -> None:
        """
        Save the complete model state to disk.

        Parameters
        ----------
        filepath : str or None, optional
            Filesystem path where the model will be saved. If None, uses
            the class-level DEFAULT_FILEPATH.

        Raises
        ------
        ValueError
            If the model has not been fitted before saving.

        Notes
        -----
        The method ensures the parent directory exists and serializes the full
        estimator (including ``self.data_``) using joblib with compression.
        """
        if filepath is None:
            filepath = self.DEFAULT_FILEPATH
        
        try:
            check_is_fitted(self, ['data_'])
        except NotFittedError:
            raise ValueError("Model must be fitted before saving")
        
        Path(filepath).parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(self, filepath, compress=3)

    def load_model(self, filepath: str | None = None) -> "GeoNearestNeighbor":
        """
        Load model state into the current instance.

        Parameters
        ----------
        filepath : str or None, optional
            Path to a saved model file. If None, uses DEFAULT_FILEPATH.

        Returns
        -------
        GeoNearestNeighbor
            The current instance updated with the loaded model state.

        Raises
        ------
        Exception
            Propagates exceptions raised by joblib.load when loading fails.

        Notes
        -----
        This method deserializes a joblib file and updates ``self.__dict__`` with
        the loaded object's attributes, effectively restoring fitted parameters
        and stored metadata.
        """

        if filepath is None:
            filepath = self.DEFAULT_FILEPATH
        
        loaded_model = joblib.load(filepath)
        self.__dict__.update(loaded_model.__dict__)
        return self

    @classmethod
    def from_file(cls, filepath: str | None = None) -> "GeoNearestNeighbor":
        """
        Create a new instance from a saved file.

        Parameters
        ----------
        filepath : str or None, optional
            Path to the saved model file. If None, uses DEFAULT_FILEPATH.

        Returns
        -------
        GeoNearestNeighbor
            A new estimator instance loaded from the file.

        Raises
        ------
        Exception
            Propagates exceptions raised by joblib.load when loading fails.
        """
        
        if filepath is None:
            filepath = cls.DEFAULT_FILEPATH
        
        return joblib.load(filepath)

    @classmethod
    def from_huggingface_hub(
        cls, 
        repo_id: str,
        filename: str | None = None,
        cache_dir: str = "models/",
        force_download: bool = False,
        token: str | None = None
    ) -> "GeoNearestNeighbor":
        """
        Download and load model from the Hugging Face Hub.

        Parameters
        ----------
        repo_id : str
            Repository identifier on Hugging Face (e.g. "username/model-name").
        filename : str or None, optional
            Filename in the repository to download; if None, defaults to DEFAULT_FILEPATH.
        cache_dir : str, optional
            Local directory to cache downloaded files (default "models/").
        force_download : bool, optional
            If True, re-download even when a cached file exists.
        token : str or None, optional
            Authentication token for private repositories.

        Returns
        -------
        GeoNearestNeighbor
            The estimator instance loaded from the downloaded file.

        Raises
        ------
        RuntimeError
            If the download or loading fails; the original exception message is wrapped.
        """
        
        if filename is None:
            filename = cls.DEFAULT_FILEPATH

        try:
            model_path = hf_hub_download(
                repo_id=repo_id,
                filename=filename,
                cache_dir=cache_dir,
                force_download=force_download,
                token=token
            )
            
            return joblib.load(model_path)
            
        except Exception as e:
            raise RuntimeError(f"Failed to download model from Hugging Face Hub: {e}")
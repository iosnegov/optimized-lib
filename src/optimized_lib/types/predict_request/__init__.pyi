# src/optimized_lib/types/predict_request/__init__.pyi
from typing import Any
from optimized_lib.types.coordinates import Coordinates

class PredictRequest:
    """
    Request for prediction with geographic coordinates and search radius.

    Parameters
    ----------
    coordinates : Coordinates
        The geographic coordinates. Muse be not None.
    radius_meters : float
        The search radius in meters. Must be finite and greater than zero.

    Attributes
    ----------
    coordinates : Coordinates
        The geographic coordinates.
    radius_meters : float
        The search radius in meters.

    Raises
    ------
    ValueError
        If coordinates is None or radius_meters is not a positive finite value.
    """

    coordinates: Coordinates
    radius_meters: float

    def __init__(self, coordinates: Coordinates, radius_meters: float):
        """
        Python-level initialization.
        
        Validates all fields have valid values before assigning.
        """
        ...

    def to_dict(self) -> dict[str, Any]: 
        """
        Convert the PredictRequest object to a dictionary.

        Returns
        -------
        dict[str, Any]
            A dictionary representation of the PredictRequest object, 
            with keys 'coordinates' (dict) and 'radius_meters' (float).
        """
        ...
    
    def to_json(self, indent: int, ensure_ascii: bool = True) -> str:
        """
        Convert the PredictRequest object to a JSON string representation.

        Parameters
        ----------
        indent : int
            The number of spaces to use for indentation in the output JSON string.

        ensure_ascii : bool, optional
            Ensures that non-ASCII characters are escaped if True (default `True`).

        Returns
        -------
        str
            A JSON string representation of the PredictRequest object.
        """
        ...
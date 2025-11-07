# src/optimized_lib/types/search_result/__init__.pyi
from typing import Any
from optimized_lib.types.coordinates import Coordinates

class SearchResult:
    """
    Result of a geographic search operation.

    Parameters
    ----------
    description : str
        Description of the search result. Cannot be None.
    coordinates : Coordinates
        The geographic coordinates of the search result. Must not be None.
    geo_distance : float
        Distance from the search origin to the found location (in meters). Must be greater than zero.

    Attributes
    ----------
    description : str
        Description of the search result.
    coordinates : Coordinates
        The geographic coordinates of the search result.
    geo_distance : float
        Distance from the search origin to the found location (in meters).

    Raises
    ------
    ValueError
        If description is None, coordinates is None, or geo_distance is not a positive finite value.
    """

    description: str
    coordinates: Coordinates
    geo_distance: float

    def __init__(self, description: str, coordinates: Coordinates, geo_distance: float): 
        """
        Python-level initialization.
        
        Validates all fields have valid values before assigning.
        """
        ...

    def to_dict(self) -> dict[str, Any]: 
        """
        Convert the SearchResult object to a dictionary.

        Returns
        -------
        dict[str, Any]
            A dictionary representation of the SearchResult object, 
            with keys 'description' (str), 'coordinates' (dict), and 'geo_distance' (float).
        """
        ...
    
    def to_json(self, indent: int, ensure_ascii: bool = True) -> str: 
        """
        Convert the SearchResult object to a JSON string representation.

        Parameters
        ----------
        indent : int
            The number of spaces to use for indentation in the output JSON string.

        ensure_ascii : bool, optional
            Ensures that non-ASCII characters are escaped if True (default `True`).

        Returns
        -------
        str
            A JSON string representation of the SearchResult object.
        """
        ...
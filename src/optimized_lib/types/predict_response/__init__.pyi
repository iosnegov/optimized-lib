# src/optimized_lib/types/predict_response/__init__.pyi
from typing import Any
from optimized_lib.types.search_result import SearchResult

class PredictResponse:
    """
    Response from a prediction operation indicating success and optional result.

    Parameters
    ----------
    found : bool
        Indicates whether a result was found. If True, result must not be None.
    result : SearchResult, optional
        The search result if found, otherwise None (default None).

    Attributes
    ----------
    found : bool
        Indicates whether a result was found. If True, result must not be None.
    result : SearchResult, optional
        The search result if found, otherwise None (default None).

    Raises
    ------
    ValueError
        If found is True but result is None.
    """

    found: bool
    result: SearchResult

    def __init__(self, found: bool, result: SearchResult): 
        """
        Python-level initialization.
        
        Validates all fields have valid values before assigning.
        """
        ...

    def to_dict(self) -> dict[str, Any]: 
        """
        Convert the PredictResponse object to a dictionary.

        Returns
        -------
        dict[str, Any]
            A dictionary representation of the PredictResponse object, 
            with keys 'found' (bool) and 'result' (dict).
        """
        ...
    
    def to_json(self, indent: int, ensure_ascii: bool = True) -> str: 
        """
        Convert the PredictResponse object to a JSON string representation.

        Parameters
        ----------
        indent : int
            The number of spaces to use for indentation in the output JSON string.

        ensure_ascii : bool, optional
            Ensures that non-ASCII characters are escaped if True (default `True`).

        Returns
        -------
        str
            A JSON string representation of the PredictResponse object.
        """
        ...
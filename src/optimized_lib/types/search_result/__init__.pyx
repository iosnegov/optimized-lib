# src/optimized_lib/types/search_result/__init__.pyx
cimport cython
import json
from optimized_lib.types.coordinates cimport Coordinates
from optimized_lib.types.predict_request cimport is_valid_distance

# Special class decorator which tells Cython that this class cannot be subclassed. 
# This optimization allows Cython to generate more efficient C code overall.
@cython.final
cdef class SearchResult:
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
    description : public str
        Description of the search result.
    coordinates : public Coordinates
        The geographic coordinates of the search result.
    geo_distance : public float
        Distance from the search origin to the found location (in meters).

    Raises
    ------
    ValueError
        If description is None, coordinates is None, or geo_distance is not a positive finite value.

    Notes
    -----
    This class uses both ``__cinit__`` and ``__init__`` for two-stage initialization:
    
    - ``__cinit__`` orms C-level initialization, setting default values (None, None, 0.0)
        to ensure the object is always in a safe state. This method is guaranteed to be
        called exactly once during object allocation, before full Python initialization.
      
    - ``__init__`` performs Python-level validation and assigns the final values. 
        This method may be skipped if the object is created via ``__new__()``. 
        The validation in ``__init__`` ensures that all fields have valid values
        when set through normal construction.

    This design ensures that even if ``__init__`` raises an exception or is bypassed,
    the C-level attributes are always initialized to safe default values.
    """

    def __cinit__(
        self, 
        str description = None, 
        Coordinates coordinates = None, 
        float geo_distance = 0.0
    ):
        """
        C-level initialization (called first during object allocation).
        
        Sets default values to ensure the object is always in a safe
        C-level state, even if ``__init__`` is skipped or raises an exception.
        This method is guaranteed to be called exactly once.
        """

        self.description = description
        self.coordinates = coordinates
        self.geo_distance = geo_distance

    def __init__(
        self, 
        str description, 
        Coordinates coordinates, 
        float geo_distance
    ):
        """
        Python-level initialization (called after ``__cinit__``).
        
        Validates all fields have valid values before assigning.
        """

        if description is None:
            raise ValueError("description cannot be None")
        if coordinates is None:
            raise ValueError("coordinates cannot be None")
        if not is_valid_distance(geo_distance):
            raise ValueError(f"distance must be > 0, got {geo_distance}")

        self.description = description
        self.coordinates = coordinates
        self.geo_distance = geo_distance

    cpdef dict to_dict(self):
        """
        Convert the SearchResult object to a dictionary.

        Returns
        -------
        dict[str, ...]
            A dictionary representation of the SearchResult object, 
            with keys 'description' (str), 'coordinates' (dict), and 'geo_distance' (float).
        
        Notes
        -----
        The method is accessible from both Python and Cython code.
        """

        return {
            'description': self.description,
            'coordinates': self.coordinates.to_dict(),
            'geo_distance': self.geo_distance
        }

    cpdef str to_json(self, int indent, bint ensure_ascii = True):
        """
        Convert the SearchResult object to a JSON string representation.

        Parameters
        ----------
        indent : int
            The number of spaces to use for indentation in the output JSON string.

        ensure_ascii : bint, optional
            Ensures that non-ASCII characters are escaped if True (default `True`).

        Returns
        -------
        str
            A JSON string representation of the SearchResult object.

        Notes
        -----
        The method is accessible from both Python and Cython code.
        """

        data = self.to_dict()
        return json.dumps(data, indent=indent, ensure_ascii=ensure_ascii)


cdef inline SearchResult create_unsafe(str description, Coordinates coordinates, float geo_distance):
    """
    Create a ``SearchResult`` instance without validation directly using `__new__`, 
    and assigning the provided values without performing any Python-level validation.

    Parameters
    ----------
    description : str
        Description of the search result (assumed valid).
    coordinates : Coordinates
        The geographic coordinates of the search result (assumed valid) .
    geo_distance : float
        Distance from the search origin to the found location (in meters, assumed valid).

    Returns
    -------
    SearchResult
        New ``SearchResult`` instance.

    Notes
    -----
    The function is accessible from Cython code only. It is declared with:
    - ``inline`` — allows the Cython compiler to embed the function body directly 
        at the call site to eliminate call overhead 
        (which increases execution speed at the cost of larger code size).
    
    Runs with Global Interpreter Lock, since a new Python object is allocated.
    The `noexcept` specifier is not meaningful here and will be ignored by Cython, 
    since the function creates a Python object, which involves operations that may raise Python exceptions.
    """

    cdef SearchResult obj = <SearchResult>SearchResult.__new__(SearchResult)
    obj.description = description
    obj.coordinates = coordinates
    obj.geo_distance = geo_distance
    return obj
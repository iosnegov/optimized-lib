# src/optimized_lib/types/coordinates/__init__.pyx
from libc.math cimport isfinite
cimport cython
import json

# Geographic coordinate limits in degrees.
# Used internally for validation.
cdef const float LAT_MIN = -90.0
cdef const float LAT_MAX = 90.0
cdef const float LON_MIN = -180.0
cdef const float LON_MAX = 180.0

cdef inline bint is_valid_coordinate(float value, float minv, float maxv) noexcept nogil:
    """
    Extremely fast check whether a coordinate value is finite 
    and lies within valid geographic bounds.

    Parameters
    ----------
    value : float
        Coordinate value to check.
    minv : float
        Minimum allowed value (inclusive).
    maxv : float
        Maximum allowed value (inclusive).

    Returns
    -------
    bint
        True if the coordinate is finite and within [minv, maxv], otherwise False.

    Notes
    -----
    The function is accessible from Cython code only. It is declared with:
    - ``inline`` — allows the Cython compiler to embed the function body directly 
        at the call site to eliminate call overhead 
        (which increases execution speed at the cost of larger code size).
    - ``noexcept`` — guarantees that the function never raises Python exceptions 
        (some form of except-modifier should usually be added for Cython compiler).
    - ``nogil`` — allows execution without holding the Python Global Interpreter Lock.
    """

    return isfinite(value) and (minv <= value <= maxv)

# Special class decorator which tells Cython that this class cannot be subclassed. 
# This optimization allows Cython to generate more efficient C code overall.
@cython.final
cdef class Coordinates:
    """
    Geographic coordinates.

    Parameters
    ----------
    latitude : float
        The latitude in decimal degrees. Must be in range [-90.0, 90.0].
    longitude : float
        The longitude in decimal degrees. Must be in range [-180.0, 180.0].

    Attributes
    ----------
    latitude : public float
        The latitude value in decimal degrees.
    longitude : public float
        The longitude value in decimal degrees.

    Raises
    ------
    ValueError
        If latitude or longitude values are out of valid range.

    Notes
    -----
    This class uses both ``__cinit__`` and ``__init__`` for two-stage initialization:
    
    - ``__cinit__`` performs C-level initialization, setting default values (0.0, 0.0)
        to ensure the object is always in a safe state. This method is guaranteed to be
        called exactly once during object allocation, before full Python initialization.
      
    - ``__init__`` performs Python-level validation and assigns the final coordinate
        values. This method may be skipped if the object is created via ``__new__()``. 
        The validation in ``__init__`` ensures coordinates are always within valid 
        ranges when set through normal construction.

    This design ensures that even if ``__init__`` raises an exception or is bypassed,
    the C-level attributes are always initialized to safe default values.
    """

    def __cinit__(self, float latitude = 0.0, float longitude = 0.0):
        """
        C-level initialization (called first during object allocation).
        
        Sets default coordinate values to ensure the object is always in a safe
        C-level state, even if ``__init__`` is skipped or raises an exception.
        This method is guaranteed to be called exactly once.
        """
        
        self.latitude = latitude
        self.longitude = longitude

    def __init__(self, float latitude, float longitude):
        """
        Python-level initialization (called after ``__cinit__``).
        
        Validates that coordinates are within 
        acceptable ranges before assigning values.
        """

        if not is_valid_coordinate(latitude, LAT_MIN, LAT_MAX):
            raise ValueError(f"latitude out of range: {latitude}")
        if not is_valid_coordinate(longitude, LON_MIN, LON_MAX):
            raise ValueError(f"longitude out of range: {longitude}")
        
        self.latitude = latitude
        self.longitude = longitude

    cpdef dict to_dict(self):
        """
        Convert the Coordinates object to a dictionary.

        Returns
        -------
        dict[str, float]
            A dictionary representation of the Coordinates object, 
            with keys 'latitude' and 'longitude'.
        
        Notes
        -----
        The method is accessible from both Python and Cython code.
        """

        return {'latitude': self.latitude, 'longitude': self.longitude}

    cpdef str to_json(self, int indent, bint ensure_ascii = True):
        """
        Convert the Coordinates object to a JSON string representation.

        Parameters
        ----------
        indent : int
            The number of spaces to use for indentation in the output JSON string.

        ensure_ascii : bint, optional
            Ensures that non-ASCII characters are escaped if True (default `True`).

        Returns
        -------
        str
            A JSON string representation of the Coordinates object.

        Notes
        -----
        The method is accessible from both Python and Cython code.
        """

        data = self.to_dict()
        return json.dumps(data, indent=indent, ensure_ascii=ensure_ascii)


cdef inline Coordinates create_unsafe(float latitude, float longitude):
    """
    Create a ``Coordinates`` instance without validation directly using `__new__`, 
    and assigning the provided values without performing any Python-level validation.

    Parameters
    ----------
    latitude : float
        Latitude in degrees (assumed valid).
    longitude : float
        Longitude in degrees (assumed valid).

    Returns
    -------
    Coordinates
        New ``Coordinates`` instance.

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

    cdef Coordinates obj = <Coordinates>Coordinates.__new__(Coordinates)
    obj.latitude = latitude
    obj.longitude = longitude
    return obj
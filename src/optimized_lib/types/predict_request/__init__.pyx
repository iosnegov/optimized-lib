# src/optimized_lib/types/predict_request/__init__.pyx
from libc.math cimport isfinite
cimport cython
import json
from optimized_lib.types.coordinates cimport Coordinates


cdef inline bint is_valid_distance(float distance) noexcept nogil:
    """
    Extremely fast check whether a distance value is finite and positive.

    Parameters
    ----------
    distance : float
        Distance value to check in meters.

    Returns
    -------
    bint
        True if the distance is finite and greater than zero, otherwise False.

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

    return isfinite(distance) and distance > 0.0

# Special class decorator which tells Cython that this class cannot be subclassed. 
# This optimization allows Cython to generate more efficient C code overall.
@cython.final
cdef class PredictRequest:
    """
    Request for prediction with geographic coordinates and search radius.

    Parameters
    ----------
    coordinates : Coordinates
        The geographic coordinates. Must not be None.
    radius_meters : float
        The search radius in meters. Must be finite and greater than zero.

    Attributes
    ----------
    coordinates : public Coordinates
        The geographic coordinates.
    radius_meters : public float
        The search radius in meters.

    Raises
    ------
    ValueError
        If coordinates is None or radius_meters is not a positive finite value.

    Notes
    -----
    This class uses both ``__cinit__`` and ``__init__`` for two-stage initialization:
    
    - ``__cinit__`` performs C-level initialization, setting default values (None, 0.0)
        to ensure the object is always in a safe state. This method is guaranteed to be
        called exactly once during object allocation, before full Python initialization.
      
    - ``__init__`` performs Python-level validation and assigns the final values. 
        This method may be skipped if the object is created via ``__new__()``. 
        The validation in ``__init__`` ensures that all fields have valid values
        when set through normal construction.

    This design ensures that even if ``__init__`` raises an exception or is bypassed,
    the C-level attributes are always initialized to safe default values.
    """

    def __cinit__(self, Coordinates coordinates = None, float radius_meters = 0.0):
        """
        C-level initialization (called first during object allocation).
        
        Sets default values to ensure the object is always in a safe
        C-level state, even if ``__init__`` is skipped or raises an exception.
        This method is guaranteed to be called exactly once.
        """
    
        self.coordinates = coordinates
        self.radius_meters = radius_meters

    def __init__(self, Coordinates coordinates, float radius_meters):
        """
        Python-level initialization (called after ``__cinit__``).
        
        Validates all fields have valid values before assigning.
        """

        if coordinates is None:
            raise ValueError("coordinates cannot be None")
        if not is_valid_distance(radius_meters):
            raise ValueError(f"radius must be > 0, got {radius_meters}")
        
        self.coordinates = coordinates
        self.radius_meters = radius_meters

    cpdef dict to_dict(self):
        """
        Convert the PredictRequest object to a dictionary.

        Returns
        -------
        dict[str, ...]
            A dictionary representation of the PredictRequest object, 
            with keys 'coordinates' (dict) and 'radius_meters' (float).
        
        Notes
        -----
        The method is accessible from both Python and Cython code.
        """
    
        return {
            'coordinates': self.coordinates.to_dict(), 
            'radius_meters': self.radius_meters
        }

    cpdef str to_json(self, int indent, bint ensure_ascii = True):
        """
        Convert the PredictRequest object to a JSON string representation.

        Parameters
        ----------
        indent : int
            The number of spaces to use for indentation in the output JSON string.

        ensure_ascii : bint, optional
            Ensures that non-ASCII characters are escaped if True (default `True`).

        Returns
        -------
        str
            A JSON string representation of the PredictRequest object.

        Notes
        -----
        The method is accessible from both Python and Cython code.
        """

        data = self.to_dict()
        return json.dumps(data, indent=indent, ensure_ascii=ensure_ascii)


cdef inline PredictRequest create_unsafe(Coordinates coordinates, float radius_meters):
    """
    Create a ``PredictRequest`` instance without validation directly using `__new__`, 
    and assigning the provided values without performing any Python-level validation.

    Parameters
    ----------
    coordinates : Coordinates
        Geographic coordinates (assumed valid and not None).
    radius_meters : float
        Search radius in meters (assumed valid and positive).

    Returns
    -------
    PredictRequest
        New ``PredictRequest`` instance.

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

    cdef PredictRequest obj = <PredictRequest>PredictRequest.__new__(PredictRequest)
    obj.coordinates = coordinates
    obj.radius_meters = radius_meters
    return obj
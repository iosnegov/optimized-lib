# src/optimized_lib/types/predict_response/__init__.pyx
import json
cimport cython
from optimized_lib.types.search_result cimport SearchResult

# Special class decorator which tells Cython that this class cannot be subclassed. 
# This optimization allows Cython to generate more efficient C code overall.
@cython.final
cdef class PredictResponse:
    """
    Response from a prediction operation indicating success and optional result.

    Parameters
    ----------
    found : bint
        Indicates whether a result was found. If True, result must not be None.
    result : SearchResult, optional
        The search result if found, otherwise None (default None).

    Attributes
    ----------
    found : public bint
        Indicates whether a result was found. If True, result must not be None.
    result : public SearchResult, optional
        The search result if found, otherwise None (default None).

    Raises
    ------
    ValueError
        If found is True but result is None.
      
    Notes
    -----
    This class uses both ``__cinit__`` and ``__init__`` for two-stage initialization:
    
    - ``__cinit__`` orms C-level initialization, setting default values (False, None)
        to ensure the object is always in a safe state. This method is guaranteed to be
        called exactly once during object allocation, before full Python initialization.
      
    - ``__init__`` performs Python-level validation and assigns the final values. 
        This method may be skipped if the object is created via ``__new__()``. 
        The validation in ``__init__`` ensures that all fields have valid values
        when set through normal construction.

    This design ensures that even if ``__init__`` raises an exception or is bypassed,
    the C-level attributes are always initialized to safe default values.
    """

    def __cinit__(self, bint found = False, SearchResult result = None):
        """
        C-level initialization (called first during object allocation).
        
        Sets default values to ensure the object is always in a safe
        C-level state, even if ``__init__`` is skipped or raises an exception.
        This method is guaranteed to be called exactly once.
        """

        self.found = found
        self.result = result

    def __init__(self, bint found, SearchResult result):
        """
        Python-level initialization (called after ``__cinit__``).
        
        Validates all fields have valid values before assigning.
        """

        if found and result is None:
            raise ValueError("result cannot be None when found is True")
        
        self.found = found
        self.result = result

    cpdef dict to_dict(self):
        """
        Convert the PredictResponse object to a dictionary.

        Returns
        -------
        dict[str, ...]
            A dictionary representation of the PredictResponse object, 
            with keys 'found' (bint) and 'result' (dict).
        
        Notes
        -----
        The method is accessible from both Python and Cython code.
        """

        if self.found and self.result is not None:
            return {
                'found': True,
                'result': self.result.to_dict()
            }
        return {
            'found': False, 
            'result': None
        }

    cpdef str to_json(self, int indent, bint ensure_ascii = True):
        """
        Convert the PredictResponse object to a JSON string representation.

        Parameters
        ----------
        indent : int
            The number of spaces to use for indentation in the output JSON string.

        ensure_ascii : bint, optional
            Ensures that non-ASCII characters are escaped if True (default `True`).

        Returns
        -------
        str
            A JSON string representation of the PredictResponse object.

        Notes
        -----
        The method is accessible from both Python and Cython code.
        """

        data = self.to_dict()
        return json.dumps(data, indent=indent, ensure_ascii=ensure_ascii)


cdef inline PredictResponse create_unsafe(SearchResult result):
    """
    Create a ``PredictResponse`` instance without validation directly using `__new__`, 
    and assigning the provided values without performing any Python-level validation.

    Parameters
    ----------
    result : SearchResult
        The search result (assumed valid).

    Returns
    -------
    PredictResponse
        New ``PredictResponse`` instance with found=True and the provided result.

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

    cdef PredictResponse obj = <PredictResponse>PredictResponse.__new__(PredictResponse)
    obj.found = True
    obj.result = result
    return obj


cdef inline PredictResponse create_not_found():
    """
    Create a ``PredictResponse`` instance with found=False and result=None and 
    without validation directly using `__new__`, and assigning the provided values 
    without performing any Python-level validation.

    Returns
    -------
    PredictResponse
        New ``PredictResponse`` instance indicating no result was found.

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

    cdef PredictResponse obj = <PredictResponse>PredictResponse.__new__(PredictResponse)
    obj.found = False
    obj.result = None
    return obj
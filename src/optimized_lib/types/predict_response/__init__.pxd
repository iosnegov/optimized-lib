# src/optimized_lib/types/predict_response/__init__.pxd
from optimized_lib.types.search_result cimport SearchResult

cdef class PredictResponse:

    cdef public bint found
    cdef public SearchResult result

    cpdef dict to_dict(self)
    cpdef str to_json(self, int indent, bint ensure_ascii=*)

cdef PredictResponse create_unsafe(SearchResult result)

cdef PredictResponse create_not_found()
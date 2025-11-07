# src/optimized_lib/types/search_result/__init__.pxd
from optimized_lib.types.coordinates cimport Coordinates

cdef class SearchResult:

    cdef public str description
    cdef public Coordinates coordinates
    cdef public float geo_distance

    cpdef dict to_dict(self)
    cpdef str to_json(self, int indent, bint ensure_ascii=*)

cdef SearchResult create_unsafe(str description, Coordinates coordinates, float geo_distance)
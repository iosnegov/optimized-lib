# src/optimized_lib/types/predict_request/__init__.pxd
from optimized_lib.types.coordinates cimport Coordinates

cdef bint is_valid_distance(float distance) noexcept nogil

cdef class PredictRequest:

    cdef public Coordinates coordinates
    cdef public float radius_meters

    cpdef dict to_dict(self)
    cpdef str to_json(self, int indent, bint ensure_ascii=*)

cdef PredictRequest create_unsafe(Coordinates coordinates, float radius_meters)
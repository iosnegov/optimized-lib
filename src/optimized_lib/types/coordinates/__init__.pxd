# src/optimized_lib/types/coordinates/__init__.pxd

cdef const float LAT_MIN
cdef const float LAT_MAX
cdef const float LON_MIN
cdef const float LON_MAX

cdef bint is_valid_coordinate(float value, float minv, float maxv) noexcept nogil

cdef class Coordinates:

    cdef public float latitude
    cdef public float longitude

    cpdef dict to_dict(self)
    cpdef str to_json(self, int indent, bint ensure_ascii=*)

cdef Coordinates create_unsafe(float latitude, float longitude)
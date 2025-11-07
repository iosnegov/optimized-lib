# setup.py
"""
Build configuration for the optimized_lib Cython extensions.

This script compiles performance-critical modules into C extensions
using Cython. It enables parallel execution (via OpenMP) and disables
runtime safety checks to maximize throughput for geographic nearest-neighbor
search and coordinate processing.

Notes
-----
- OpenMP flags (`-fopenmp`) enable parallel execution in `prange` loops. 
  The target virtual environment explicitly requires `gcc_linux-64 >=15.1.0,<16`, 
  which provides full OpenMP support — no additional configuration needed.
- All typed memoryviews and array accesses assume valid inputs; safety
  is enforced at the Python API boundary, not in Cython hot paths.
- The `src/` directory is added to `include_dirs` to allow relative cimports
  across the package (e.g., `from optimized_lib.types cimport ...`).
- NumPy C API headers are included via `np.get_include()` for typed memoryview support.
"""

from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np

# Define Cython extensions for each low-level module
# Structured as separate extensions to enable incremental compilation
# and clearer dependency isolation.
extensions = [
    Extension(
        "optimized_lib.core",
        sources=["src/optimized_lib/core/__init__.pyx"],
        include_dirs=[
            "src",              # Required for relative cimports within the package
            np.get_include()    # NumPy C API headers for typed memoryviews
        ],
        extra_compile_args=['-fopenmp'],
        extra_link_args=['-fopenmp']
    ),
    Extension(
        "optimized_lib.types.coordinates",
        sources=["src/optimized_lib/types/coordinates/__init__.pyx"],
        include_dirs=["src", np.get_include()]
    ),
    Extension(
        "optimized_lib.types.search_result",
        sources=["src/optimized_lib/types/search_result/__init__.pyx"],
        include_dirs=["src", np.get_include()]
    ),
    Extension(
        "optimized_lib.types.predict_request",
        sources=["src/optimized_lib/types/predict_request/__init__.pyx"],
        include_dirs=["src", np.get_include()]
    ),
    Extension(
        "optimized_lib.types.predict_response",
        sources=["src/optimized_lib/types/predict_response/__init__.pyx"],
        include_dirs=["src", np.get_include()]
    )
]

# Configure Cython compilation with performance-oriented directives.
# These settings prioritize speed over safety and are appropriate because:
# - Input validation is performed at the Python layer before calling Cython functions.
# - All arrays are assumed to be pre-validated and within declared bounds.
ext_modules = cythonize(
    extensions,
    annotate=True,  # Generates HTML annotation files for performance analysis
    compiler_directives={
        "language_level": "3",      # Enforce Python 3 syntax
        "boundscheck": False,       # Disable index bounds checking (critical for speed)
        "wraparound": False,        # Disable negative indexing (e.g., arr[-1])
        "cdivision": True,          # Use fast C-style division (no ZeroDivisionError)
        "initializedcheck": False   # Skip checks for uninitialized memoryviews
    }
)

setup(ext_modules=ext_modules)
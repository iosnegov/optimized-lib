# **Optimized Simple Geographic Recommendation System Library**

*An optimized simple library for building geographic recommendation systems.*

---

## **Overview**

This project is developed for educational purposes and demonstrates
how to combine geographic data processing with machine learning.

As an extension of the original implementation, this version rewrites 
performance‑critical custom code using Cython, 
leaving highly optimized libraries like scikit-learn unchanged.

The implementation uses:

- [scikit-learn](https://github.com/scikit-learn/scikit-learn) —
  for machine learning algorithms and nearest neighbor search.
- [pandas](https://github.com/pandas-dev/pandas) and
  [numpy](https://github.com/numpy/numpy) —
  for data handling and numerical computations.
- [joblib](https://github.com/joblib/joblib) —
  for efficient model serialization.
- [Hugging Face Hub](https://github.com/huggingface/huggingface_hub) —
  for cloud model storage and sharing.
- [Cython](https://github.com/cython/cython) —
  compiles Python-like code into C extensions to significantly accelerate custom computations.
  
Based on [simple-lib](https://github.com/Sierra-Arn/simple-lib) by Sierra Arn, which is licensed under BSD 3-Clause License.

## **Key Features**

- Haversine distance calculation for accurate geographic distances.
- Radius-based search for finding places within specified distance.
- Returns single best result.
- Callable interface for intuitive usage.

## **Optimized Core Features**

- **Cython-accelerated core routines**:  
Critical operations (coordinate validation, degree-to-radian conversion, single-query prediction) are implemented in Cython for near-C speed.
- **Zero-overhead coordinate validation**:  
Validates over a million coordinates in milliseconds using GIL-released loops and typed memoryviews for minimal overhead.
- **Parallel batch transformation**:  
Automatically parallelizes coordinate conversion for large inputs (>10,000 points) with controlled thread count.
- **Unsafe but fast response construction**:  
Bypasses runtime validation during inference via `_unsafe` object builders for minimal latency.
- **Seamless scikit-learn integration**:  
Retains full compatibility with scikit-learn’s `NearestNeighbors` while offloading hot paths to compiled code.

## **Library Installation**

> ⚠️ **Platform-Specific Binary**  
> The provided wheel (`optimized_lib-0.1.0-cp313-cp313-linux_x86_64.whl`) is a **pre-compiled binary for Linux x86_64** and **Python 3.13**.  
> It will **not work** on:
> - Different operating systems (e.g., Windows or macOS),
> - Different CPU architectures (e.g., ARM64),
> - Other Python versions (e.g., 3.12 or 3.14).

```bash
pip install https://github.com/Sierra-Arn/optimized-lib/releases/download/v0.1.0/optimized_lib-0.1.0-cp313-cp313-linux_x86_64.whl
```

> **Note:** if you’re on a different platform or Python version, **you must compile the library from source**.

## **Development and Testing**

### **I. Prerequisites**

- Package manager [Pixi](https://pixi.sh/latest/).

### **II. Project Structure**

```bash
optimized-lib/
├── src/                # Library source code
├── pyproject.toml      # Python package build configuration
├── setup.py            # Configuration for building and compiling Cython extensions
├── MANIFEST.in         # Includes Cython source files in source distributions (sdist)
├── dist/               # Package builds and distributions
├── tests/              # Tests and usage examples
├── pixi.toml           # Pixi project configuration and dependencies
└── pixi.lock           # Locked dependency versions
```

### **III. Environment Setup**

1. **Clone the repository:**

   ```bash
   git clone https://github.com/sierra-arn/optimized-lib.git
   cd optimized-lib
   ```

2. **Install dependencies:**

   ```bash
   pixi install --all
   ```

   > **Note**: The default `pixi.toml` targets `linux-64` (x86_64 Linux). If you're on a different platform (e.g., macOS, Windows, or ARM64), you may need to adjust the `[system]` requirements or dependency versions in `pixi.toml` to match your architecture.

### **IV. Main Pixi Commands**

1. Build the package (includes compilation of Cython extensions):

   ```bash
   pixi run -e build-env build-lib
   ```

2. Install the package in the test environment:

   ```bash
   pixi run -e test-env install-lib
   ```

3. Test the package with code coverage report:

   ```bash
   pixi run -e test-env test-lib
   ```

   > **Note:** an [interactive version](tests/test-lib.ipynb) is also available for testing code functionality.

## **License**

The project is distributed under the [BSD-3-Clause License](LICENSE).
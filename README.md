# Optimized Simple Geographic Recommendation System Library

*An optimized simple library for building geographic recommendation systems.*

> [!WARNING]  
> **Project Archived**
> 
> This project is no longer actively maintained. 
> 
> **Context:**  
> Originally, this repository was created to explore and learn the fundamentals of Cython. Rather than just reading about performance optimization, I wanted to learn through practice by rewriting performance-critical paths of my own original implementation, the [Simple Geographic Recommendation System Library](https://github.com/snegoviol/simple-lib). That said, it was purely a learning exercise and was never intended to be a production-ready or educational tool.
> 
> **Reason for Archiving:**  
> The primary goal of this repository has been achieved. Consequently, I no longer have an interest in further maintaining this codebase. This repository is now archived purely as a historical artifact, serving as a snapshot of my first steps with Cython and a reminder of where I started in software development.

## Brief Overview

This project is developed for educational purposes and demonstrates how to combine geographic data processing with machine learning. As an extension of the original implementation, this version rewrites performance-critical custom code using Cython, leaving highly optimized libraries like scikit-learn unchanged.

Key features include:

- **Haversine distance calculation** for accurate geographic distances.
- **Radius-based search** for finding places within a specified distance.
- **Single best result** returned based on proximity and relevance.
- **Callable interface** for intuitive and straightforward usage.

## Optimized Core Features

- **Cython-accelerated core routines**: Critical operations (coordinate validation, degree-to-radian conversion, single-query prediction) are implemented in Cython for near-C speed.
- **Zero-overhead coordinate validation**: Validates over a million coordinates in milliseconds using GIL-released loops and typed memoryviews for minimal overhead.
- **Parallel batch transformation**: Automatically parallelizes coordinate conversion for large inputs (>10,000 points) with controlled thread count.
- **Unsafe but fast response construction**: Bypasses runtime validation during inference via `_unsafe` object builders for minimal latency.
- **Seamless scikit-learn integration**: Retains full compatibility with scikit-learn’s `NearestNeighbors` while offloading hot paths to compiled code.

## Project Structure

```
optimized-lib/
├── src/                # Library source code
├── tests/              # Tests and usage examples
├── pyproject.toml      # Python package build configuration
├── setup.py            # Configuration for building and compiling Cython extensions
├── MANIFEST.in         # Includes Cython source files in source distributions (sdist)
├── pixi.toml           # Pixi project configuration, environments, and dependencies
└── pixi.lock           # Locked dependency versions for reproducible environments
```

## Dependencies Overview

| Dependency | Repository | What it is |
| :--- | :--- | :--- |
| **CPython** | [python/cpython](https://github.com/python/cpython) | The de facto standard implementation of the Python programming language. |
| **scikit-learn** | [scikit-learn/scikit-learn](https://github.com/scikit-learn/scikit-learn) | Machine learning algorithms and nearest neighbor search. |
| **pandas** | [pandas-dev/pandas](https://github.com/pandas-dev/pandas) | Data manipulation and analysis library. |
| **numpy** | [numpy/numpy](https://github.com/numpy/numpy) | Fundamental package for scientific computing and numerical operations. |
| **joblib** | [joblib/joblib](https://github.com/joblib/joblib) | Efficient serialization (pickling) of Python objects, especially large numpy arrays. |
| **huggingface_hub** | [huggingface/huggingface_hub](https://github.com/huggingface/huggingface_hub) | Client library for interacting with the Hugging Face Hub for model storage and sharing. |
| **Cython** | [cython/cython](https://github.com/cython/cython) | Compiler for writing C extensions for Python, used here to significantly accelerate custom computations. |

## Pre-built Installation

**Prerequisites**

| Component            | Requirement                               |
| :------------------- | :---------------------------------------- |
| **Operating System** | GNU/Linux-based system                    |
| **Architecture**     | `x86_64`                                  |
| **Python Version**   | `3.13`                                    |

> **Note:**  
> If your environment does not match these specifications, **you must compile the library from source**. Please refer to the [Local Development](#local-development) section for instructions.

If your environment matches the prerequisites, you can install the pre-built wheel directly.

**Via pip:**
```bash
pip install "optimized-lib @ https://github.com/snegoviol/optimized-lib/releases/download/v0.1.0/optimized_lib-0.1.0-cp313-cp313-linux_x86_64.whl"
```

**Via Pixi:**
```bash
pixi add --pypi "optimized-lib @ https://github.com/snegoviol/optimized-lib/releases/download/v0.1.0/optimized_lib-0.1.0-cp313-cp313-linux_x86_64.whl"
```

> **Note:**  
> You can find an example of how to use the library in the [interactive notebook](tests/test-lib.ipynb).

## Local Development

### I. Prerequisites

| Component            | Requirement                               |
| :------------------- | :---------------------------------------- |
| **Package Manager**  | [`Pixi`](https://pixi.prefix.dev/latest/) |
| **Operating System** | GNU/Linux-based system                    |
| **Architecture**     | `x86_64`                                  |

> **Note:**  
> These are not strict requirements, but rather the baseline environment where the code is 
> guaranteed to run out of the box. Alternative setups are possible but may require manual 
> configuration.

### II. Environment Setup

1. **Clone the repository**

    ```bash
    git clone https://github.com/snegoviol/optimized-lib.git
    cd optimized-lib
    ```

2. **Install dependencies**

    ```bash
    pixi install --all
    ```

### III. Build and Install

1. **Build the package** (includes compilation of Cython extensions):

    ```bash
    pixi run -e build-env build-lib
    ```

2. **Install the package in the test environment**:

    ```bash
    pixi run -e test-env install-lib
    ```

### IV. Testing

Once the environment is set up, you can test the package functionality using either automated tests or an interactive notebook.

1. **Run automated tests with a code coverage report:**

    ```bash
    pixi run -e test-env test-lib
    ```

2. **Explore the interactive notebook:**

    For a more hands-on approach, you can run the [interactive Jupyter notebook](tests/test-lib.ipynb) to test code functionality and explore usage examples step-by-step.

## License

Each file in this repository is licensed under the [MIT No Attribution License](LICENSE.txt).

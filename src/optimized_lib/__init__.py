"""
An optimized simple library for building geographic recommendation systems.

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

Example
-------
>>> from optimized_lib.model import GeoNearestNeighbor
>>> from optimized_lib.types import Coordinates, PredictRequest
>>> model = GeoNearestNeighbor()
>>> model.fit(dataframe)
>>> coordinates = Coordinates(latitude = 55.7, longitude = 37.56)
>>> predict_request = PredictRequest(coordinates = coordinates, radius_meters = 5000)
>>> response = model(predict_request)
>>> print(response.to_json(indent=2))
"""

__version__ = "0.1.0"
__author__ = "Sierra Arn"
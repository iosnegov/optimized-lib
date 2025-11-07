# src/optimized_lib/types/coordinates/__init__.pyi

class Coordinates:
    """
    Geographic coordinates.

    Parameters
    ----------
    latitude : float
        The latitude in decimal degrees. Must be in range [-90.0, 90.0].
    longitude : float
        The longitude in decimal degrees. Must be in range [-180.0, 180.0].

    Attributes
    ----------
    latitude : float
        The latitude value in decimal degrees.
    longitude : float
        The longitude value in decimal degrees.

    Raises
    ------
    ValueError
        If latitude or longitude values are out of valid range.
    """

    latitude: float
    longitude: float

    def __init__(self, latitude: float, longitude: float): 
        """
        Python-level initialization.
        
        Validates that coordinates are within 
        acceptable ranges before assigning values.
        """
        ...

    def to_dict(self) -> dict[str, float]: 
        """
        Convert the Coordinates object to a dictionary.

        Returns
        -------
        dict[str, float]
            A dictionary representation of the Coordinates object, 
            with keys 'latitude' and 'longitude'.
        """
        ...

    def to_json(self, indent: int, ensure_ascii: bool = True) -> str: 
        """
        Convert the Coordinates object to a JSON string representation.

        Parameters
        ----------
        indent : int
            The number of spaces to use for indentation in the output JSON string.

        ensure_ascii : bool, optional
            Ensures that non-ASCII characters are escaped if True (default `True`).

        Returns
        -------
        str
            A JSON string representation of the Coordinates object.
        """
        ...
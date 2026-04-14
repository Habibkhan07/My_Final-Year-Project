class InvalidAddressError(Exception):
    """
    Raised when the given address_id does not exist or does not belong to the
    requesting user. The service never distinguishes between the two cases so
    the caller cannot enumerate address IDs (IDOR prevention).
    """


class OutOfServiceAreaError(Exception):
    """
    Raised when the Haversine distance between the technician's base location
    and the customer's address exceeds the technician's max_travel_radius_km.

    Carries the actual distance so the view can include it in the error message.
    """
    def __init__(self, distance_km: float, radius_km: float):
        self.distance_km = round(distance_km, 1)
        self.radius_km = radius_km
        super().__init__(f"Distance {self.distance_km} km exceeds radius {radius_km} km")


class SlotUnavailableError(Exception):
    """
    Raised inside the atomic lock when a concurrent booking has already
    claimed the requested time window before this transaction committed.
    """

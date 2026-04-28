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


class InconsistentBookingIntentError(Exception):
    """
    Raised when the catalog references in the request body don't form a
    coherent triplet — e.g. ``sub_service_id`` whose parent ``Service`` is
    not the supplied ``service_id``, or a ``promotion_id`` whose
    ``target_service`` is a different category. Carries the field name
    that was inconsistent so the caller can surface a per-field error.
    """
    def __init__(self, field: str, message: str):
        self.field = field
        self.message = message
        super().__init__(f"{field}: {message}")


class PromoFirewallError(Exception):
    """
    Raised when a ``promotion_id`` is supplied alongside a fixed-price
    sub-service. Discount stacking on fixed gigs is forbidden by product
    rule (mirrors the read-side firewall in the pricing resolver).
    """


class PriceMismatchError(Exception):
    """
    Raised when ``price_amount`` doesn't match the figure derived from
    the catalog references + technician skill. Carries the expected
    bounds so the caller's error message can describe the gap.
    """
    def __init__(self, expected_min, expected_max, actual):
        self.expected_min = expected_min
        self.expected_max = expected_max
        self.actual = actual
        if expected_max is None or expected_max == expected_min:
            super().__init__(f"Expected {expected_min}, got {actual}")
        else:
            super().__init__(
                f"Expected between {expected_min} and {expected_max}, got {actual}"
            )

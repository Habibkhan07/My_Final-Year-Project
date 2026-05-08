from rest_framework.exceptions import APIException
from rest_framework import status as drf_status


# ---------------------------------------------------------------------------
# Booking orchestrator v1 (sprint 0008): canonical validation envelope.
#
# The orchestrator transitions raise ``BookingValidationError`` with a
# stable machine-readable ``code`` plus a human-readable ``message`` and
# an optional per-field ``errors`` dict. The custom DRF exception handler
# at ``core/common/failures/exception.py`` matches on this class FIRST and
# emits the canonical ``{status, code, message, errors}`` envelope without
# letting DRF's default flow override the code with the generic
# ``"validation_error"``.
#
# The pre-existing exceptions below (InvalidAddressError, ...) belong to
# the booking-creation path. They predate the standard envelope contract
# and are translated to envelope shape inside their callers' views, not
# here. Do NOT retrofit them onto ``BookingValidationError``.
# ---------------------------------------------------------------------------


class BookingValidationError(APIException):
    """Raised by ``bookings.services.orchestrator`` transition functions.

    Serialized by ``core.common.failures.exception.custom_exception_handler``
    into the canonical ``{status, code, message, errors}`` envelope.

    Always pass ``code`` (one of ``ERROR_*`` constants below) and a
    user-facing ``message``. Use ``errors={'field': ['detail', ...]}``
    only when the failure is per-field; transition guards typically pass
    ``{'current_status': [<status>]}`` so the client can render a
    contextual hint.
    """

    status_code = drf_status.HTTP_400_BAD_REQUEST
    default_detail = "Booking transition invalid."
    default_code = "invalid_transition"

    def __init__(
        self,
        *,
        code: str,
        message: str,
        errors: dict | None = None,
        status: int = drf_status.HTTP_400_BAD_REQUEST,
    ):
        self.status_code = status
        self.code = code
        self.message = message
        self.errors = errors or {}
        # APIException expects ``detail``; passing ``message`` keeps DRF logs
        # readable when the handler chain doesn't reach our custom branch.
        super().__init__(detail=message, code=code)


# Stable ``code`` strings for ``BookingValidationError``. Wire-strings —
# the Flutter side keys off these literals to surface user-friendly UI,
# so do not rename without coordinating a frontend change.
ERROR_INVALID_TRANSITION = "invalid_transition"
ERROR_INVALID_INPUT = "invalid_input"
ERROR_INVALID_QUOTE_EMPTY = "invalid_quote_empty"
ERROR_QUOTE_BAND_VIOLATION = "quote_band_violation"
ERROR_CANCELLATION_NOT_ALLOWED = "cancellation_not_allowed"
ERROR_DISPUTE_NOT_DISPUTABLE_STATUS = "dispute_not_disputable_status"
ERROR_RESCHEDULE_NOT_ALLOWED = "reschedule_not_allowed"
ERROR_NOT_ASSIGNED_TO_YOU = "not_assigned_to_you"
ERROR_NO_SHOW_TOO_EARLY = "no_show_too_early"
# Resource-not-found codes. Distinct from ERROR_INVALID_TRANSITION so the
# Flutter dispatcher can branch cleanly: 404 means "the thing you
# referenced doesn't exist" (gone, deleted, never existed) — different
# from "you cannot move from this state to that one."
ERROR_BOOKING_NOT_FOUND = "booking_not_found"
ERROR_QUOTE_NOT_FOUND = "quote_not_found"
ERROR_TICKET_NOT_FOUND = "ticket_not_found"


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


class BookingNotFoundForTechnicianError(Exception):
    """
    Raised by accept/decline when no JobBooking matches both the supplied
    primary key AND the requesting user as its assigned technician. The
    service deliberately collapses two cases — "booking does not exist"
    and "booking belongs to a different technician" — into the same
    exception so the API cannot leak booking-id existence to a non-owning
    technician (IDOR-safe enumeration defense).
    """


class BookingNotActionableError(Exception):
    """
    Raised by accept/decline when the booking has already left AWAITING and
    the request is therefore not the idempotent same-tech repeat (CONFIRMED
    for accept, REJECTED for decline). Carries ``current_status`` so the
    view can echo it in the error envelope for client-side debugging.

    Example transitions that raise this:
        - SLA timeout fired first  →  status == REJECTED, accept attempted
        - Customer cancelled first →  status == CANCELLED, either attempted
        - Booking already accepted →  status == CONFIRMED, decline attempted
    """
    def __init__(self, current_status: str):
        self.current_status = current_status
        super().__init__(f"Booking is no longer actionable (status={current_status}).")

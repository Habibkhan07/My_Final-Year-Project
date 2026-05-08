"""Auto-transition layer (sprint meta §14 rule 1).

Geofence-driven status flips. Triggered by the tech-location ingress
endpoint that lands in session 2: every GPS frame the technician's foreground
service publishes hits ``evaluate_on_location``, which decides whether to
flip the booking's status by distance threshold.

The orchestrator owns atomicity, broadcasts, and finance hooks; this module
is purely the trigger classifier — pick the transition, call the orchestrator,
return the new status string. Idempotency comes for free because the
orchestrator's transition functions short-circuit on already-target state.

Threshold semantics (sprint meta §14 rule 1):
    - CONFIRMED + GPS more than EN_ROUTE_THRESHOLD_METERS from the customer
      address is treated as "tech is moving" → flip to EN_ROUTE.
      v1 uses the customer's address as a stand-in for the accept-location
      anchor; v2 will record the tech's actual first-ping coordinates and
      compute the threshold from there. See sprint meta §14.
    - EN_ROUTE + GPS within ARRIVED_THRESHOLD_METERS of the customer
      address → flip to ARRIVED.
    - INSPECTING / QUOTED / IN_PROGRESS / terminal: never auto-flip.
      Frontend navigation drives ARRIVED → INSPECTING; the customer drives
      QUOTED → IN_PROGRESS via approve_quote.
"""

from __future__ import annotations

from math import asin, cos, radians, sin, sqrt

from bookings.models import JobBooking
from bookings.services import orchestrator


# §14 rule 1 thresholds.
EN_ROUTE_THRESHOLD_METERS = 200    # tech has left the accept-location vicinity
ARRIVED_THRESHOLD_METERS = 100     # tech is essentially at the customer's address


def evaluate_on_location(
    *,
    booking_id: int,
    lat: float,
    lng: float,
    technician_user,
) -> str | None:
    """Apply geofence rules to a tech-location frame; flip status if criteria met.

    Returns the new status string when a transition fired, or ``None`` when
    the frame did not move the booking.

    Idempotency is guaranteed by the orchestrator: callers can fire this on
    every GPS frame without worrying about duplicate transitions.

    Booking-not-found returns ``None`` silently — a stale GPS publisher on
    the tech's phone after the booking was cancelled should NOT raise; the
    foreground service simply stops publishing once the booking moves out
    of an active state at the next reload.
    """
    try:
        booking = JobBooking.objects.select_related('address').get(id=booking_id)
    except JobBooking.DoesNotExist:
        return None

    if booking.address is None:
        # Defensive: address FK is SET_NULL, so a deleted address can leave
        # the booking without a destination. Without coords there's nothing
        # to threshold against.
        return None

    # CustomerAddress.latitude / longitude are DecimalField; cast to float
    # for the trig functions. Decimal would otherwise propagate through
    # ``radians`` and explode on ``sqrt`` of a Decimal.
    cust_lat = float(booking.address.latitude)
    cust_lng = float(booking.address.longitude)

    if booking.status == JobBooking.STATUS_CONFIRMED:
        if _haversine_meters(lat, lng, cust_lat, cust_lng) > EN_ROUTE_THRESHOLD_METERS:
            orchestrator.en_route(
                booking_id=booking_id,
                technician_user=technician_user,
                source='auto',
            )
            return JobBooking.STATUS_EN_ROUTE
        return None

    if booking.status == JobBooking.STATUS_EN_ROUTE:
        if _haversine_meters(lat, lng, cust_lat, cust_lng) <= ARRIVED_THRESHOLD_METERS:
            orchestrator.arrived(
                booking_id=booking_id,
                technician_user=technician_user,
                source='auto',
            )
            return JobBooking.STATUS_ARRIVED
        return None

    return None


def _haversine_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in meters between two lat/lng pairs.

    Mirrors the formulation used by the matching selector; copied locally so
    auto_transition has no cross-feature dependency. The numeric outputs are
    accurate enough for 100m / 200m geofence thresholds in Pakistan
    latitudes (Earth's curvature error << threshold band at city scale).
    """
    earth_radius_m = 6_371_000
    phi1, phi2 = radians(lat1), radians(lat2)
    dphi = radians(lat2 - lat1)
    dlambda = radians(lng2 - lng1)
    a = sin(dphi / 2) ** 2 + cos(phi1) * cos(phi2) * sin(dlambda / 2) ** 2
    c = 2 * asin(sqrt(a))
    return earth_radius_m * c

import math
import decimal
from django.db import transaction
from django.utils import timezone

from technicians.models import TechnicianProfile
from bookings.exceptions import InvalidAddressError, OutOfServiceAreaError, SlotUnavailableError


# ---------------------------------------------------------------------------
# Pure math helper (inlined here to avoid coupling to matchmaking_selectors)
# ---------------------------------------------------------------------------

def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance between two GPS coordinates in kilometres."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

def create_instant_booking(
    *,
    customer_user,
    technician_id: int,
    address_id: int,
    scheduled_start,
    scheduled_end,
    price_amount: decimal.Decimal,
    price_context: str,
):
    """
    Creates a CONFIRMED JobBooking after passing four defensive checks:

    1. Address ownership — query is scoped to customer__user so a mismatched
       address_id raises DoesNotExist instead of returning another user's address.
       Caller converts DoesNotExist to a generic 400 so the error doesn't leak
       whether the address ID exists at all (IDOR prevention).

    2. Technician exists and is APPROVED.

    3. Geofence — Haversine distance must be ≤ tech.max_travel_radius_km.

    4. Slot race condition — inside transaction.atomic() + select_for_update()
       we re-check for any PENDING/CONFIRMED booking that overlaps the requested
       window. Half-open semantics: [start, end). A booking starting exactly at
       scheduled_end is NOT a conflict.

    Returns the newly created JobBooking instance.
    """
    # --- 1. Ownership check (IDOR-safe) ---
    # Import here to avoid a top-level circular import (customers → bookings → customers)
    from customers.models import CustomerAddress

    try:
        address = CustomerAddress.objects.select_related('customer__user').get(
            id=address_id,
            customer__user=customer_user,
        )
    except CustomerAddress.DoesNotExist:
        # Deliberately opaque — caller cannot tell whether the ID doesn't exist
        # or belongs to another user.
        raise InvalidAddressError()

    # --- 2. Technician guard ---
    tech = (
        TechnicianProfile.objects
        .filter(status='APPROVED')
        .get(pk=technician_id)
    )

    # --- 3. Geofence ---
    if tech.base_latitude is None or tech.base_longitude is None:
        # Technician hasn't set a base location yet — treat as out-of-range
        raise OutOfServiceAreaError(distance_km=float('inf'), radius_km=tech.max_travel_radius_km)

    distance_km = _haversine_km(
        float(tech.base_latitude), float(tech.base_longitude),
        float(address.latitude),   float(address.longitude),
    )

    if distance_km > tech.max_travel_radius_km:
        raise OutOfServiceAreaError(distance_km=distance_km, radius_km=tech.max_travel_radius_km)

    # --- 4. Atomic slot lock + race condition check + creation ---
    from bookings.models import JobBooking  # avoid circular at module level

    with transaction.atomic():
        # Lock the technician row so no concurrent booking can slip through
        # SECURITY: select_for_update prevents two simultaneous requests from
        # both passing the overlap check and both creating a double-booking
        TechnicianProfile.objects.select_for_update().get(pk=tech.pk)

        overlap_exists = JobBooking.objects.filter(
            technician=tech,
            status__in=[JobBooking.STATUS_PENDING, JobBooking.STATUS_CONFIRMED],
            # Half-open overlap: existing booking overlaps iff it starts before
            # our end AND ends after our start
            scheduled_start__lt=scheduled_end,
            scheduled_end__gt=scheduled_start,
        ).exists()

        if overlap_exists:
            raise SlotUnavailableError()

        booking = JobBooking.objects.create(
            technician=tech,
            customer=customer_user,
            address=address,
            scheduled_start=scheduled_start,
            scheduled_end=scheduled_end,
            status=JobBooking.STATUS_CONFIRMED,
            price_amount=price_amount,
            price_context=price_context,
        )

    return booking

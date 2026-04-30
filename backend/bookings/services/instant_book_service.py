import math
from typing import Optional

from django.db import transaction

from technicians.models import TechnicianProfile
from bookings.exceptions import (
    InconsistentBookingIntentError,
    InvalidAddressError,
    OutOfServiceAreaError,
    PromoFirewallError,
    SlotUnavailableError,
)
from bookings.selectors import resolve_booking_intent


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
# Catalog resolution helpers — strict-reject on missing/inactive references.
# ---------------------------------------------------------------------------

def _resolve_service(service_id: int):
    from catalog.models import Service
    try:
        return Service.objects.get(id=service_id)
    except Service.DoesNotExist:
        raise InconsistentBookingIntentError(
            field='service_id',
            message='No matching service found.',
        )


def _resolve_sub_service(sub_service_id: int):
    from catalog.models import SubService
    try:
        return SubService.objects.select_related('service').get(id=sub_service_id)
    except SubService.DoesNotExist:
        raise InconsistentBookingIntentError(
            field='sub_service_id',
            message='No matching sub-service found.',
        )


def _resolve_promotion(promotion_id: int):
    from marketing.models import Promotion
    try:
        return Promotion.objects.select_related('target_service').get(
            id=promotion_id,
            is_active=True,
        )
    except Promotion.DoesNotExist:
        raise InconsistentBookingIntentError(
            field='promotion_id',
            message='No matching active promotion found.',
        )


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

def create_instant_booking(
    *,
    customer_user,
    technician_id: int,
    address_id: int,
    service_id: int,
    scheduled_start,
    scheduled_end,
    sub_service_id: Optional[int] = None,
    promotion_id: Optional[int] = None,
):
    """
    Creates an AWAITING JobBooking after passing the defensive check pipeline.
    The booking transitions to CONFIRMED once the dispatched technician
    accepts within the SLA window (the accept endpoint is a separate sprint);
    if the SLA fires first, the timeout task flips it to REJECTED.

    Pipeline:

    1. Address ownership — query is scoped to ``customer__user`` so a mismatched
       ``address_id`` raises ``DoesNotExist`` instead of returning another
       user's address. The view converts that to a generic 400 so the response
       cannot enumerate address IDs (IDOR prevention).

    2. Technician exists and is APPROVED.

    3. Catalog consistency + promo firewall:
         * ``sub_service.service_id`` must equal ``service_id``.
         * ``promotion.target_service`` (when set) must equal ``service_id``.
         * A ``promotion_id`` paired with an ``is_fixed_price`` sub-service is
           rejected (no discount stacking on fixed gigs).

    4. Resolve the catalog intent into the persisted figure. The resolver
       is the single source of truth across read and write paths:
         * FIXED_GIG: ``sub_service.base_price``.
         * LABOR_GIG: technician's ``TechnicianSkill.labor_rate`` (or the
           sub-service base price when no rate is set).
         * INSPECTION: ``service.base_inspection_fee``.

       Stamped onto ``JobBooking.price_amount`` directly — no client value
       on the wire, so no validation step is needed.

    5. Geofence — Haversine distance must be ≤ ``tech.max_travel_radius_km``.

    6. Slot race condition — inside ``transaction.atomic()`` +
       ``select_for_update()`` we re-check for any PENDING/AWAITING/CONFIRMED
       booking that overlaps the requested window. Half-open semantics:
       ``[start, end)``. AWAITING is included because an unaccepted booking
       still reserves the technician's time window.

    Returns the newly created ``JobBooking`` instance.
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

    # --- 3. Catalog consistency + promo firewall ---
    service = _resolve_service(service_id)
    sub_service = _resolve_sub_service(sub_service_id) if sub_service_id else None
    promotion = _resolve_promotion(promotion_id) if promotion_id else None

    if sub_service is not None and sub_service.service_id != service.id:
        raise InconsistentBookingIntentError(
            field='sub_service_id',
            message='Sub-service does not belong to the supplied service.',
        )

    if (
        promotion is not None
        and promotion.target_service_id is not None
        and promotion.target_service_id != service.id
    ):
        raise InconsistentBookingIntentError(
            field='promotion_id',
            message='Promotion does not target the supplied service.',
        )

    if (
        promotion is not None
        and sub_service is not None
        and sub_service.is_fixed_price
    ):
        # Mirror the read-side firewall: discount stacking on fixed gigs is
        # forbidden. Reject loudly so a buggy Flutter cache cannot smuggle
        # a stale promo onto a fixed-price booking.
        raise PromoFirewallError()

    # --- 4. Resolve intent (server-derived price) ---
    intent = resolve_booking_intent(
        technician=tech,
        service=service,
        sub_service=sub_service,
        promotion=promotion,
    )

    # --- 5. Geofence ---
    if tech.base_latitude is None or tech.base_longitude is None:
        # Technician hasn't set a base location yet — treat as out-of-range
        raise OutOfServiceAreaError(distance_km=float('inf'), radius_km=tech.max_travel_radius_km)

    distance_km = _haversine_km(
        float(tech.base_latitude), float(tech.base_longitude),
        float(address.latitude),   float(address.longitude),
    )

    if distance_km > tech.max_travel_radius_km:
        raise OutOfServiceAreaError(distance_km=distance_km, radius_km=tech.max_travel_radius_km)

    # --- 6. Atomic slot lock + race condition check + creation ---
    from bookings.models import JobBooking  # avoid circular at module level
    from bookings.services.job_request_dispatch import dispatch_job_new_request_event

    with transaction.atomic():
        # Lock the technician row so no concurrent booking can slip through
        # SECURITY: select_for_update prevents two simultaneous requests from
        # both passing the overlap check and both creating a double-booking
        TechnicianProfile.objects.select_for_update().get(pk=tech.pk)

        overlap_exists = JobBooking.objects.filter(
            technician=tech,
            status__in=[
                JobBooking.STATUS_PENDING,
                JobBooking.STATUS_AWAITING_TECH_ACCEPT,
                JobBooking.STATUS_CONFIRMED,
            ],
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
            service=intent.service,
            sub_service=intent.sub_service,
            # ``intent.promotion`` is None for fixed gigs (firewall stripped)
            # even when a Promotion was resolved upstream; trusting the
            # resolver here keeps the firewall enforced at exactly one site.
            promotion=intent.promotion,
            scheduled_start=scheduled_start,
            scheduled_end=scheduled_end,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
            # Server-derived figure — single source of truth lives in the
            # pricing resolver, never on the wire.
            price_amount=intent.primary_amount,
            # Customer-receipt label, derived from the resolver. The column
            # stays as a denormalized snapshot so historical bookings render
            # consistently even if the catalog row is later renamed.
            price_context=intent.price_context_label,
        )

        # Fire the realtime event AND arm the SLA timeout only after the
        # booking row commits. on_commit guarantees no phantom WS frame /
        # FCM push / queued timeout if this transaction is rolled back by
        # an outer caller.
        transaction.on_commit(lambda: dispatch_job_new_request_event(booking))

    return booking

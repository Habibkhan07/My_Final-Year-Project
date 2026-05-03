"""
Builds the ``job_new_request`` event payload for a freshly-created booking
and dispatches it through the realtime hub + the SLA scheduler port.

Pure service layer: NO Celery imports. Scheduling is delegated to a
``JobDispatchScheduler`` adapter (see ``bookings/services/ports.py`` and
``bookings/adapters/__init__.py``). Tests pass a fake scheduler.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone as dt_timezone
from decimal import Decimal, ROUND_HALF_UP

from django.utils import timezone

from bookings.selectors import (
    BOOKING_TYPE_FIXED_GIG,
    BOOKING_TYPE_INSPECTION,
    BOOKING_TYPE_LABOR_GIG,
)
from bookings.services.ports import JobDispatchScheduler
from realtime.constants.event_types import EventType
from realtime.events.services import EventDispatchService

# --- Commission ------------------------------------------------------------
# Platform takes 20%; technician sees the net cut on their job card.
PLATFORM_COMMISSION_RATE = Decimal("0.20")
TECHNICIAN_NET_RATE = Decimal("1") - PLATFORM_COMMISSION_RATE  # 0.80

# --- Two-tier dispatch SLA -------------------------------------------------
# Tier 1 ("ASAP"): job starts within 2h → tech has 60s to accept.
# Tier 2 ("Scheduled"): job > 2h out  → tech has 15min to accept.
ASAP_THRESHOLD = timedelta(hours=2)
ASAP_TIMER_SECONDS = 60
SCHEDULED_TIMER_SECONDS = 15 * 60

# --- Wire-contract floor on the dispatch SLA -------------------------------
# The technician swipe-to-accept UI (low-literacy user, budget Android, often
# holding tools or in transit) needs at least 5 minutes between the offer
# arriving and the SLA expiring — enough time to notice the push, read the
# four blocks of detail, decide, and physically swipe across the runway.
# Applied at the dispatch site (NOT inside compute_dispatch_timer_seconds, so
# the pure tier function stays readable on its own). Single source of truth
# for both the wire payload and the Celery SLA countdown — flooring once
# before both calls keeps them locked together.
MIN_DISPATCH_SLA = timedelta(minutes=5)

# --- Technician-card prose -------------------------------------------------
# One short string per booking type. Keeps the Flutter card Dumb-UI: the
# technician's app renders payout_context verbatim and switches layout /
# affordances on booking_type. Inspection bookings carry the warning that
# the headline payout is just the visit fee — quote-built revenue follows.
_PAYOUT_CONTEXT_BY_TYPE = {
    BOOKING_TYPE_INSPECTION: "Inspection visit — quote built on-site",
    BOOKING_TYPE_FIXED_GIG: "Fixed-price gig — full payout",
    BOOKING_TYPE_LABOR_GIG: "Labor agreed up front",
}


def compute_technician_payout(price_amount: Decimal) -> str:
    """
    Net rupees the technician sees on their job card.

    Returned as an integer string ("1200") rather than a Decimal so the
    Flutter side parses it without float drift and can render verbatim.
    """
    net = (Decimal(price_amount) * TECHNICIAN_NET_RATE).quantize(
        Decimal("1"), rounding=ROUND_HALF_UP
    )
    return str(int(net))


def compute_dispatch_timer_seconds(scheduled_start: datetime) -> int:
    """
    Two-tier acceptance SLA based on how soon the job starts.

    A scheduled_start in the past collapses to Tier 1 (ASAP) — defensive
    against clock skew or stale slots; the booking is happening *now* or
    sooner, which is the most urgent case.
    """
    delta = scheduled_start - timezone.now()
    return ASAP_TIMER_SECONDS if delta <= ASAP_THRESHOLD else SCHEDULED_TIMER_SECONDS


def _to_iso_utc(value: datetime) -> str:
    """
    Serialize a tz-aware datetime to UTC ISO-8601 with a trailing ``Z``.

    Wire-format only — Flutter consumes the ISO string and renders the
    locale-aware label. The Dumb-UI principle (see CLAUDE.md and
    EVENT_DISPATCH_API.md) keeps display formatting on the client.
    """
    return value.astimezone(dt_timezone.utc).isoformat().replace("+00:00", "Z")


def _derive_booking_type(booking) -> str:
    """
    Reduce the booking's catalog FKs to a single discriminator the
    technician's app uses to pick the on-site flow (Complete vs. Build
    Quote) and the layout of the job card.

    Mirrors the resolver's classification — kept local here because the
    write side has the persisted FKs in hand and doesn't need to re-run
    the full pricing resolver.
    """
    if booking.sub_service_id is None:
        return BOOKING_TYPE_INSPECTION
    return (
        BOOKING_TYPE_FIXED_GIG
        if booking.sub_service.is_fixed_price
        else BOOKING_TYPE_LABOR_GIG
    )


def dispatch_job_new_request_event(
    booking,
    scheduler: JobDispatchScheduler | None = None,
) -> None:
    """
    Fan a ``job_new_request`` event at the assigned technician and arm the
    SLA timeout.

    Called from ``transaction.on_commit`` in ``create_instant_booking`` so a
    rolled-back booking never produces a phantom WS frame, FCM push, or
    queued timeout.

    Parameters
    ----------
    booking:
        Freshly committed ``JobBooking`` row.
    scheduler:
        Optional injected ``JobDispatchScheduler``. Tests pass a fake; in
        production we lazily resolve the Celery adapter via
        ``bookings.adapters.get_default_scheduler``. The lazy import keeps
        Celery off the service module's import graph.
    """
    # SECURITY: this dispatcher accepts only a freshly created JobBooking from
    # create_instant_booking, never user input — recipient (booking.technician.user)
    # and payload values are derived server-side, so there is no surface for a
    # client to redirect the broadcast or forge a job request to another technician.
    if scheduler is None:
        from bookings.adapters import get_default_scheduler  # lazy: see ports.py
        scheduler = get_default_scheduler()

    expires_in = compute_dispatch_timer_seconds(booking.scheduled_start)
    # Floor to the swipe-to-accept minimum. A future per-booking-type
    # policy that drops below 5 minutes would silently make the
    # technician UI unusable; enforce the wire contract at the source.
    expires_in = max(int(MIN_DISPATCH_SLA.total_seconds()), expires_in)
    booking_type = _derive_booking_type(booking)

    # Prefer the more specific catalog name. sub_service is set for fixed
    # and labor gigs; falls through to the parent service for inspection
    # bookings. Both FKs are server-controlled so neither can be missing
    # at this point — service is NOT NULL, sub_service was validated
    # against the resolved scenario at booking time.
    service_name = (
        booking.sub_service.name if booking.sub_service_id else booking.service.name
    )

    # Pre-composed locality string sourced from `CustomerAddress.locality_label`
    # (populated client-side at address creation; see session 4 / flag #15).
    # Null-safe on two axes: the address FK is SET_NULL, and legacy addresses
    # created before the locality columns existed have null `locality_label`.
    # The technician card hides the row when this is null rather than rendering
    # a placeholder.
    ui_location_label = (
        booking.address.locality_label if booking.address_id else None
    )

    payload = {
        "job_id": booking.id,
        "service_name": service_name,
        "booking_type": booking_type,
        "scheduled_start_iso": _to_iso_utc(booking.scheduled_start),
        "payout": compute_technician_payout(booking.price_amount),
        "payout_context": _PAYOUT_CONTEXT_BY_TYPE[booking_type],
        "expires_in_seconds": expires_in,
        "ui_location_label": ui_location_label,
    }

    EventDispatchService.broadcast_event(
        user=booking.technician.user,
        target_role="technician",
        event_type=EventType.JOB_NEW_REQUEST.value,
        payload=payload,
        # Top-level field drives ``envelope["expires_at"]`` and the
        # ``EventLog.expires_at`` column. Kept inside ``payload`` too as
        # ``expires_in_seconds`` so older clients that look there still
        # work during the rollout window. See flag #19.
        expires_in_seconds=expires_in,
    )

    scheduler.schedule_sla_timeout(
        booking_id=booking.id,
        delay_seconds=expires_in,
    )

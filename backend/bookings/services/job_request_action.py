"""
Technician-side accept / decline service for a dispatched job offer.

Both operations share an identical state-machine guard:
    - Booking row resolved by (pk, technician__user) — IDOR-safe.
    - SELECT FOR UPDATE serializes against the concurrent SLA timeout
      task (``bookings.tasks.expire_pending_job_booking``) and against
      the customer's cancellation flow. Whichever path commits first
      wins; the loser sees a non-AWAITING status on its re-read and
      either short-circuits (idempotent same-tech repeat) or raises
      ``BookingNotActionableError`` (observed conflict).
    - The customer-facing event is dispatched inside ``transaction.on_commit``
      so a rolled-back transaction never produces a phantom WS frame /
      FCM push / EventLog row, and the broadcast happens after the row
      lock is released (cheaper).

SLA-task cancellation: there is no explicit ``revoke``. Once status moves
out of AWAITING the Celery task's idempotent guard turns it into a no-op
when it eventually fires (see ``bookings/tasks.py::expire_pending_job_booking``).
Adding a Port-level revoke would buy nothing functional and would couple
the Port to a queue-library primitive.

Pure service layer: NO Celery imports. Event dispatch goes through
``EventDispatchService`` which itself fans to Channels + FCM + EventLog.
"""
from __future__ import annotations

from datetime import datetime, timezone as dt_timezone
from typing import Any

from django.db import transaction

from bookings.exceptions import (
    BookingNotActionableError,
    BookingNotFoundForTechnicianError,
)
from bookings.models import JobBooking
from realtime.constants.event_types import EventType
from realtime.events.services import EventDispatchService
from technicians.models import TechnicianProfile
from wallet.exceptions import WalletLockoutError
from wallet.selectors.lockout import is_wallet_locked, lockout_status


def _to_iso_utc(value: datetime) -> str:
    """ISO-8601 UTC string with trailing ``Z`` — wire-format only.

    Mirrors the helper in ``job_request_dispatch._to_iso_utc``; kept local
    here so the action service has zero coupling to the dispatch module.
    """
    return value.astimezone(dt_timezone.utc).isoformat().replace("+00:00", "Z")


def _build_job_accepted_payload(booking: JobBooking) -> dict[str, Any]:
    """
    Customer-facing ``job_accepted`` payload.

    Fields are all server-derived from the freshly-locked booking row.
    No client input flows through here. ``technician_display_name`` is
    composed via ``get_full_name`` so the customer's ``Job Accepted``
    surface can show the tech's name without a follow-up profile fetch.

    ``service_name`` prefers the more specific sub-service name when set
    (fixed gigs and labor gigs); falls back to the parent service for
    inspection-only bookings. Mirrors the dispatch payload's resolution
    so the customer's surface and the technician's offer card agree on
    naming.
    """
    service_name = (
        booking.sub_service.name if booking.sub_service_id else booking.service.name
    )
    return {
        "job_id": booking.id,
        "technician_id": booking.technician_id,
        "technician_display_name": booking.technician.user.get_full_name() or booking.technician.user.username,
        "scheduled_start_iso": _to_iso_utc(booking.scheduled_start),
        "service_name": service_name,
    }


def _build_booking_rejected_payload(
    booking: JobBooking, *, reason: str
) -> dict[str, Any]:
    """
    Customer-facing ``booking_rejected`` payload.

    ``reason`` discriminates the pathway: ``"technician_declined"`` for the
    technician-decline arm (``decline_job_booking``) and ``"sla_timeout"``
    for the SLA-expiry arm (``bookings.tasks.expire_pending_job_booking``).
    A single event type with a payload discriminator means the customer
    surface is one subscriber regardless of which pathway flipped the
    booking to REJECTED.
    """
    service_name = (
        booking.sub_service.name if booking.sub_service_id else booking.service.name
    )
    return {
        "job_id": booking.id,
        "technician_id": booking.technician_id,
        "scheduled_start_iso": _to_iso_utc(booking.scheduled_start),
        "service_name": service_name,
        "reason": reason,
    }


def _emit_job_accepted(booking: JobBooking) -> None:
    """Captured in ``transaction.on_commit`` — see callers."""
    EventDispatchService.broadcast_event(
        user=booking.customer,
        target_role="customer",
        event_type=EventType.JOB_ACCEPTED.value,
        payload=_build_job_accepted_payload(booking),
        # No SLA on this notification — the customer surface is informational.
        expires_in_seconds=None,
    )


def _emit_booking_rejected(booking: JobBooking, *, reason: str) -> None:
    """Captured in ``transaction.on_commit`` — see callers.

    ``reason`` is required and propagated into the payload discriminator —
    see ``_build_booking_rejected_payload``. Both the technician-decline
    arm and the SLA-expiry arm import this helper.
    """
    EventDispatchService.broadcast_event(
        user=booking.customer,
        target_role="customer",
        event_type=EventType.BOOKING_REJECTED.value,
        payload=_build_booking_rejected_payload(booking, reason=reason),
        expires_in_seconds=None,
    )


def _resolve_locked_booking(*, booking_id: int, technician_user) -> JobBooking:
    """
    Fetch the booking under SELECT FOR UPDATE, scoped to the technician
    making the request. Collapses the missing-row and wrong-owner cases
    into a single exception so the API layer cannot surface a
    distinguishable response (IDOR-safe).

    select_related on technician__user / customer / service / sub_service
    is mandatory — every downstream payload builder reads at least one
    of these. Adding the joins to the locking query keeps the action
    transaction inside a single round-trip even when the event payload
    is composed.
    """
    try:
        return (
            JobBooking.objects
            .select_for_update()
            .select_related(
                "technician__user",
                "customer",
                "service",
                "sub_service",
            )
            .get(pk=booking_id, technician__user=technician_user)
        )
    except JobBooking.DoesNotExist as exc:
        raise BookingNotFoundForTechnicianError() from exc


def accept_job_booking(*, booking_id: int, technician_user) -> JobBooking:
    """
    Transition a dispatched booking from AWAITING → CONFIRMED on behalf of
    the assigned technician and emit ``job_accepted`` to the customer.

    Idempotency
    -----------
    Calling this with a booking that is already CONFIRMED **for the same
    technician** returns the existing row unchanged and does NOT re-emit
    the event. This protects against retries (network flakiness, double-
    tap, FCM-driven repeat taps) without leaking a duplicate notification
    to the customer.

    Errors
    ------
    BookingNotFoundForTechnicianError
        Booking missing OR not assigned to this technician (the two are
        deliberately indistinguishable to the caller).
    BookingNotActionableError
        Booking has already moved to a terminal/non-AWAITING state that
        is not the same-tech idempotent CONFIRMED case (CANCELLED by
        customer, REJECTED by SLA, COMPLETED, PENDING).

    Wallet-lockout gate
    -------------------
    Per the negative-balance lockout policy (memory ``wallet-money-mechanics``),
    a tech whose wallet is currently underwater (``current_wallet_balance < 0``)
    cannot accept new dispatches until they top up. Raised as
    ``WalletLockoutError`` (HTTP 403 via the canonical envelope handler).

    The gate fires AFTER the idempotency and AWAITING checks: a tech who
    already accepted this booking yesterday (and is now locked) still gets
    the idempotent CONFIRMED back. The lockout is enforced only on the
    transition that would actually change state.

    SECURITY: queryset is scoped to ``technician__user=technician_user`` so
    a technician cannot accept another technician's offer; SELECT FOR
    UPDATE serializes against the SLA timeout task and the customer
    cancellation flow.
    """
    with transaction.atomic():
        booking = _resolve_locked_booking(
            booking_id=booking_id,
            technician_user=technician_user,
        )

        # Idempotent same-tech retry: treat as success without re-emitting.
        # The queryset already proved the requesting tech owns the row;
        # encountering CONFIRMED here means the same tech accepted in a
        # prior request that we never confirmed back to them. Done BEFORE
        # the lockout check so a previously-successful accept is not
        # retroactively reversed by a later wallet dip.
        if booking.status == JobBooking.STATUS_CONFIRMED:
            return booking

        if booking.status != JobBooking.STATUS_AWAITING_TECH_ACCEPT:
            raise BookingNotActionableError(current_status=booking.status)

        # Wallet-lockout gate. The booking lock above (`select_for_update`
        # on JobBooking, with `select_related` JOIN of the tech) only locks
        # the booking row — the tech's wallet balance could still race a
        # concurrent commission write. A separate `select_for_update` on
        # the TechnicianProfile row is mandatory: it observes the latest
        # committed balance AND serializes against any commission/refund
        # write currently mid-flight (those writes also hold this same
        # row lock via `wallet.services.ledger.record_transaction`).
        locked_tech = (
            TechnicianProfile.objects
            .select_for_update()
            .get(pk=booking.technician_id)
        )
        if is_wallet_locked(locked_tech):
            status = lockout_status(locked_tech)
            raise WalletLockoutError(
                balance_pkr=status["balance_pkr"],
                owed_pkr=status["owed_pkr"],
            )

        booking.status = JobBooking.STATUS_CONFIRMED
        booking.save(update_fields=["status"])

        # Customer notification on commit only. Ordering matters:
        # registering on_commit *after* the status mutation but *inside*
        # the atomic block guarantees that a downstream rollback (e.g.,
        # an outer caller in tests) suppresses the broadcast.
        transaction.on_commit(lambda: _emit_job_accepted(booking))

    return booking


def decline_job_booking(*, booking_id: int, technician_user) -> JobBooking:
    """
    Transition a dispatched booking from AWAITING → REJECTED on behalf of
    the assigned technician and emit ``booking_rejected`` to the customer
    (with ``reason: "technician_declined"``). Shares the wire envelope with
    the SLA-expiry path (``bookings.tasks.expire_pending_job_booking``,
    which emits with ``reason: "sla_timeout"``) — single customer-side
    subscriber regardless of which pathway flipped the booking to REJECTED.

    Idempotency
    -----------
    Calling this with a booking that is already REJECTED **for the same
    technician** returns the row unchanged and does NOT re-emit. Note
    REJECTED is also the terminal state used by the SLA-timeout task —
    if the timeout won the race we still report idempotent success here,
    because the technician's intent (decline) and the system's outcome
    (rejected) are the same end-state.

    Errors
    ------
    BookingNotFoundForTechnicianError
        Same as accept — IDOR-safe collapse.
    BookingNotActionableError
        Booking moved to CONFIRMED, COMPLETED, CANCELLED, or PENDING
        before this decline could land.

    SECURITY: same queryset-scoping + SELECT FOR UPDATE pattern as accept.
    """
    with transaction.atomic():
        booking = _resolve_locked_booking(
            booking_id=booking_id,
            technician_user=technician_user,
        )

        # Idempotent same-tech retry: REJECTED already, treat as success.
        # Includes the SLA-won-the-race case (both pathways flip AWAITING
        # → REJECTED), which is correct: the tech wanted to decline, the
        # system also rejected — end state matches the user's intent.
        if booking.status == JobBooking.STATUS_REJECTED:
            return booking

        if booking.status != JobBooking.STATUS_AWAITING_TECH_ACCEPT:
            raise BookingNotActionableError(current_status=booking.status)

        booking.status = JobBooking.STATUS_REJECTED
        booking.save(update_fields=["status"])

        transaction.on_commit(
            lambda: _emit_booking_rejected(booking, reason="technician_declined")
        )

    return booking

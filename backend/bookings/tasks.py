"""
Bookings Celery tasks.

Tasks operate on primitive IDs (never ORM instances) and re-fetch under
``select_for_update`` so they remain idempotent and safe to retry.
"""
from __future__ import annotations

import logging
# importing the importants libraries
from celery import shared_task
from django.db import transaction

logger = logging.getLogger(__name__)


@shared_task(name="bookings.expire_pending_job_booking")
def expire_pending_job_booking(booking_id: int) -> None:
    """
    Flip an AWAITING booking to TECH_NO_RESPONSE if the technician failed
    to reply within the SLA window. The AWAITING status itself is the
    "still waiting" signal — once the technician accepts, status moves to
    CONFIRMED and this task becomes a no-op.

    On a successful flip, emit ``booking_rejected`` to the customer with
    ``reason="sla_timeout"`` — same wire envelope the technician-decline
    arm emits with ``reason="technician_declined"`` (see
    ``bookings.services.job_request_action._emit_booking_rejected``). The
    customer surface is a single subscriber for both pathways; the
    DURABLE discriminator is the booking status (TECH_NO_RESPONSE here vs
    TECH_DECLINED on manual decline). The wire ``reason`` is kept for FCM
    body copy and the live banner, but the customer's orchestrator detail
    reads the status directly on refetch.

    Idempotent guards (any one short-circuits to a no-op):
        * booking row missing — nothing to mutate, no emit
        * ``status != AWAITING`` — technician already accepted (CONFIRMED),
          or the booking was cancelled / completed / rejected by another
          path before the timer fired; no emit

    SECURITY: ``select_for_update`` serializes against the customer's
    cancellation flow and the technician's accept flow; without it, two
    workers could race and one could overwrite the other's state.
    """
    # Imported inside the task to keep model load off the Celery worker
    # boot path (and to avoid app-loading order surprises).
    from bookings.models import JobBooking
    from bookings.services.job_request_action import _emit_booking_rejected

    with transaction.atomic():
        try:
            booking = (
                JobBooking.objects
                .select_for_update()
                .select_related(
                    "customer",
                    "service",
                    "sub_service",
                    # technician__user is required by _build_booking_rejected_payload's
                    # ``technician_display_name`` field — without this JOIN the on_commit
                    # emit would fire 2 extra queries (technician FK + user FK).
                    "technician__user",
                )
                .get(pk=booking_id)
            )
        except JobBooking.DoesNotExist:
            logger.info("SLA timeout: booking %s not found, skipping.", booking_id)
            return

        if booking.status != JobBooking.STATUS_AWAITING_TECH_ACCEPT:
            logger.info(
                "SLA timeout: booking %s in status %s (not AWAITING), skipping.",
                booking_id,
                booking.status,
            )
            return

        booking.status = JobBooking.STATUS_TECH_NO_RESPONSE
        booking.save(update_fields=["status"])

        # Emit on commit — registering inside the atomic block guarantees
        # a rolled-back transaction never produces a phantom WS frame /
        # FCM push / EventLog row.
        transaction.on_commit(
            lambda: _emit_booking_rejected(booking, reason="sla_timeout")
        )

        logger.info(
            "SLA timeout fired: booking %s flipped AWAITING → TECH_NO_RESPONSE.",
            booking_id,
        )


# This is change made by me
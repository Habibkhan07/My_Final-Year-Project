"""
Bookings Celery tasks.

Tasks operate on primitive IDs (never ORM instances) and re-fetch under
``select_for_update`` so they remain idempotent and safe to retry. Customer
notification on SLA timeout is intentionally out of scope this sprint —
DB state mutation only.
"""
from __future__ import annotations

import logging

from celery import shared_task
from django.db import transaction

logger = logging.getLogger(__name__)


@shared_task(name="bookings.expire_pending_job_booking")
def expire_pending_job_booking(booking_id: int) -> None:
    """
    Flip an AWAITING booking to REJECTED if the technician failed to
    accept it within the SLA window. The AWAITING status itself is the
    "still waiting" signal — once the technician accepts, status moves to
    CONFIRMED and this task becomes a no-op.

    Idempotent guards (any one short-circuits to a no-op):
        * booking row missing — nothing to mutate
        * ``status != AWAITING`` — technician already accepted (CONFIRMED),
          or the booking was cancelled / completed / rejected by another
          path before the timer fired

    SECURITY: ``select_for_update`` serializes against the customer's
    cancellation flow and the technician's accept flow; without it, two
    workers could race and one could overwrite the other's state.
    """
    # Imported inside the task to keep model load off the Celery worker
    # boot path (and to avoid app-loading order surprises).
    from bookings.models import JobBooking

    with transaction.atomic():
        try:
            booking = JobBooking.objects.select_for_update().get(pk=booking_id)
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

        booking.status = JobBooking.STATUS_REJECTED
        booking.save(update_fields=["status"])
        logger.info(
            "SLA timeout fired: booking %s flipped AWAITING → REJECTED.",
            booking_id,
        )

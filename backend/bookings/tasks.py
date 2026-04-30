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
    Flip a CONFIRMED booking to REJECTED if the technician failed to
    acknowledge it within the SLA window.

    Idempotent guards (any one short-circuits to a no-op):
        * booking row missing — nothing to mutate
        * ``accepted_at`` already set — technician acknowledged in time
        * ``status != CONFIRMED`` — booking already cancelled / completed
          / rejected by another path

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

        if booking.accepted_at is not None:
            logger.info(
                "SLA timeout: booking %s already accepted at %s, skipping.",
                booking_id,
                booking.accepted_at,
            )
            return

        if booking.status != JobBooking.STATUS_CONFIRMED:
            logger.info(
                "SLA timeout: booking %s in status %s (not CONFIRMED), skipping.",
                booking_id,
                booking.status,
            )
            return

        booking.status = JobBooking.STATUS_REJECTED
        booking.save(update_fields=["status"])
        logger.info(
            "SLA timeout fired: booking %s flipped CONFIRMED → REJECTED.",
            booking_id,
        )

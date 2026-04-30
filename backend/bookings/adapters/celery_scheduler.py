"""
Celery-backed adapter for the ``JobDispatchScheduler`` port.

This is the only file in the bookings app that knows the SLA timeout
runs on Celery. Swap to a different queue backend by writing a sibling
adapter and pointing ``get_default_scheduler`` at it — the service layer
will not notice.
"""
from __future__ import annotations

from bookings.tasks import expire_pending_job_booking


class CelerySchedulerAdapter:
    """
    Production ``JobDispatchScheduler`` implementation.

    Conforms structurally to ``bookings.services.ports.JobDispatchScheduler``;
    no explicit inheritance because Protocols use structural typing.
    """

    def schedule_sla_timeout(self, *, booking_id: int, delay_seconds: int) -> None:
        # countdown=N tells Celery to defer execution by N seconds without
        # blocking the web worker. The task itself is idempotent and safe
        # to fire even if the booking was already accepted/cancelled.
        #customer need to be notified which is not in current sprint
        expire_pending_job_booking.apply_async(
            args=[booking_id],
            countdown=delay_seconds,
        )

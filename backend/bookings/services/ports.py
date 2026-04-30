"""
Bookings service-layer ports.

A *port* is the abstract boundary the service layer depends on. Concrete
adapters (Celery, Django-Q, in-memory fakes for tests) implement these
Protocols and live under ``bookings/adapters/``.

Why this exists: the service layer must remain free of infrastructure
imports (Celery, Redis, FCM, ...). Code that asks "schedule this thing for
later" gets a ``JobDispatchScheduler`` parameter, never a Celery task
reference. That keeps services unit-testable and the import graph clean —
swapping the queue backend touches adapters only, never services.
"""
from __future__ import annotations

from typing import Protocol


class JobDispatchScheduler(Protocol):
    """
    Schedules deferred work tied to a job booking.

    Implementations MUST be safe to call multiple times for the same booking
    without producing duplicate state mutations — the underlying task is
    expected to be idempotent.
    """

    def schedule_sla_timeout(self, *, booking_id: int, delay_seconds: int) -> None:
        """
        Arrange for the SLA timeout task to run ``delay_seconds`` from now.

        On fire, the task flips the booking's status to REJECTED iff it is
        still ``AWAITING`` (the technician has not accepted yet). Any other
        status — CONFIRMED, CANCELLED, COMPLETED, REJECTED — short-circuits
        to a no-op. No customer notification — DB state mutation only.
        """
        ...

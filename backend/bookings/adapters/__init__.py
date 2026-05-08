"""
Adapters bind ports defined in ``bookings/services/ports.py`` to concrete
infrastructure (Celery, FCM, etc.). Service code depends on Protocols
from ``ports``, not on anything in this package.

``get_default_scheduler`` is the production wiring. It exists here so the
service layer can resolve a default scheduler without importing Celery
directly: the import is deferred until the function runs, keeping
``bookings.services.*`` modules free of queue-library imports at
top level. Tests inject a fake instead of calling this.
"""
from __future__ import annotations

from bookings.services.ports import JobDispatchScheduler


def get_default_scheduler() -> JobDispatchScheduler:
    """
    Return the production ``JobDispatchScheduler``.

    The Celery import is intentionally inside the function body — the whole
    point of the Port/Adapter split is that ``import bookings.services.*``
    must not transitively pull in Celery. Resolving the adapter on demand
    preserves that boundary.
    """
    from bookings.adapters.celery_scheduler import CelerySchedulerAdapter

    return CelerySchedulerAdapter()


def get_default_finance_service():
    """
    Return the production ``FinancePort`` adapter.

    Lazy-imports ``NullFinanceAdapter`` for the booking orchestrator sprint;
    the finance sprint swaps the body to return a wallet-backed adapter
    without touching any service-layer caller. The lazy import preserves
    the same boundary as ``get_default_scheduler``: importing
    ``bookings.services.*`` must never transitively pull in finance code.
    """
    from bookings.adapters.null_finance import NullFinanceAdapter

    return NullFinanceAdapter()

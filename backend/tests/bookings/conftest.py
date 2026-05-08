"""Shared fixtures for the bookings test tree.

The orchestrator's service-layer tests at
``tests/bookings/services/test_orchestrator.py`` defined ``fake_finance``
and ``captured_broadcasts`` as file-local fixtures. Session 2 tests
across the api/ + selectors/ sub-trees need the same primitives, so
they're hoisted here. The original copies stay in ``test_orchestrator.py``
to keep that file self-contained — pytest's local-fixture-wins
semantics mean nothing breaks.
"""
from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from bookings.services import orchestrator


@pytest.fixture
def fake_finance():
    """A MagicMock standing in for FinancePort.

    ``can_accept_job`` returns ``(True, None)`` by default; tests override
    when exercising lockout paths.
    """
    m = MagicMock()
    m.can_accept_job.return_value = (True, None)
    m.record_commission.return_value = None
    m.apply_inspection_fee_decision.return_value = None
    m.apply_cancellation_charge.return_value = None
    m.record_cash_collected.return_value = None
    return m


@pytest.fixture
def captured_broadcasts():
    """Hijack ``orchestrator._broadcast`` + force ``on_commit`` to fire inline.

    Pytest-django's default test transaction rolls back at teardown so
    ``transaction.on_commit`` callbacks never run. We patch both:
        * ``orchestrator._broadcast`` to record every emit
        * ``orchestrator.transaction.on_commit`` to invoke its callback
          immediately

    Yields a list — tests assert on ``len`` / per-call ``event_type`` /
    ``payload`` keys.

    Tests that need real rollback semantics still opt into
    ``@pytest.mark.django_db(transaction=True)`` separately.
    """
    calls: list[dict] = []

    def _capture(*, user, target_role, event_type, payload):
        calls.append({
            "user": user,
            "target_role": target_role,
            "event_type": event_type,
            "payload": payload,
        })

    def _immediate_on_commit(func, using=None):
        func()

    with (
        patch.object(orchestrator, "_broadcast", side_effect=_capture),
        patch(
            "bookings.services.orchestrator.transaction.on_commit",
            side_effect=_immediate_on_commit,
        ),
    ):
        yield calls

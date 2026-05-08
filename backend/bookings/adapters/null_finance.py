"""NullFinanceAdapter — no-op concrete adapter for ``FinancePort``.

Selected by ``adapters.get_default_finance_service()`` for the booking
orchestrator sprint and for any test that doesn't need real money flow.
The finance sprint will introduce a wallet-backed adapter alongside this
file; selection happens in ``adapters/__init__.py``.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Literal


class NullFinanceAdapter:
    """Implements ``bookings.services.finance_ports.FinancePort`` structurally.

    Every method is a no-op so the orchestrator's atomic blocks complete
    cleanly without touching any wallet plumbing. ``can_accept_job`` always
    permits — the lockout check moves to the real adapter when the wallet
    sprint lands.
    """

    def can_accept_job(self, *, technician, payout_amount: Decimal) -> tuple[bool, str | None]:
        return (True, None)

    def record_commission(self, *, booking, amount: Decimal) -> None:
        return None

    def apply_inspection_fee_decision(
        self,
        *,
        booking,
        decision: Literal['accepted', 'declined'],
    ) -> None:
        return None

    def apply_cancellation_charge(
        self,
        *,
        booking,
        actor: Literal['customer', 'tech'],
        phase: Literal['pre_accept', 'pre_arrival', 'post_arrival'],
    ) -> None:
        return None

    def record_cash_collected(
        self,
        *,
        booking,
        amount: Decimal,
        method: str,
    ) -> None:
        return None

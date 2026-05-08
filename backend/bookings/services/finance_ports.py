"""Finance ports for the booking orchestrator (sprint meta §9).

The orchestrator must NOT import wallet, commission, or JazzCash machinery
directly — that machinery doesn't exist yet (deferred to the finance
sprint). Instead, the orchestrator depends on the ``FinancePort`` Protocol
below, and ``NullFinanceAdapter`` (in ``adapters/null_finance.py``) provides
no-op implementations for this sprint. The finance sprint will swap in a
real adapter without touching orchestrator code.

Atomicity contract: every method here is called INSIDE the same
``transaction.atomic()`` block as the status mutation it accompanies. Real
adapters MAY raise (e.g. wallet lockout on accept) — the orchestrator must
let exceptions propagate so the surrounding transaction rolls back. The
null adapter never raises, so this sprint cannot exercise the rollback
path; finance-sprint integration tests will.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Literal, Protocol


class FinancePort(Protocol):
    """The single Protocol the orchestrator depends on.

    Five methods, one Protocol. Do not split into per-call mini-Protocols —
    every concrete adapter (null this sprint, wallet next sprint) implements
    the same surface. Splitting fragments the dependency graph for no gain.
    """

    def can_accept_job(
        self,
        *,
        technician,
        payout_amount: Decimal,
    ) -> tuple[bool, str | None]:
        """Lockout check before a technician accepts a job.

        Returns ``(allowed, reason_code_or_None)``. When ``allowed`` is
        ``False``, ``reason_code`` is a stable machine-readable string
        (e.g. ``"wallet_below_threshold"``) the caller surfaces in the
        error envelope. The null adapter always returns ``(True, None)``.
        """
        ...

    def record_commission(self, *, booking, amount: Decimal) -> None:
        """Called on the IN_PROGRESS → COMPLETED transition.

        The finance sprint will create ``JobCommission`` and
        ``WalletTransaction`` rows here. The null adapter is a no-op so
        the booking lifecycle works end-to-end without finance plumbing.
        """
        ...

    def apply_inspection_fee_decision(
        self,
        *,
        booking,
        decision: Literal['accepted', 'declined'],
    ) -> None:
        """Called on QUOTED → IN_PROGRESS (``decision='accepted'``) or
        QUOTED → COMPLETED_INSPECTION_ONLY (``decision='declined'``).

        Inspection-fee bookkeeping (Rs.500 deducted from the final bill on
        accept, owed as cash on decline) is computed by the orchestrator
        regardless. This hook lets the finance sprint additionally write
        a wallet entry. Null adapter: no-op.
        """
        ...

    def apply_cancellation_charge(
        self,
        *,
        booking,
        actor: Literal['customer', 'tech'],
        phase: Literal['pre_accept', 'pre_arrival', 'post_arrival'],
    ) -> None:
        """Called on every ``... → CANCELLED`` transition.

        Penalty/fee column writes happen on the booking row regardless;
        this hook lets finance log a wallet entry for the Rs.500 owed
        (customer-cancel post-accept) or a reliability-related charge
        (tech-cancel). Null adapter: no-op.
        """
        ...

    def record_cash_collected(
        self,
        *,
        booking,
        amount: Decimal,
        method: str,
    ) -> None:
        """Called on IN_PROGRESS → COMPLETED after the tech taps the
        combined ``Cash Collected: Rs.X`` button (sprint meta §14 rule 2).

        Booking columns (``cash_collected_amount``, ``cash_collected_at``,
        ``cash_collection_method``) are stamped by the orchestrator. The
        finance sprint will additionally write a ``WalletTransaction``
        here. Null adapter: no-op.
        """
        ...

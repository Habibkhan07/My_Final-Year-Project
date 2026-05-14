"""Wallet lockout — single source of truth for the negative-balance rule.

The rule is structural, not configurable:

    is_wallet_locked(tech)  ⇔  tech.current_wallet_balance < 0

Zero is allowed; only strictly-negative balance triggers lockout. The
reasoning lives in memory ``wallet-money-mechanics``: commission magnitude
is unknown at accept-job time (decided in the post-inspection quote phase),
so any positive threshold would be an arbitrary made-up number with no
business meaning. Going negative is the only signal with real semantics —
the tech currently owes the platform money.

Every gate that consumes the lockout signal MUST import from here. Do NOT
re-implement ``balance < 0`` inline in service code, serializers, or
adapters — the entire point of this module is that the rule changes in
one place if it ever changes at all.
"""
from __future__ import annotations

from decimal import Decimal, ROUND_FLOOR
from typing import TypedDict

from technicians.models import TechnicianProfile


class LockoutStatus(TypedDict):
    """Dumb-UI payload shape returned by :func:`lockout_status`."""

    is_locked_out: bool
    balance_pkr: int
    owed_pkr: int


def is_wallet_locked(technician: TechnicianProfile) -> bool:
    """Return True iff the technician's wallet balance is strictly negative.

    SECURITY / CONCURRENCY: the caller is responsible for ensuring
    ``technician.current_wallet_balance`` is fresh. When this selector is
    consumed inside a transaction that intends to use the result for a
    gating decision (e.g. ``accept_job_booking``), the caller MUST have
    re-fetched the row under ``select_for_update`` first — otherwise a
    concurrent commission write could land between this read and the
    decision, producing a stale "not locked" answer for a wallet that
    has just dipped below zero.
    """
    return technician.current_wallet_balance < Decimal('0')


def lockout_status(technician: TechnicianProfile) -> LockoutStatus:
    """Return the three-field Dumb-UI payload for wallet detail / errors.

    The keys mirror the canonical envelope shape used by
    :class:`wallet.exceptions.WalletLockoutError` so the same selector can
    feed both the wallet GET endpoint and the error-envelope payload
    without bespoke wiring.

    Rounding policy
    ---------------
    For negative balances we use ``ROUND_FLOOR`` on the balance and the
    additive inverse for ``owed_pkr``. This guarantees the invariant::

        balance_pkr + owed_pkr == 0   (when locked)

    so the displayed numbers reconcile visually for the tech: "balance
    Rs. -101, owed Rs. 101". Truncation toward zero on a sub-rupee paisa
    fraction (e.g. balance -100.01) would under-report the obligation by
    a paisa — a tech paying ``owed_pkr`` should fully clear the lockout,
    not be left a paisa short. Whole-rupee inputs (the practical case)
    behave identically under either rounding mode.

    For non-negative balances ``int()`` truncates toward zero (no change
    from the natural Python behavior). ``owed_pkr`` is always 0 when
    not locked.
    """
    balance = technician.current_wallet_balance
    locked = balance < Decimal('0')

    if locked:
        # ROUND_FLOOR rounds toward -infinity, so -100.01 → -101.
        balance_int = int(balance.quantize(Decimal('1'), rounding=ROUND_FLOOR))
        owed_int = -balance_int  # balance_int is negative; flip the sign
    else:
        balance_int = int(balance)  # truncates toward zero for positives
        owed_int = 0

    return {
        "is_locked_out": locked,
        "balance_pkr": balance_int,
        "owed_pkr": owed_int,
    }

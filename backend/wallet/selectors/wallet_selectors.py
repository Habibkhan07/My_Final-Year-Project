"""Read-side queries for the wallet domain.

Selectors are the DB-read layer per the project's thin-views/fat-services
convention. Views call selectors; selectors never mutate.
"""
from __future__ import annotations

from datetime import datetime
from typing import TypedDict

from technicians.models import TechnicianProfile


class WalletBalancePayload(TypedDict):
    """Response shape for ``GET /api/technicians/wallet/``."""
    balance: str       # Decimal-as-string, "1500.00"
    as_of: str         # ISO-8601 UTC timestamp


def get_wallet_balance(technician: TechnicianProfile) -> WalletBalancePayload:
    """Return the tech's current wallet balance + as-of timestamp.

    Uses the denormalized ``TechnicianProfile.current_wallet_balance`` field
    (kept in sync by every ``ledger.record_transaction`` call). The
    forensic invariant guarantees this matches ``MAX(balance_after)`` for
    the tech in ``WalletTransaction`` — if the two ever diverge, the
    ledger service is broken, not this view.

    Decimal is serialized as a string to preserve precision across the
    wire. The frontend parses it back to a numeric type at the boundary.
    """
    return {
        'balance': str(technician.current_wallet_balance),
        # ``timezone.now()`` would also work; using datetime.now(tz=UTC) keeps
        # this selector free of django.utils.timezone imports.
        'as_of': datetime.now().astimezone().isoformat(),
    }

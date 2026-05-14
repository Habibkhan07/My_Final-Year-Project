"""Read-side queries for the wallet domain.

Selectors are the DB-read layer per the project's thin-views/fat-services
convention. Views call selectors; selectors never mutate.
"""
from __future__ import annotations

import base64
import binascii
from datetime import datetime
from typing import Optional, TypedDict

from django.db.models import Q

from technicians.models import TechnicianProfile
from wallet.models import TransactionType, WalletTransaction
from wallet.selectors.lockout import lockout_status


class WalletBalancePayload(TypedDict):
    """Response shape for ``GET /api/technicians/wallet/``.

    Five fields, two concerns:

    * Display fidelity (``balance``, ``as_of``) — preserves the legacy
      Decimal-as-string contract for currency rendering.
    * Lockout state (``is_locked_out``, ``balance_pkr``, ``owed_pkr``) —
      Dumb-UI payload from ``wallet.selectors.lockout.lockout_status``.
      The frontend banner composes "Top up Rs. {owed_pkr} to come online"
      without any client-side math.
    """
    balance: str          # Decimal-as-string, "1500.00"
    as_of: str            # ISO-8601 UTC timestamp
    is_locked_out: bool
    balance_pkr: int
    owed_pkr: int


def get_wallet_balance(technician: TechnicianProfile) -> WalletBalancePayload:
    """Return the tech's current wallet balance + lockout state + as-of timestamp.

    Uses the denormalized ``TechnicianProfile.current_wallet_balance`` field
    (kept in sync by every ``ledger.record_transaction`` call). The
    forensic invariant guarantees this matches ``MAX(balance_after)`` for
    the tech in ``WalletTransaction`` — if the two ever diverge, the
    ledger service is broken, not this view.

    Decimal is serialized as a string to preserve precision across the
    wire. The frontend parses it back to a numeric type at the boundary.

    Lockout state comes from ``wallet.selectors.lockout.lockout_status``,
    which is the single source of truth for the negative-balance rule.
    The fields are additive over the legacy two-field payload so existing
    Flutter clients that only parse ``balance`` + ``as_of`` keep working.
    """
    status = lockout_status(technician)
    return {
        'balance': str(technician.current_wallet_balance),
        # ``timezone.now()`` would also work; using datetime.now(tz=UTC) keeps
        # this selector free of django.utils.timezone imports.
        'as_of': datetime.now().astimezone().isoformat(),
        'is_locked_out': status['is_locked_out'],
        'balance_pkr': status['balance_pkr'],
        'owed_pkr': status['owed_pkr'],
    }


# ---------------------------------------------------------------------------
# Transaction history (cursor-paginated, Dumb-UI-shaped)
# ---------------------------------------------------------------------------

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 50


class InvalidCursor(ValueError):
    """Raised when the inbound ``cursor`` query param cannot be decoded.

    The view catches this and emits the standard 400 error envelope so
    a tampered cursor can't pollute the query layer with garbage.
    """


def list_transactions(
    technician: TechnicianProfile,
    *,
    cursor: Optional[str] = None,
    page_size: int = DEFAULT_PAGE_SIZE,
) -> dict:
    """Return one page of the tech's wallet ledger, newest-first.

    Why cursor over offset
    ----------------------
    The ledger is an append-only timeline. With offset pagination, a new
    row written between requests shifts every page boundary and the next
    page silently shows a duplicate row. Cursor on ``(-timestamp, -id)``
    is stable under concurrent writes — a new row appears at the front
    where the user can refresh-to-see, and never inside the in-flight
    pagination window.

    Cursor encoding: base64 of ``"<iso_timestamp>|<id>"``. Opaque to the
    client; the frontend just round-trips whatever ``next_cursor`` the
    previous page returned. Tampered/malformed cursors raise
    ``InvalidCursor`` (view → 400 envelope).

    select_related touches all four 1:1 subtypes in one JOIN so the
    Dumb-UI shaper below stays N+1-free regardless of the row mix.
    """
    page_size = max(1, min(int(page_size), MAX_PAGE_SIZE))

    qs = (
        WalletTransaction.objects
        .filter(technician=technician)
        .select_related(
            'topup',
            'job_commission',
            'job_commission__booking',
            'refund_deduction',
            'withdrawal_fulfilment',
            'withdrawal_fulfilment__withdrawal_request',
        )
        .order_by('-timestamp', '-id')
    )

    if cursor:
        cursor_ts, cursor_id = _decode_cursor(cursor)
        # "Strictly after the cursor row in newest-first order" =
        # earlier timestamp, OR same timestamp with smaller id.
        qs = qs.filter(
            Q(timestamp__lt=cursor_ts)
            | Q(timestamp=cursor_ts, id__lt=cursor_id)
        )

    # Fetch one extra to detect whether another page exists without a
    # COUNT(*) query.
    rows = list(qs[: page_size + 1])
    has_next = len(rows) > page_size
    page = rows[:page_size]

    next_cursor = None
    if has_next:
        last = page[-1]
        next_cursor = _encode_cursor(last.timestamp, last.id)

    return {
        'results': [_shape_row(row) for row in page],
        'next_cursor': next_cursor,
    }


# --- Dumb-UI row shaping -----------------------------------------------------

def _shape_row(row: WalletTransaction) -> dict:
    """Return one ledger row as a Flutter-ready, type-discriminated dict.

    The frontend's TransactionRow widget must NOT branch on
    ``transaction_type`` — that's a violation of the Dumb-UI rule.
    Instead we shape the icon key, human title, and subtitle here so
    the widget is a pure presenter.
    """
    ui_icon, ui_title, ui_subtitle = _ui_fields_for(row)
    return {
        'id': row.id,
        'type': row.transaction_type,
        'amount': str(row.amount),
        'balance_after': str(row.balance_after),
        'timestamp': row.timestamp.isoformat(),
        'memo': row.memo,
        'ui_icon': ui_icon,
        'ui_title': ui_title,
        'ui_subtitle': ui_subtitle,
        'ui_amount_color': 'credit' if row.amount >= 0 else 'debit',
    }


def _ui_fields_for(row: WalletTransaction) -> tuple[str, str, str]:
    """Map a row + its subtype to (icon_key, title, subtitle).

    Subtitles favour the most identifying datum available:
      * commission  → ``Booking #<id>``
      * topup       → gateway display name
      * withdrawal  → fulfilment external ref if present, else the
                      request id (less revealing than account digits).
      * refund      → penalty reason (admin-entered, short)
      * adjustment  → ``row.memo`` (admin-entered)
    """
    t = row.transaction_type

    if t == TransactionType.COMMISSION_DEBIT:
        commission = getattr(row, 'job_commission', None)
        booking_id = commission.booking_id if commission else None
        subtitle = f'Booking #{booking_id}' if booking_id else 'Commission'
        return 'commission', 'Platform commission', subtitle

    if t == TransactionType.TOPUP_CREDIT:
        topup = getattr(row, 'topup', None)
        gateway = (topup.gateway_name if topup else '').strip()
        subtitle = _GATEWAY_DISPLAY.get(gateway.lower(), gateway or 'Top-up')
        return 'topup', 'Wallet top-up', subtitle

    if t == TransactionType.WITHDRAWAL_DEBIT:
        fulfilment = getattr(row, 'withdrawal_fulfilment', None)
        external_ref = (fulfilment.withdrawal_request.admin_external_ref
                        if fulfilment else '').strip()
        if external_ref:
            subtitle = f'Ref: {external_ref}'
        elif fulfilment:
            subtitle = f'Request #{fulfilment.withdrawal_request_id}'
        else:
            subtitle = 'Withdrawal processed'
        return 'withdrawal', 'Withdrawal', subtitle

    if t == TransactionType.REFUND_DEBIT:
        refund = getattr(row, 'refund_deduction', None)
        subtitle = (refund.penalty_reason if refund else '') or 'Customer refund'
        return 'refund', 'Refund deducted', subtitle

    if t == TransactionType.ADJUSTMENT:
        subtitle = row.memo or 'Manual ledger correction'
        return 'adjustment', 'Admin adjustment', subtitle

    # Defensive default — a new TransactionType variant added without
    # also being mapped here renders generically rather than crashing.
    return 'adjustment', t.replace('_', ' ').title(), row.memo or ''


_GATEWAY_DISPLAY = {
    'jazzcash': 'via JazzCash',
    'mock': 'via Mock gateway',
}


# --- Cursor helpers ----------------------------------------------------------

def _encode_cursor(ts: datetime, row_id: int) -> str:
    """Pack (timestamp, id) into an opaque, base64-safe cursor string."""
    raw = f'{ts.isoformat()}|{row_id}'.encode('utf-8')
    return base64.urlsafe_b64encode(raw).rstrip(b'=').decode('ascii')


def _decode_cursor(cursor: str) -> tuple[datetime, int]:
    """Decode the cursor back into ``(timestamp, id)`` or raise.

    Padding is restored before decode because ``rstrip`` removed it for a
    cleaner-looking URL on the wire.
    """
    try:
        padded = cursor + '=' * (-len(cursor) % 4)
        raw = base64.urlsafe_b64decode(padded.encode('ascii')).decode('utf-8')
        ts_str, id_str = raw.split('|', 1)
        return datetime.fromisoformat(ts_str), int(id_str)
    except (binascii.Error, ValueError, UnicodeDecodeError) as exc:
        raise InvalidCursor(str(exc)) from exc

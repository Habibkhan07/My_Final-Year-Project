"""Read-side queries for the withdrawal flow.

Two selectors live here, both pure DB reads. Mutations go through
``wallet.services.withdrawal_service``.

* :func:`list_active_payout_accounts` — feeds the "Payout to" picker on
  the tech's withdrawal-submit screen. Returns only ``is_active=True``
  accounts, scoped to the passed-in technician.

* :func:`list_withdrawal_requests` — cursor-paginated history of the
  tech's own ``WithdrawalRequest`` rows (all statuses). The cursor
  encoding mirrors ``wallet_selectors.list_transactions`` so the frontend
  can reuse the same pagination plumbing.

SECURITY: every query in this module accepts ``technician`` as a parameter
and scopes the queryset to it. There is no implicit "current user" lookup
— the view's ``_require_technician`` gate is responsible for sourcing the
profile from ``request.user.tech_profile``.
"""
from __future__ import annotations

import base64
import binascii
from datetime import datetime
from typing import Optional, TypedDict

from django.db.models import Q
from django.utils.dateparse import parse_datetime

from technicians.models import TechnicianProfile
from wallet.models import (
    TechnicianBankAccount,
    TechnicianJazzCashAccount,
    WithdrawalRequest,
    WithdrawalStatus,
)


# ---------------------------------------------------------------------------
# Payout-account list
# ---------------------------------------------------------------------------

class PayoutAccountsPayload(TypedDict):
    bank_accounts: list[TechnicianBankAccount]
    jazzcash_accounts: list[TechnicianJazzCashAccount]


def list_active_payout_accounts(
    technician: TechnicianProfile,
) -> PayoutAccountsPayload:
    """Return the tech's currently-usable payout targets.

    Two parallel queries — one per account type — keep the result shape
    obvious to the caller. Active-only filter at the DB layer (not a
    Python-side filter) so soft-deleted accounts never enter the
    serializer.

    Order: newest-captured first. The most recently added account is
    the most likely "intended" target for a fresh withdrawal — surfacing
    it at the top of the picker cuts taps for the common case (tech
    just added a bank, immediately submits withdrawal).
    """
    bank_qs = list(
        TechnicianBankAccount.objects
        .filter(technician=technician, is_active=True)
        .order_by('-captured_at', '-id')
    )
    jazzcash_qs = list(
        TechnicianJazzCashAccount.objects
        .filter(technician=technician, is_active=True)
        .order_by('-captured_at', '-id')
    )
    return {
        'bank_accounts': bank_qs,
        'jazzcash_accounts': jazzcash_qs,
    }


# ---------------------------------------------------------------------------
# Withdrawal request history (cursor-paginated)
# ---------------------------------------------------------------------------

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 50


class InvalidCursor(ValueError):
    """Tampered or malformed ``cursor`` query param.

    Distinct from the ``wallet_selectors.InvalidCursor`` of the same name
    — the two cursor schemes have different keys (timestamp+id vs the
    same here), so we keep the exception types separate to avoid
    accidental cross-imports turning one into the other silently.
    """


def list_withdrawal_requests(
    technician: TechnicianProfile,
    *,
    cursor: Optional[str] = None,
    page_size: int = DEFAULT_PAGE_SIZE,
) -> dict:
    """Return one cursor-paginated page of the tech's withdrawal requests.

    Newest-first by ``requested_at``. Cursor encoding matches
    ``list_transactions``: base64 of ``"<iso_timestamp>|<id>"``. Stable
    under concurrent writes (new requests appear at the front, never
    inside the in-flight page window).

    ``select_related`` pulls the two payout-account FKs and the
    optional fulfilment in a single JOIN so the read serializer can
    render the masked account label without a second query per row.

    Returns the raw queryset rows (NOT dicts) — the view's serializer
    shapes them. Selectors stay narrow; UI shaping is a serializer
    concern.
    """
    page_size = max(1, min(int(page_size), MAX_PAGE_SIZE))

    qs = (
        WithdrawalRequest.objects
        .filter(technician=technician)
        .select_related(
            'payout_bank_account',
            'payout_jazzcash_account',
        )
        .order_by('-requested_at', '-id')
    )

    if cursor:
        cursor_ts, cursor_id = _decode_cursor(cursor)
        qs = qs.filter(
            Q(requested_at__lt=cursor_ts)
            | Q(requested_at=cursor_ts, id__lt=cursor_id)
        )

    # Fetch one extra row to detect whether another page exists without
    # a COUNT(*) — same trick as list_transactions.
    rows = list(qs[: page_size + 1])
    has_next = len(rows) > page_size
    page = rows[:page_size]

    next_cursor = None
    if has_next:
        last = page[-1]
        next_cursor = _encode_cursor(last.requested_at, last.id)

    return {
        'results': page,
        'next_cursor': next_cursor,
    }


def get_in_flight_request(
    technician: TechnicianProfile,
) -> Optional[WithdrawalRequest]:
    """Return the tech's open in-flight withdrawal, if any.

    "In-flight" = ``PENDING_REVIEW`` or ``APPROVED`` (admin has approved
    but not yet clicked Done; fulfilment row not written). Either state
    blocks a fresh submit.

    Called by the create service inside its ``transaction.atomic()``
    block, AFTER the caller has acquired a ``SELECT FOR UPDATE`` on the
    technician row. That tech-row lock is the only lock needed to
    serialize concurrent submits — a parallel submit blocks on the
    tech row, and when it proceeds it sees the row this transaction
    just inserted and raises ``DuplicatePendingWithdrawalError``.

    We deliberately do NOT take a row-lock on ``WithdrawalRequest``
    here: the admin "Approve & Process" path probably locks
    ``WithdrawalRequest`` first (reading the request) and then the
    tech row (writing the ledger), so locking the request here on the
    submit path would acquire the same two locks in the opposite
    order — Postgres would correctly detect the deadlock and abort
    one transaction, but the avoidable deadlock-abort is its own bug.
    Returns ``None`` when the tech has no in-flight request.
    """
    return (
        WithdrawalRequest.objects
        .filter(
            technician=technician,
            status__in=(
                WithdrawalStatus.PENDING_REVIEW,
                WithdrawalStatus.APPROVED,
            ),
        )
        .order_by('-requested_at', '-id')
        .first()
    )


# ---------------------------------------------------------------------------
# Cursor encode/decode helpers
# ---------------------------------------------------------------------------

def _encode_cursor(ts: datetime, row_id: int) -> str:
    """Pack (timestamp, id) into an opaque base64 token.

    Format: ``base64("<iso_timestamp>|<id>")``. The pipe separator is
    illegal inside an ISO-8601 string so the split is unambiguous.
    """
    raw = f'{ts.isoformat()}|{row_id}'
    return base64.urlsafe_b64encode(raw.encode('utf-8')).decode('ascii')


def _decode_cursor(token: str) -> tuple[datetime, int]:
    """Reverse :func:`_encode_cursor`. Raises :class:`InvalidCursor` on bad input.

    The view catches the exception and emits the standard 400 envelope.
    Any failure mode — wrong base64, missing pipe, unparseable timestamp,
    non-integer id — collapses to the same error so a client probing for
    parser oracle gets nothing useful.
    """
    try:
        raw = base64.urlsafe_b64decode(token.encode('ascii')).decode('utf-8')
    except (binascii.Error, UnicodeDecodeError, ValueError) as exc:
        raise InvalidCursor('Cursor could not be decoded.') from exc

    if '|' not in raw:
        raise InvalidCursor('Cursor is malformed.')

    ts_part, _, id_part = raw.rpartition('|')
    ts = parse_datetime(ts_part)
    if ts is None:
        raise InvalidCursor('Cursor timestamp is invalid.')

    try:
        row_id = int(id_part)
    except ValueError as exc:
        raise InvalidCursor('Cursor id is invalid.') from exc

    return ts, row_id

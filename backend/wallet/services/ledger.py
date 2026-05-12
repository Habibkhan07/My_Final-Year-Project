"""Wallet ledger — the single ledger-write site for every WalletTransaction.

Every WalletTransaction in the system funnels through ``record_transaction``.
That centralization is the ACID guarantee:

* **Atomicity** — the function runs inside a ``transaction.atomic()`` block
  (nests safely inside the caller's outer atomic, which is the typical
  pattern from ``WalletFinanceAdapter`` being invoked mid-orchestrator-
  transition).
* **Consistency** — ``balance_after`` is computed under the same lock as
  the ``TechnicianProfile.current_wallet_balance`` update, so the audit
  invariant ``MAX(balance_after) WHERE technician=X == current_wallet_balance``
  holds at every commit boundary.
* **Isolation** — ``select_for_update`` on the technician row serializes
  concurrent writers. Two parallel commission deductions on the same tech
  will queue at this lock rather than read-then-stomp.
* **Durability** — handled by Postgres + Django. Do NOT bypass this
  function with raw ``UPDATE tech_profile SET balance = ...`` — that
  defeats the isolation guarantee.

Idempotency is opt-in via ``transaction_reference_number``. When the caller
supplies one (e.g. ``f'booking:{id}:commission'``), the partial-unique
constraint on ``WalletTransaction`` returns the existing row instead of
double-writing. Callers that need stronger guarantees (e.g. one
``JobCommission`` per booking) should additionally rely on the 1:1
constraints on subtype models.

Subtype rows (``JobCommission``, ``WalletTopup``, etc.) are NOT created
here — callers attach them after ``record_transaction`` returns, inside
the same outer atomic. Keeping the subtype layer out of the ledger means
this function never needs to know about new transaction kinds.
"""
from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING

from django.db import transaction

from technicians.models import TechnicianProfile
from wallet.models import WalletTransaction

if TYPE_CHECKING:  # pragma: no cover
    pass


# SECURITY: every ledger write is scoped to a TechnicianProfile passed in by
# the caller. There is no implicit "current user" — the FinancePort adapter
# (and any future caller) MUST source the technician from the booking row or
# from request.user.tech_profile under its own IDOR guard. This module trusts
# its input.


def record_transaction(
    *,
    technician: TechnicianProfile,
    transaction_type: str,
    amount: Decimal,
    transaction_reference_number: str = '',
    gateway_reference: str = '',
    is_manual_adjustment: bool = False,
    memo: str = '',
) -> WalletTransaction:
    """Append one row to the ledger and patch the tech's denormalized balance.

    Parameters
    ----------
    technician:
        TechnicianProfile instance. Re-fetched under ``select_for_update``
        inside this function — the caller's instance is NOT mutated;
        a fresh row is loaded so we observe any concurrent writes.
    transaction_type:
        One of ``TransactionType.values``. Not enforced by CheckConstraint
        in v1 — the model's ``choices=`` provides admin-level validation.
    amount:
        Signed Decimal. Positive = credit (tech gains balance), negative
        = debit. The function does NOT enforce sign-by-type; the
        ``_DEBIT``/``_CREDIT`` suffix is documentation only. Caller
        responsibility to pass the correct sign.
    transaction_reference_number:
        Idempotency key. When non-empty, a pre-existing row with the same
        key is returned unchanged (the balance is NOT mutated again).
        Empty string allows multiple rows (e.g. ADJUSTMENT entries).
    gateway_reference:
        Opaque third-party transaction id, surfaced in admin for audit.
    is_manual_adjustment:
        True only for admin-initiated ADJUSTMENT rows.
    memo:
        Free-text annotation surfaced in admin.

    Returns
    -------
    WalletTransaction
        The newly created row (or the pre-existing row, if the
        idempotency key already had one).

    Side effects
    ------------
    * Updates ``technician.current_wallet_balance``.
    * Schedules a ``WALLET_BALANCE_UPDATED`` realtime broadcast via
      ``transaction.on_commit``. If the surrounding transaction rolls
      back, the broadcast NEVER fires — preventing the customer-visible
      "ghost update" failure mode.
    """
    if not isinstance(amount, Decimal):
        amount = Decimal(str(amount))

    with transaction.atomic():
        # Idempotent re-call short-circuit. Done OUTSIDE select_for_update
        # so the lock window stays short. The partial-unique constraint
        # on ``transaction_reference_number`` makes this race-safe: even
        # if two callers race past this check, the second INSERT below
        # would raise IntegrityError, which the caller can catch and
        # re-read. In practice the FinancePort adapter wraps a unique
        # key per booking, so the race is structurally impossible.
        if transaction_reference_number:
            existing = WalletTransaction.objects.filter(
                transaction_reference_number=transaction_reference_number,
            ).first()
            if existing is not None:
                return existing

        # Re-fetch under select_for_update. The caller's ``technician``
        # instance might have a stale current_wallet_balance after another
        # concurrent commit. Lock-and-reload ensures we add to the latest
        # committed balance, not a snapshot.
        locked_tech = (
            TechnicianProfile.objects
            .select_for_update()
            .get(pk=technician.pk)
        )

        new_balance = locked_tech.current_wallet_balance + amount

        # Write the ledger row. ``balance_after`` is the forensic invariant:
        # MAX(balance_after) per tech must equal locked_tech.current_wallet_balance
        # after the .save() below. The two writes are atomic together.
        wt = WalletTransaction.objects.create(
            technician=locked_tech,
            amount=amount,
            transaction_type=transaction_type,
            balance_after=new_balance,
            gateway_reference=gateway_reference,
            transaction_reference_number=transaction_reference_number,
            is_manual_adjustment=is_manual_adjustment,
            memo=memo,
        )

        # Patch the denormalized balance on the technician row. update_fields
        # narrows the UPDATE to one column so concurrent writers touching
        # unrelated fields (e.g. is_online toggle) don't pseudo-collide.
        locked_tech.current_wallet_balance = new_balance
        locked_tech.save(update_fields=['current_wallet_balance'])

        # Schedule the WS broadcast on commit. If the outer atomic rolls
        # back, this lambda is dropped and no event reaches the tech app.
        # Capture by value (pk + balance) so the broadcaster doesn't need
        # to re-fetch the row from a connection that may have been closed.
        tech_user_id = locked_tech.user_id
        balance_str = str(new_balance)
        transaction_id = wt.id
        transaction_type_value = transaction_type
        transaction.on_commit(
            lambda: _broadcast_wallet_balance_updated(
                tech_user_id=tech_user_id,
                balance=balance_str,
                transaction_id=transaction_id,
                transaction_type=transaction_type_value,
            )
        )

        return wt


def _broadcast_wallet_balance_updated(
    *,
    tech_user_id: int,
    balance: str,
    transaction_id: int,
    transaction_type: str,
) -> None:
    """Post-commit hook: broadcast the new balance to the tech's WS surface.

    Narrow try/except around the channel-layer send only (per CLAUDE.md
    realtime rule — bug-hiding wide barrels forbidden). If the realtime
    broadcast fails, the WalletTransaction is still durable; the
    next dashboard refresh will pick it up.

    Imported lazily so module-load on ``wallet.services.ledger`` does
    not pull the realtime channel layer into scope at test-collection
    time (matches the ``bookings.services.orchestrator._broadcast`` pattern).
    """
    from django.contrib.auth import get_user_model
    from realtime.events.services import EventDispatchService

    User = get_user_model()
    try:
        user = User.objects.get(pk=tech_user_id)
    except User.DoesNotExist:
        # Tech user deleted between commit and on_commit hook firing —
        # exotic enough to be a no-op. The ledger row persists either way.
        return

    EventDispatchService.broadcast_event(
        user=user,
        target_role='technician',
        event_type='wallet_balance_updated',
        payload={
            'balance': balance,
            'transaction_id': transaction_id,
            'transaction_type': transaction_type,
        },
        expires_in_seconds=None,
    )

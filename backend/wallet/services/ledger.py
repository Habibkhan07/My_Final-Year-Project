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
from wallet.exceptions import InsufficientFundsError
from wallet.models import TransactionType, WalletTransaction

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

    Raises
    ------
    InsufficientFundsError
        Only when ``transaction_type == WITHDRAWAL_DEBIT`` and the resulting
        balance would be negative. Per the per-type sufficiency policy
        (see ``wallet.exceptions`` and memory ``wallet-money-mechanics``),
        withdrawal is the ONLY debit the ledger refuses to record —
        commission/refund debits proceed even into negative balance, which
        is the lockout signal. Raised BEFORE any ledger row is written
        and BEFORE the ``select_for_update`` lock is released, so the
        attempt leaves no audit trace and no balance mutation.
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

        # Per-type sufficiency policy. Penalizing debits (COMMISSION, REFUND)
        # proceed regardless and may drive balance negative — that is the
        # lockout signal consumed at job-accept time. User-initiated
        # withdrawal is the ONLY debit gated here: a tech cannot borrow
        # money from the platform by withdrawing more than they currently
        # hold. ADJUSTMENT is admin discretion (no gate, either direction).
        # See memory ``wallet-money-mechanics`` for the authoritative table.
        #
        # Raising here, before the WalletTransaction.objects.create() call,
        # means the failed attempt produces NO ledger row and NO balance
        # mutation — the outer ``with transaction.atomic()`` block rolls
        # back cleanly. Idempotency replay (above) takes precedence over
        # this guard, which is correct: an already-recorded withdrawal
        # was sufficient at write time and is the ledger's source of truth.
        if (
            transaction_type == TransactionType.WITHDRAWAL_DEBIT
            and new_balance < Decimal('0')
        ):
            raise InsufficientFundsError(
                # ``amount`` arrives as a negative Decimal for debits; the
                # absolute value is what the tech requested. ``int()``
                # truncates the (model-allowed but practically never used)
                # paisa fraction — conservative under-reporting for the
                # "available" side, exact for the "requested" side.
                requested_pkr=int(-amount),
                available_pkr=int(locked_tech.current_wallet_balance),
            )

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
        # narrows the UPDATE to the columns we actually mutated so concurrent
        # writers touching unrelated fields don't pseudo-collide.
        locked_tech.current_wallet_balance = new_balance
        update_fields = ['current_wallet_balance']

        # Auto-offline gate. When this ledger write drives the balance into
        # negative territory (and the tech is currently online), the same
        # atomic also forces ``is_online = False``. The tech is structurally
        # locked out from accepting dispatches (see ``accept_job_booking``
        # gate) AND visibly removed from the dispatch pool. The recovery
        # loop is "tech sees forced-offline, taps top-up, taps back online".
        #
        # Top-ups that clear lockout do NOT auto-flip back to True: coming
        # back online is intentionally an explicit tech action (memory
        # ``wallet-money-mechanics``). The condition ``locked_tech.is_online``
        # makes this branch idempotent — a subsequent commission write on
        # an already-locked-and-offline tech is a no-op for ``is_online``.
        #
        # Boundary: the lockout signal is ``balance < 0`` (strict). A write
        # that lands balance at exactly 0 (e.g. an exact-amount withdrawal
        # taken to zero, or admin adjustment) does NOT trigger auto-offline.
        # This matches the rule in ``wallet.selectors.lockout``.
        if new_balance < Decimal('0') and locked_tech.is_online:
            locked_tech.is_online = False
            update_fields.append('is_online')

        locked_tech.save(update_fields=update_fields)

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

"""Admin-side withdrawal fulfilment service.

The tech submits a ``WithdrawalRequest`` via Flutter (request-side, see
``withdrawal_service.py``). Money does NOT move at that point — only the
intent row exists. Admin then:

1. Transfers funds out-of-band (bank wire or JazzCash merchant app).
2. Opens Django Admin → Withdrawal requests → selects the row(s).
3. Runs the "Approve & process" action, pasting the external reference
   and any notes.

This module is the ledger-side completion of that flow. It runs inside a
single ``transaction.atomic() + select_for_update`` on both the request
row and the technician row so:

* A duplicate click cannot double-debit (idempotency via row lock + status
  guard).
* A concurrent commission/refund write cannot race past us.
* If the ledger raises (insufficient funds — defence in depth; submit-side
  already guarded), no fulfilment row is created and the request stays
  PENDING_REVIEW.

The reject path is the mirror — flips status to REJECTED, captures admin
notes, NO ledger movement (no money was held; the request was just an
intent).
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from wallet.exceptions import InsufficientFundsError
from wallet.models import (
    TransactionType,
    WalletTransaction,
    WithdrawalFulfilment,
    WithdrawalRequest,
    WithdrawalStatus,
)
from wallet.services.ledger import record_transaction


class WithdrawalNotPending(Exception):
    """Raised when fulfilment is attempted on a non-PENDING_REVIEW row."""

    def __init__(self, current_status: str):
        super().__init__(f'Withdrawal is in status {current_status}, not pending review.')
        self.current_status = current_status


@dataclass(frozen=True)
class FulfilmentResult:
    request: WithdrawalRequest
    fulfilment: WithdrawalFulfilment
    wallet_transaction: WalletTransaction


def approve_and_process_withdrawal(
    *,
    request_id: int,
    admin_user,
    admin_external_ref: str,
    admin_notes: str = '',
) -> FulfilmentResult:
    """Mark a PENDING_REVIEW withdrawal as PROCESSED + write the ledger debit.

    Parameters
    ----------
    request_id:
        Primary key of the ``WithdrawalRequest`` to fulfil. Re-fetched
        under ``select_for_update`` inside this function.
    admin_user:
        The staff user clicking the button — stamped onto ``reviewed_by``
        for audit.
    admin_external_ref:
        Required. The bank wire reference / JazzCash merchant txn id /
        any other out-of-band identifier so the row can be reconciled
        against bank statements later. Surfaces back to the tech on the
        withdrawal-history endpoint (see WALLET_API.md).
    admin_notes:
        Optional internal annotation. Not exposed to the tech.

    Raises
    ------
    WithdrawalNotPending
        Status is not PENDING_REVIEW — already processed, already
        rejected, or in an unexpected state. The transaction rolls back
        without any writes.
    InsufficientFundsError
        Defence-in-depth: the submit-side already checked, but the tech's
        balance could have moved negative between submit and now (e.g.
        commission write). The ledger refuses the debit and no fulfilment
        row is created.
    """
    if not admin_external_ref.strip():
        raise ValueError('admin_external_ref is required.')

    with transaction.atomic():
        request_row = (
            WithdrawalRequest.objects
            .select_for_update()
            .select_related('technician')
            .get(pk=request_id)
        )

        if request_row.status != WithdrawalStatus.PENDING_REVIEW:
            raise WithdrawalNotPending(current_status=request_row.status)

        # Ledger row — negative amount because this is an outflow from the
        # tech's wallet. ``record_transaction`` performs its own
        # ``select_for_update`` on the tech row inside our outer atomic
        # (nested-atomic safe). The reference number scopes idempotency to
        # this specific request — re-running the action is a no-op at the
        # ledger layer, and the status guard above is the layer above that.
        wt = record_transaction(
            technician=request_row.technician,
            transaction_type=TransactionType.WITHDRAWAL_DEBIT,
            amount=-Decimal(request_row.amount),
            transaction_reference_number=f'withdrawal:{request_row.pk}',
            gateway_reference=admin_external_ref.strip()[:128],
            memo=admin_notes.strip()[:255] if admin_notes else '',
        )

        fulfilment = WithdrawalFulfilment.objects.create(
            withdrawal_request=request_row,
            wallet_transaction=wt,
            processing_note=admin_notes.strip(),
        )

        # Flip the request to PROCESSED + capture the audit trail.
        request_row.status = WithdrawalStatus.PROCESSED
        request_row.admin_external_ref = admin_external_ref.strip()[:128]
        request_row.admin_notes = admin_notes.strip()
        request_row.reviewed_by = admin_user
        request_row.reviewed_at = timezone.now()
        request_row.save(update_fields=[
            'status',
            'admin_external_ref',
            'admin_notes',
            'reviewed_by',
            'reviewed_at',
        ])

    return FulfilmentResult(
        request=request_row,
        fulfilment=fulfilment,
        wallet_transaction=wt,
    )


def reject_withdrawal(
    *,
    request_id: int,
    admin_user,
    admin_notes: str,
) -> WithdrawalRequest:
    """Refuse a PENDING_REVIEW request without any ledger movement.

    No wallet transaction is written — the original submit did not move
    money. The tech is now free to submit a fresh request (the duplicate-
    pending guard releases as soon as this row leaves PENDING_REVIEW).
    """
    if not admin_notes.strip():
        raise ValueError('Rejection requires an admin note explaining why.')

    with transaction.atomic():
        request_row = (
            WithdrawalRequest.objects
            .select_for_update()
            .get(pk=request_id)
        )

        if request_row.status != WithdrawalStatus.PENDING_REVIEW:
            raise WithdrawalNotPending(current_status=request_row.status)

        request_row.status = WithdrawalStatus.REJECTED
        request_row.admin_notes = admin_notes.strip()
        request_row.reviewed_by = admin_user
        request_row.reviewed_at = timezone.now()
        request_row.save(update_fields=[
            'status',
            'admin_notes',
            'reviewed_by',
            'reviewed_at',
        ])

    return request_row

"""Withdrawal request creation service.

Tech submits a withdrawal request via Flutter; admin processes it
out-of-band via Django Admin (real bank wire / JazzCash merchant app)
and clicks "Done" to fire the ``WITHDRAWAL_DEBIT`` ledger row. This
module is the request-side half — it writes a ``WithdrawalRequest`` at
``PENDING_REVIEW`` and stops. NO ledger row, NO realtime broadcast, NO
Celery task. See ``project_withdrawal_lifecycle`` memory + the admin
action wiring in ``wallet/admin.py`` for the fulfilment side.

Defense-in-depth checks (in the order they fire):

  1. Technician account active — ``status='APPROVED'`` AND ``is_active=True``.
     A tech who is PENDING / REJECTED, or who was approved but later
     deactivated by an admin (suspension / soft-ban), cannot withdraw.
  2. Negative-balance lockout — same gate accept-job uses; if the tech
     is locked out, no new withdrawal is created.
  3. Existing in-flight request — refuse if a PENDING_REVIEW (or
     APPROVED-but-not-yet-fulfilled) row exists. One in-flight at a time.
  4. Sufficiency — amount must be ≤ current balance. Same exception
     class the ledger raises at fulfilment time, so the frontend sees one
     envelope shape regardless of which gate fires.
  5. Payout-account ownership — the picked account must belong to the
     requesting tech and be ``is_active=True``. IDOR-scoped resolution.

All five run inside a single ``transaction.atomic() + select_for_update()``
block on the ``TechnicianProfile`` row. The row lock means a concurrent
commission write (which could push the balance below zero) and a
concurrent submit (which could duplicate-pending) both serialize at this
lock instead of racing.
"""
from __future__ import annotations

from decimal import Decimal, ROUND_CEILING, ROUND_FLOOR
from typing import Optional

from django.db import transaction
from rest_framework.exceptions import ValidationError

from technicians.models import TechnicianProfile
from wallet.exceptions import (
    DuplicatePendingWithdrawalError,
    InactiveTechnicianError,
    InsufficientFundsError,
    WalletLockoutError,
)
from wallet.models import (
    TechnicianBankAccount,
    TechnicianJazzCashAccount,
    WithdrawalRequest,
    WithdrawalStatus,
)
from wallet.selectors.lockout import is_wallet_locked, lockout_status
from wallet.selectors.withdrawal_selectors import get_in_flight_request


# SECURITY: ``technician`` is supplied by the caller (the view's
# _require_technician gate sources it from request.user.tech_profile).
# Payout-account ids in the request body are NEVER trusted blindly —
# resolution is scoped to ``technician=...`` so a malicious client cannot
# pay out to another tech's saved account. The XOR rule is enforced both
# in the caller's serializer AND below as a defensive assert.


# Whole-rupee window. Decimals are accepted (model is DecimalField) but
# bounded — Rs.5,000 max keeps demo-time typo bugs ("5,00,000" with a
# stray separator) from authorizing a Rs.500k payout. The lower bound of
# Rs.1 prevents zero/negative which a misconfigured serializer might let
# slip; the serializer's own min_value is the first line of defense.
MIN_WITHDRAWAL_RUPEES: Decimal = Decimal('1.00')
MAX_WITHDRAWAL_RUPEES: Decimal = Decimal('5000.00')


def create_withdrawal_request(
    *,
    technician: TechnicianProfile,
    amount: Decimal,
    payout_bank_account_id: Optional[int],
    payout_jazzcash_account_id: Optional[int],
) -> WithdrawalRequest:
    """Create a ``WithdrawalRequest`` at ``PENDING_REVIEW`` after all gates pass.

    Parameters
    ----------
    technician:
        The requesting tech. Re-fetched under ``select_for_update`` inside
        this function — the caller's instance is NOT mutated; a fresh row
        is loaded so we observe any concurrent commission writes.
    amount:
        Signed Decimal (positive). Must be in
        ``[MIN_WITHDRAWAL_RUPEES, MAX_WITHDRAWAL_RUPEES]`` (the serializer
        enforces this; the service re-asserts as defense in depth).
    payout_bank_account_id / payout_jazzcash_account_id:
        Exactly one must be a positive int; the other must be None. The
        XOR rule is enforced at three layers: serializer ``validate()``,
        the service-level XOR check below (defense in depth in case a
        non-serializer caller appears), and the DB ``CheckConstraint``.

    Returns
    -------
    WithdrawalRequest
        The freshly created row at ``status=PENDING_REVIEW``.

    Raises
    ------
    InactiveTechnicianError
        Tech's ``status`` is not ``APPROVED``.
    WalletLockoutError
        Tech's current balance is < 0.
    DuplicatePendingWithdrawalError
        Tech already has an open ``PENDING_REVIEW`` / ``APPROVED`` request.
    InsufficientFundsError
        Requested ``amount`` > tech's current balance.
    ValidationError
        Payout-account id does not resolve to an active account owned by
        this tech (covers IDOR attempts, soft-deleted accounts, and
        nonexistent ids — same error message so no information disclosure).
        Also raised if the amount is outside the service-level bounds
        (caller's serializer should catch this first; this is defense in
        depth).
    """
    # --- Sign / bounds defense-in-depth (serializer should catch first) ---
    if amount <= 0:
        raise ValidationError({'amount': ['Amount must be positive.']})
    if amount < MIN_WITHDRAWAL_RUPEES:
        raise ValidationError({
            'amount': [f'Amount must be at least Rs. {MIN_WITHDRAWAL_RUPEES}.'],
        })
    if amount > MAX_WITHDRAWAL_RUPEES:
        raise ValidationError({
            'amount': [f'Amount must not exceed Rs. {MAX_WITHDRAWAL_RUPEES}.'],
        })

    # --- XOR defense-in-depth (serializer catches first; DB catches last) -
    bank_id = payout_bank_account_id
    jazz_id = payout_jazzcash_account_id
    if (bank_id is None and jazz_id is None) or (bank_id is not None and jazz_id is not None):
        raise ValidationError({
            'payout': ['Exactly one of payout_bank_account_id or payout_jazzcash_account_id is required.'],
        })

    with transaction.atomic():
        # --- Re-fetch tech under row lock --------------------------------
        # The caller's TechnicianProfile instance was read at view-time and
        # may be seconds stale by now. Under select_for_update the row is
        # locked for the rest of this transaction, serializing this submit
        # against any concurrent commission / refund write that could
        # change the balance or the status.
        locked_tech = (
            TechnicianProfile.objects
            .select_for_update()
            .get(pk=technician.pk)
        )

        # --- 1. Account-active gate -------------------------------------
        # Two independent fields gate this: ``status`` (PENDING / APPROVED
        # / REJECTED, lifecycle of the application) and ``is_active``
        # (admin soft-ban / suspension flag, independent of approval
        # lifecycle). EITHER failing → no withdrawal. The exception
        # carries the ``status`` value verbatim when the status gate
        # trips, or the synthetic ``"DEACTIVATED"`` when the is_active
        # gate trips on an otherwise-APPROVED tech — distinct enough for
        # the UI to render the right message without leaking the second
        # field's semantics on the wire.
        if locked_tech.status != 'APPROVED':
            raise InactiveTechnicianError(status=locked_tech.status)
        if not locked_tech.is_active:
            raise InactiveTechnicianError(status='DEACTIVATED')

        # --- 2. Negative-balance lockout --------------------------------
        # Uses the single source of truth in wallet.selectors.lockout.
        # If the tech is in debt, no new outflow allowed.
        if is_wallet_locked(locked_tech):
            status_payload = lockout_status(locked_tech)
            raise WalletLockoutError(
                balance_pkr=status_payload['balance_pkr'],
                owed_pkr=status_payload['owed_pkr'],
            )

        # --- 3. Duplicate in-flight check -------------------------------
        # PENDING_REVIEW or APPROVED-but-not-yet-fulfilled both count as
        # "one in flight". The tech-row lock above is what serializes
        # parallel submits: Tx B waits at the tech-row SELECT FOR
        # UPDATE, then on its turn sees the row Tx A just inserted and
        # raises here. We deliberately do NOT lock the WithdrawalRequest
        # row from this path — see ``get_in_flight_request`` docstring
        # for the lock-order rationale.
        existing = get_in_flight_request(locked_tech)
        if existing is not None:
            raise DuplicatePendingWithdrawalError(pending_request_id=existing.pk)

        # --- 4. Sufficiency ---------------------------------------------
        # Same exception class the ledger raises at fulfilment time. The
        # PKR cast here is asymmetric on purpose: requested rounds UP
        # (ceiling) and available rounds DOWN (floor). With
        # request=100.99 and balance=100.50 (gate trips on the exact
        # Decimal compare below), naive int() would render BOTH as 100
        # and produce the misleading message "Cannot withdraw Rs. 100.
        # Available balance: Rs. 100." The asymmetric rounding renders
        # "Cannot withdraw Rs. 101. Available balance: Rs. 100." —
        # always shows the pessimistic-for-tech number on each side, so
        # the displayed gap is never zero when the underlying gate
        # trips. Mirrors the rounding policy in
        # ``wallet.selectors.lockout.lockout_status``.
        current_balance = locked_tech.current_wallet_balance
        if amount > current_balance:
            requested_int = int(amount.quantize(Decimal('1'), rounding=ROUND_CEILING))
            available_int = int(current_balance.quantize(Decimal('1'), rounding=ROUND_FLOOR))
            raise InsufficientFundsError(
                requested_pkr=requested_int,
                available_pkr=available_int,
            )

        # --- 5. Payout-account resolution (IDOR-scoped) -----------------
        # Both queries filter by ``technician=locked_tech`` so a payload
        # carrying another tech's account id resolves to None and emits
        # the same generic error as "doesn't exist" — no info disclosure.
        # ``is_active=True`` keeps soft-deleted accounts unusable.
        bank_account = None
        jazz_account = None
        if bank_id is not None:
            bank_account = (
                TechnicianBankAccount.objects
                .filter(pk=bank_id, technician=locked_tech, is_active=True)
                .first()
            )
            if bank_account is None:
                raise ValidationError({
                    'payout_bank_account_id': ['Invalid payout account.'],
                })
        else:
            jazz_account = (
                TechnicianJazzCashAccount.objects
                .filter(pk=jazz_id, technician=locked_tech, is_active=True)
                .first()
            )
            if jazz_account is None:
                raise ValidationError({
                    'payout_jazzcash_account_id': ['Invalid payout account.'],
                })

        # --- All gates passed — write the request -----------------------
        # PROTECT FKs on payout accounts mean a tech cannot delete an
        # account that has live withdrawal requests pointing at it; soft-
        # delete (is_active=False) is the supported tear-down path.
        request_row = WithdrawalRequest.objects.create(
            technician=locked_tech,
            amount=amount,
            status=WithdrawalStatus.PENDING_REVIEW,
            payout_bank_account=bank_account,
            payout_jazzcash_account=jazz_account,
        )

    return request_row

"""Tests for ``wallet.services.withdrawal_service.create_withdrawal_request``.

Covers the full five-gate matrix:

1. Tech active gate — ``status='APPROVED' AND is_active=True``.
2. Negative-balance lockout gate.
3. Duplicate in-flight gate (PENDING_REVIEW or APPROVED blocks).
4. Sufficiency gate (amount > balance).
5. Payout-account ownership gate (IDOR / soft-deleted / unknown id).

Plus the happy paths (bank and JazzCash), the amount-bounds defense-in-
depth at the service layer (serializer is the first line of defense; we
re-assert in case a future internal caller skips it), and the XOR
defense-in-depth.

No ledger writes occur on the submit path — every test asserts the
``WalletTransaction`` table is untouched by submission.
"""
from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework.exceptions import ValidationError

from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.wallet import (
    TechnicianBankAccountFactory,
    TechnicianJazzCashAccountFactory,
    WithdrawalRequestFactory,
)
from wallet.exceptions import (
    DuplicatePendingWithdrawalError,
    InactiveTechnicianError,
    InsufficientFundsError,
    WalletLockoutError,
)
from wallet.models import WalletTransaction, WithdrawalRequest, WithdrawalStatus
from wallet.services.withdrawal_service import (
    MAX_WITHDRAWAL_RUPEES,
    MIN_WITHDRAWAL_RUPEES,
    create_withdrawal_request,
)


def _approved_tech(*, balance=Decimal('1000.00')):
    """Default tech for happy-path tests: APPROVED + active + Rs.1000 balance."""
    return TechnicianProfileFactory(
        status='APPROVED',
        is_active=True,
        current_wallet_balance=balance,
    )


# ──────────────────────────────────────────────────────────────────────
# Happy paths
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestHappyPath:
    def test_creates_pending_request_via_bank(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)

        request = create_withdrawal_request(
            technician=tech,
            amount=Decimal('500.00'),
            payout_bank_account_id=bank.pk,
            payout_jazzcash_account_id=None,
        )

        assert request.pk is not None
        assert request.status == WithdrawalStatus.PENDING_REVIEW
        assert request.amount == Decimal('500.00')
        assert request.payout_bank_account_id == bank.pk
        assert request.payout_jazzcash_account_id is None

    def test_creates_pending_request_via_jazzcash(self):
        tech = _approved_tech()
        jazz = TechnicianJazzCashAccountFactory(technician=tech)

        request = create_withdrawal_request(
            technician=tech,
            amount=Decimal('500.00'),
            payout_bank_account_id=None,
            payout_jazzcash_account_id=jazz.pk,
        )

        assert request.status == WithdrawalStatus.PENDING_REVIEW
        assert request.payout_jazzcash_account_id == jazz.pk
        assert request.payout_bank_account_id is None

    def test_no_ledger_row_written_on_submit(self):
        """Critical: submission writes NO WalletTransaction. Ledger only fires at admin fulfilment."""
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)

        create_withdrawal_request(
            technician=tech,
            amount=Decimal('500.00'),
            payout_bank_account_id=bank.pk,
            payout_jazzcash_account_id=None,
        )

        assert WalletTransaction.objects.filter(technician=tech).count() == 0

    def test_balance_not_changed_on_submit(self):
        tech = _approved_tech(balance=Decimal('1000.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        create_withdrawal_request(
            technician=tech,
            amount=Decimal('500.00'),
            payout_bank_account_id=bank.pk,
            payout_jazzcash_account_id=None,
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('1000.00')

    def test_withdraw_exact_balance_allowed(self):
        """amount == balance passes the strict ``>`` sufficiency check."""
        tech = _approved_tech(balance=Decimal('500.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        request = create_withdrawal_request(
            technician=tech,
            amount=Decimal('500.00'),
            payout_bank_account_id=bank.pk,
            payout_jazzcash_account_id=None,
        )

        assert request.amount == Decimal('500.00')


# ──────────────────────────────────────────────────────────────────────
# Gate 1: Tech active gate
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestActiveGate:
    def test_pending_status_raises(self):
        tech = TechnicianProfileFactory(
            status='PENDING', current_wallet_balance=Decimal('1000.00'),
        )
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(InactiveTechnicianError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert exc.value.errors['status'] == ['PENDING']

    def test_rejected_status_raises(self):
        tech = TechnicianProfileFactory(
            status='REJECTED', current_wallet_balance=Decimal('1000.00'),
        )
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(InactiveTechnicianError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert exc.value.errors['status'] == ['REJECTED']

    def test_deactivated_approved_tech_raises(self):
        """Approved tech with is_active=False (banned/suspended) cannot withdraw."""
        tech = TechnicianProfileFactory(
            status='APPROVED',
            is_active=False,
            current_wallet_balance=Decimal('1000.00'),
        )
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(InactiveTechnicianError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert exc.value.errors['status'] == ['DEACTIVATED']

    def test_no_withdrawal_row_written_when_gate_trips(self):
        tech = TechnicianProfileFactory(
            status='PENDING', current_wallet_balance=Decimal('1000.00'),
        )
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(InactiveTechnicianError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )

        assert WithdrawalRequest.objects.filter(technician=tech).count() == 0


# ──────────────────────────────────────────────────────────────────────
# Gate 2: Negative-balance lockout
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestLockoutGate:
    def test_negative_balance_raises_wallet_lockout(self):
        tech = _approved_tech(balance=Decimal('-50.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(WalletLockoutError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('10.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert exc.value.errors['balance_pkr'] == ['-50']
        assert exc.value.errors['owed_pkr'] == ['50']

    def test_one_paisa_negative_locks(self):
        """Strict ``< 0`` semantics — one paisa under is enough."""
        tech = _approved_tech(balance=Decimal('-0.01'))
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(WalletLockoutError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('1.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )

    def test_zero_balance_is_not_locked(self):
        """Zero is allowed. Tech can't actually withdraw from zero (sufficiency
        gate will catch it), but the lockout gate alone does not trip."""
        tech = _approved_tech(balance=Decimal('0.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(InsufficientFundsError):  # sufficiency, not lockout
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('1.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )


# ──────────────────────────────────────────────────────────────────────
# Gate 3: Duplicate in-flight
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestDuplicateInFlight:
    def test_pending_request_blocks_new_submit(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        existing = WithdrawalRequestFactory(
            technician=tech,
            status=WithdrawalStatus.PENDING_REVIEW,
            payout_bank_account=bank,
        )

        with pytest.raises(DuplicatePendingWithdrawalError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert exc.value.errors['pending_request_id'] == [str(existing.pk)]

    def test_approved_request_blocks_new_submit(self):
        """APPROVED-but-not-fulfilled also blocks (admin is mid-processing)."""
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        WithdrawalRequestFactory(
            technician=tech,
            status=WithdrawalStatus.APPROVED,
            payout_bank_account=bank,
        )

        with pytest.raises(DuplicatePendingWithdrawalError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )

    def test_rejected_request_does_not_block(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        WithdrawalRequestFactory(
            technician=tech,
            status=WithdrawalStatus.REJECTED,
            payout_bank_account=bank,
        )

        request = create_withdrawal_request(
            technician=tech,
            amount=Decimal('100.00'),
            payout_bank_account_id=bank.pk,
            payout_jazzcash_account_id=None,
        )

        assert request.status == WithdrawalStatus.PENDING_REVIEW

    def test_processed_request_does_not_block(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        WithdrawalRequestFactory(
            technician=tech,
            status=WithdrawalStatus.PROCESSED,
            payout_bank_account=bank,
        )

        request = create_withdrawal_request(
            technician=tech,
            amount=Decimal('100.00'),
            payout_bank_account_id=bank.pk,
            payout_jazzcash_account_id=None,
        )

        assert request.status == WithdrawalStatus.PENDING_REVIEW

    def test_another_techs_pending_does_not_block(self):
        me = _approved_tech()
        my_bank = TechnicianBankAccountFactory(technician=me)
        other = _approved_tech()
        other_bank = TechnicianBankAccountFactory(technician=other)
        WithdrawalRequestFactory(
            technician=other,
            status=WithdrawalStatus.PENDING_REVIEW,
            payout_bank_account=other_bank,
        )

        request = create_withdrawal_request(
            technician=me,
            amount=Decimal('100.00'),
            payout_bank_account_id=my_bank.pk,
            payout_jazzcash_account_id=None,
        )

        assert request.status == WithdrawalStatus.PENDING_REVIEW


# ──────────────────────────────────────────────────────────────────────
# Gate 4: Sufficiency + rounding semantics
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestSufficiencyGate:
    def test_amount_greater_than_balance_raises(self):
        tech = _approved_tech(balance=Decimal('100.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(InsufficientFundsError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('101.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert exc.value.errors['requested_pkr'] == ['101']
        assert exc.value.errors['available_pkr'] == ['100']

    def test_paisa_fraction_rounds_pessimistically_for_tech(self):
        """The bug-fix scenario: req=100.99, bal=100.50.

        Naive int() would render both as 100 → message looks like
        balance is sufficient. The asymmetric rounding renders
        requested=101 / available=100 instead — gap never collapses to
        zero when the gate trips.
        """
        tech = _approved_tech(balance=Decimal('100.50'))
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(InsufficientFundsError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.99'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert exc.value.errors['requested_pkr'] == ['101']
        assert exc.value.errors['available_pkr'] == ['100']

    def test_no_withdrawal_row_written_when_insufficient(self):
        tech = _approved_tech(balance=Decimal('50.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(InsufficientFundsError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )

        assert WithdrawalRequest.objects.filter(technician=tech).count() == 0


# ──────────────────────────────────────────────────────────────────────
# Gate 5: Payout-account resolution / IDOR
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestPayoutAccountGate:
    def test_other_techs_bank_account_id_raises_generic_validation_error(self):
        """IDOR attempt: tech submits with another tech's bank id."""
        me = _approved_tech()
        other = _approved_tech()
        other_bank = TechnicianBankAccountFactory(technician=other)

        with pytest.raises(ValidationError) as exc:
            create_withdrawal_request(
                technician=me,
                amount=Decimal('100.00'),
                payout_bank_account_id=other_bank.pk,
                payout_jazzcash_account_id=None,
            )
        # Same error key as "doesn't exist" — no information disclosure.
        assert 'payout_bank_account_id' in exc.value.detail

    def test_other_techs_jazzcash_id_raises(self):
        me = _approved_tech()
        other = _approved_tech()
        other_jazz = TechnicianJazzCashAccountFactory(technician=other)

        with pytest.raises(ValidationError) as exc:
            create_withdrawal_request(
                technician=me,
                amount=Decimal('100.00'),
                payout_bank_account_id=None,
                payout_jazzcash_account_id=other_jazz.pk,
            )
        assert 'payout_jazzcash_account_id' in exc.value.detail

    def test_nonexistent_bank_id_raises(self):
        tech = _approved_tech()

        with pytest.raises(ValidationError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=99_999,
                payout_jazzcash_account_id=None,
            )

    def test_nonexistent_jazzcash_id_raises(self):
        tech = _approved_tech()

        with pytest.raises(ValidationError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=None,
                payout_jazzcash_account_id=99_999,
            )

    def test_inactive_bank_account_raises(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech, is_active=False)

        with pytest.raises(ValidationError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )

    def test_inactive_jazzcash_account_raises(self):
        tech = _approved_tech()
        jazz = TechnicianJazzCashAccountFactory(technician=tech, is_active=False)

        with pytest.raises(ValidationError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=None,
                payout_jazzcash_account_id=jazz.pk,
            )


# ──────────────────────────────────────────────────────────────────────
# XOR defense-in-depth at service layer
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestXorDefenseInDepth:
    def test_neither_account_supplied_raises(self):
        tech = _approved_tech()

        with pytest.raises(ValidationError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=None,
                payout_jazzcash_account_id=None,
            )
        assert 'payout' in exc.value.detail

    def test_both_accounts_supplied_raises(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        jazz = TechnicianJazzCashAccountFactory(technician=tech)

        with pytest.raises(ValidationError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('100.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=jazz.pk,
            )
        assert 'payout' in exc.value.detail


# ──────────────────────────────────────────────────────────────────────
# Amount bounds defense-in-depth
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestAmountBoundsDefenseInDepth:
    def test_zero_amount_raises(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(ValidationError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('0.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert 'amount' in exc.value.detail

    def test_negative_amount_raises(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(ValidationError) as exc:
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('-10.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )
        assert 'amount' in exc.value.detail

    def test_below_minimum_raises(self):
        """Below MIN_WITHDRAWAL_RUPEES (Rs. 1.00) — service-level guard."""
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(ValidationError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('0.50'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )

    def test_above_maximum_raises(self):
        """Above MAX_WITHDRAWAL_RUPEES (Rs. 5,000) — service-level guard
        against typo bugs sneaking past a misconfigured serializer."""
        tech = _approved_tech(balance=Decimal('1000000.00'))  # plenty of balance
        bank = TechnicianBankAccountFactory(technician=tech)

        with pytest.raises(ValidationError):
            create_withdrawal_request(
                technician=tech,
                amount=Decimal('5001.00'),
                payout_bank_account_id=bank.pk,
                payout_jazzcash_account_id=None,
            )

    def test_minimum_amount_accepted(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)

        request = create_withdrawal_request(
            technician=tech,
            amount=MIN_WITHDRAWAL_RUPEES,
            payout_bank_account_id=bank.pk,
            payout_jazzcash_account_id=None,
        )

        assert request.amount == MIN_WITHDRAWAL_RUPEES

    def test_maximum_amount_accepted(self):
        tech = _approved_tech(balance=Decimal('10000.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        request = create_withdrawal_request(
            technician=tech,
            amount=MAX_WITHDRAWAL_RUPEES,
            payout_bank_account_id=bank.pk,
            payout_jazzcash_account_id=None,
        )

        assert request.amount == MAX_WITHDRAWAL_RUPEES

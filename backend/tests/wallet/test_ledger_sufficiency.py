"""Per-type sufficiency policy at the ledger boundary.

Pins the rule that ``record_transaction`` enforces inside its
``transaction.atomic()`` block:

* ``WITHDRAWAL_DEBIT`` raises ``InsufficientFundsError`` if and only if
  the resulting balance would be negative. No ledger row is written and
  no balance mutation persists.
* ``COMMISSION_DEBIT`` and ``REFUND_DEBIT`` are allowed to drive balance
  below zero — that's the lockout signal consumed by tech-action services.
* ``ADJUSTMENT`` is admin discretion (either direction, no gate).
* ``TOPUP_CREDIT`` is always permitted (it can only increase balance).

Authoritative reference: memory ``wallet-money-mechanics``.
"""
from __future__ import annotations

from decimal import Decimal

import pytest

from tests.factories.technicians import TechnicianProfileFactory
from wallet.exceptions import InsufficientFundsError
from wallet.models import TransactionType, WalletTransaction
from wallet.services.ledger import record_transaction


# ──────────────────────────────────────────────────────────────────────
# WITHDRAWAL_DEBIT — the only debit type the ledger refuses to overdraw.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestWithdrawalSufficiency:
    def test_withdrawal_within_balance_succeeds(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('1000.00'))

        wt = record_transaction(
            technician=tech,
            transaction_type=TransactionType.WITHDRAWAL_DEBIT,
            amount=Decimal('-300.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('700.00')
        assert wt.amount == Decimal('-300.00')
        assert wt.balance_after == Decimal('700.00')

    def test_withdrawal_exact_balance_succeeds_at_zero_boundary(self):
        """Withdrawing exactly the balance is allowed — final balance == 0
        is NOT lockout (the rule is strictly ``balance < 0``)."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('500.00'))

        wt = record_transaction(
            technician=tech,
            transaction_type=TransactionType.WITHDRAWAL_DEBIT,
            amount=Decimal('-500.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('0.00')
        assert wt.balance_after == Decimal('0.00')

    def test_withdrawal_one_paisa_over_raises(self):
        """The boundary is strict — any negative result must reject."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('500.00'))

        with pytest.raises(InsufficientFundsError) as excinfo:
            record_transaction(
                technician=tech,
                transaction_type=TransactionType.WITHDRAWAL_DEBIT,
                amount=Decimal('-500.01'),
            )

        # Exception carries the request context for the envelope.
        err = excinfo.value
        assert err.code == "insufficient_funds"
        assert err.status_code == 400
        assert err.errors == {
            "requested_pkr": ["500"],   # int(500.01) → 500
            "available_pkr": ["500"],
        }
        # Balance and ledger MUST be untouched.
        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('500.00')
        assert not WalletTransaction.objects.filter(technician=tech).exists()

    def test_withdrawal_overdraw_raises_and_writes_no_row(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('300.00'))

        with pytest.raises(InsufficientFundsError) as excinfo:
            record_transaction(
                technician=tech,
                transaction_type=TransactionType.WITHDRAWAL_DEBIT,
                amount=Decimal('-500.00'),
            )

        err = excinfo.value
        assert err.errors == {
            "requested_pkr": ["500"],
            "available_pkr": ["300"],
        }
        assert "Rs. 500" in err.message
        assert "Rs. 300" in err.message

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('300.00')
        assert not WalletTransaction.objects.filter(technician=tech).exists()

    def test_withdrawal_on_zero_balance_raises(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))

        with pytest.raises(InsufficientFundsError):
            record_transaction(
                technician=tech,
                transaction_type=TransactionType.WITHDRAWAL_DEBIT,
                amount=Decimal('-1.00'),
            )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('0.00')

    def test_withdrawal_on_already_locked_wallet_raises(self):
        """A tech currently in lockout cannot make their balance worse
        with a withdrawal — the guard fires regardless of starting balance."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-100.00'))

        with pytest.raises(InsufficientFundsError) as excinfo:
            record_transaction(
                technician=tech,
                transaction_type=TransactionType.WITHDRAWAL_DEBIT,
                amount=Decimal('-50.00'),
            )

        # available_pkr is the negative starting balance — admin/UI can
        # detect the lockout case by seeing a negative available value.
        assert excinfo.value.errors == {
            "requested_pkr": ["50"],
            "available_pkr": ["-100"],
        }
        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-100.00')

    def test_failed_withdrawal_does_not_consume_idempotency_key(self):
        """A rejected withdrawal leaves the reference number available — a
        retry with corrected amount must be able to claim it."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('100.00'))

        with pytest.raises(InsufficientFundsError):
            record_transaction(
                technician=tech,
                transaction_type=TransactionType.WITHDRAWAL_DEBIT,
                amount=Decimal('-500.00'),
                transaction_reference_number='withdrawal:42',
            )

        # Same key, corrected amount — should succeed.
        wt = record_transaction(
            technician=tech,
            transaction_type=TransactionType.WITHDRAWAL_DEBIT,
            amount=Decimal('-50.00'),
            transaction_reference_number='withdrawal:42',
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('50.00')
        assert wt.transaction_reference_number == 'withdrawal:42'


# ──────────────────────────────────────────────────────────────────────
# COMMISSION_DEBIT / REFUND_DEBIT — penalizing debits drive lockout.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestPenalizingDebitsAllowOverdraw:
    def test_commission_can_drive_balance_negative(self):
        """A tech took customer cash for a completed job; platform's cut
        is owed regardless. Commission must record even when low."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('100.00'))

        wt = record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-300.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-200.00')
        assert wt.balance_after == Decimal('-200.00')

    def test_commission_can_deepen_already_negative_balance(self):
        """A locked tech who completes another job still owes more
        commission — the platform's claim doesn't pause for lockout."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-100.00'))

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-200.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-300.00')

    def test_refund_can_drive_balance_negative(self):
        """Admin-issued customer refund is a penalty — tech cannot refuse."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('50.00'))

        wt = record_transaction(
            technician=tech,
            transaction_type=TransactionType.REFUND_DEBIT,
            amount=Decimal('-200.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-150.00')
        assert wt.balance_after == Decimal('-150.00')


# ──────────────────────────────────────────────────────────────────────
# ADJUSTMENT — admin discretion, either direction.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestAdjustmentDiscretion:
    def test_negative_adjustment_can_drive_balance_negative(self):
        """Admin manual debit (e.g. fixing a missed commission) — allowed
        even if it puts the tech in lockout territory."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('100.00'))

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.ADJUSTMENT,
            amount=Decimal('-300.00'),
            is_manual_adjustment=True,
            memo='Backfill missed commission for booking 117',
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-200.00')

    def test_positive_adjustment_can_clear_lockout(self):
        """Admin credit to settle a complaint — allowed to lift lockout."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-150.00'))

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.ADJUSTMENT,
            amount=Decimal('200.00'),
            is_manual_adjustment=True,
            memo='Goodwill credit per ticket #88',
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('50.00')


# ──────────────────────────────────────────────────────────────────────
# TOPUP_CREDIT — always permitted.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestTopupAlwaysPermitted:
    def test_topup_on_locked_wallet_partial_recovery(self):
        """Top-up that doesn't fully clear lockout still records — balance
        remains negative but moves toward zero."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-200.00'))

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.TOPUP_CREDIT,
            amount=Decimal('50.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-150.00')

    def test_topup_clears_lockout(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-200.00'))

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.TOPUP_CREDIT,
            amount=Decimal('500.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('300.00')

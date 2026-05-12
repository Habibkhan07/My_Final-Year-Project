"""Tests for ``WalletFinanceAdapter`` — the FinancePort implementation.

Covers the 5 FinancePort hook methods and the idempotency / no-op
contracts the orchestrator depends on.
"""
from __future__ import annotations

from decimal import Decimal

import pytest

from tests.factories.bookings import JobBookingCompletedFactory
from tests.factories.technicians import TechnicianProfileFactory
from wallet.adapters.wallet_finance_adapter import WalletFinanceAdapter
from wallet.models import (
    JobCommission,
    TransactionType,
    WalletTransaction,
)


@pytest.fixture
def adapter() -> WalletFinanceAdapter:
    return WalletFinanceAdapter()


@pytest.mark.django_db
class TestCanAcceptJob:
    def test_always_permits_tonight(self, adapter):
        """Lockout enforcement is deferred to Thursday. Adapter must permit."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))
        allowed, reason = adapter.can_accept_job(technician=tech, payout_amount=Decimal('500'))
        assert allowed is True
        assert reason is None

    def test_permits_even_with_negative_balance(self, adapter):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-100.00'))
        allowed, reason = adapter.can_accept_job(technician=tech, payout_amount=Decimal('500'))
        assert allowed is True
        assert reason is None


@pytest.mark.django_db
class TestRecordCommission:
    def test_writes_debit_and_subtype_row(self, adapter):
        booking = JobBookingCompletedFactory()
        booking.technician.current_wallet_balance = Decimal('1000.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        adapter.record_commission(booking=booking, amount=Decimal('500.00'))

        booking.technician.refresh_from_db()
        # 20% of 500 = 100 → balance 1000 - 100 = 900
        assert booking.technician.current_wallet_balance == Decimal('900.00')

        wt = WalletTransaction.objects.get(
            transaction_reference_number=f'booking:{booking.id}:commission'
        )
        assert wt.transaction_type == TransactionType.COMMISSION_DEBIT
        assert wt.amount == Decimal('-100.00')
        assert wt.balance_after == Decimal('900.00')

        commission = JobCommission.objects.get(booking=booking)
        assert commission.payout_amount == Decimal('500.00')
        assert commission.commission_rate == Decimal('0.20')
        assert commission.commission_amount == Decimal('100.00')
        assert commission.wallet_transaction == wt

    def test_idempotent_on_retry(self, adapter):
        """Re-call with same booking does not double-debit."""
        booking = JobBookingCompletedFactory()
        booking.technician.current_wallet_balance = Decimal('1000.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        adapter.record_commission(booking=booking, amount=Decimal('500.00'))
        adapter.record_commission(booking=booking, amount=Decimal('500.00'))
        adapter.record_commission(booking=booking, amount=Decimal('500.00'))

        booking.technician.refresh_from_db()
        assert booking.technician.current_wallet_balance == Decimal('900.00')
        assert WalletTransaction.objects.filter(
            transaction_reference_number=f'booking:{booking.id}:commission',
        ).count() == 1
        assert JobCommission.objects.filter(booking=booking).count() == 1

    def test_commission_amount_quantized_to_two_dp(self, adapter):
        """20% of an awkward number rounds correctly to 2dp."""
        booking = JobBookingCompletedFactory()
        booking.technician.current_wallet_balance = Decimal('1000.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        # 20% of 333.33 = 66.666 → quantize → 66.67
        adapter.record_commission(booking=booking, amount=Decimal('333.33'))

        commission = JobCommission.objects.get(booking=booking)
        assert commission.commission_amount == Decimal('66.67')


@pytest.mark.django_db
class TestApplyInspectionFeeDecision:
    def test_accepted_is_noop(self, adapter):
        booking = JobBookingCompletedFactory()
        booking.technician.current_wallet_balance = Decimal('100.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        adapter.apply_inspection_fee_decision(booking=booking, decision='accepted')

        booking.technician.refresh_from_db()
        assert booking.technician.current_wallet_balance == Decimal('100.00')
        assert not WalletTransaction.objects.filter(technician=booking.technician).exists()

    def test_declined_is_noop(self, adapter):
        """Customer pays Rs.500 cash directly to tech — no wallet entry tonight."""
        booking = JobBookingCompletedFactory()
        booking.technician.current_wallet_balance = Decimal('100.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        adapter.apply_inspection_fee_decision(booking=booking, decision='declined')

        booking.technician.refresh_from_db()
        assert booking.technician.current_wallet_balance == Decimal('100.00')
        assert not WalletTransaction.objects.filter(technician=booking.technician).exists()


@pytest.mark.django_db
class TestApplyCancellationCharge:
    @pytest.mark.parametrize('actor,phase', [
        ('customer', 'pre_accept'),
        ('customer', 'pre_arrival'),
        ('customer', 'post_arrival'),
        ('tech', 'pre_accept'),
        ('tech', 'pre_arrival'),
        ('tech', 'post_arrival'),
    ])
    def test_all_combinations_noop(self, adapter, actor, phase):
        """Cancellation fees are cash exchanges; wallet has no entry."""
        booking = JobBookingCompletedFactory()
        booking.technician.current_wallet_balance = Decimal('100.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        adapter.apply_cancellation_charge(booking=booking, actor=actor, phase=phase)

        booking.technician.refresh_from_db()
        assert booking.technician.current_wallet_balance == Decimal('100.00')
        assert not WalletTransaction.objects.filter(technician=booking.technician).exists()


@pytest.mark.django_db
class TestRecordCashCollected:
    def test_is_noop(self, adapter):
        """Cash goes to tech's pocket — wallet only sees commission deduction."""
        booking = JobBookingCompletedFactory()
        booking.technician.current_wallet_balance = Decimal('100.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        adapter.record_cash_collected(booking=booking, amount=Decimal('1500.00'), method='cash')

        booking.technician.refresh_from_db()
        assert booking.technician.current_wallet_balance == Decimal('100.00')
        assert not WalletTransaction.objects.filter(technician=booking.technician).exists()

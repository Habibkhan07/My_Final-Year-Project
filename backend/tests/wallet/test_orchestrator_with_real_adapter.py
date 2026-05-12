"""End-to-end test: orchestrator + WalletFinanceAdapter (real ledger writes).

This is the integration sanity check that the FinancePort wiring actually
moves money on a real booking transition. Distinct from the orchestrator's
own test suite (which uses NullFinanceAdapter) by passing the real adapter
explicitly into ``mark_complete_with_cash``.

The orchestrator wraps the FinancePort call in ``transaction.atomic()`` —
if the adapter raises, the booking status flip rolls back too. This test
exercises the happy path; the atomicity guarantee is exercised in
test_ledger.test_broadcast_not_fired_on_rollback.
"""
from __future__ import annotations

from decimal import Decimal

import pytest

from bookings.models import JobBooking
from bookings.services.orchestrator import mark_complete_with_cash
from tests.factories.bookings import JobBookingInProgressFactory
from wallet.adapters.wallet_finance_adapter import WalletFinanceAdapter
from wallet.models import JobCommission, TransactionType, WalletTransaction


@pytest.mark.django_db
class TestCompleteBookingThroughWallet:
    def test_full_flow_writes_commission_to_ledger(
        self,
        django_capture_on_commit_callbacks,
    ):
        """ACCEPT → ... → IN_PROGRESS → COMPLETED with cash collection.

        Asserts:
          1. ``WalletTransaction`` COMMISSION_DEBIT row exists with the
             correct amount (20% of cash collected).
          2. ``JobCommission`` row exists with snapshot of rate + amount.
          3. ``TechnicianProfile.current_wallet_balance`` decreased by
             the commission amount.
          4. ``balance_after`` invariant holds:
             ``current_wallet_balance == latest balance_after for tech``.
        """
        booking = JobBookingInProgressFactory(
            final_cash_to_collect=Decimal('1500.00'),
        )
        booking.technician.current_wallet_balance = Decimal('5000.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        # Drive the orchestrator transition with the REAL adapter injected
        # (bypasses the FINANCE_BACKEND env-var path).
        with django_capture_on_commit_callbacks(execute=True):
            updated = mark_complete_with_cash(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                cash_amount=Decimal('1500.00'),
                method='cash',
                finance=WalletFinanceAdapter(),
            )

        assert updated.status == JobBooking.STATUS_COMPLETED
        assert updated.cash_collected_amount == Decimal('1500.00')

        # Wallet ledger side.
        wt = WalletTransaction.objects.get(
            technician=booking.technician,
            transaction_type=TransactionType.COMMISSION_DEBIT,
        )
        # 20% of 1500 = 300
        assert wt.amount == Decimal('-300.00')
        assert wt.balance_after == Decimal('4700.00')
        assert wt.transaction_reference_number == f'booking:{booking.id}:commission'

        commission = JobCommission.objects.get(booking=booking)
        assert commission.payout_amount == Decimal('1500.00')
        assert commission.commission_rate == Decimal('0.20')
        assert commission.commission_amount == Decimal('300.00')
        assert commission.wallet_transaction == wt

        booking.technician.refresh_from_db()
        assert booking.technician.current_wallet_balance == Decimal('4700.00')

    def test_idempotent_retry_no_double_debit(
        self,
        django_capture_on_commit_callbacks,
    ):
        """A retry of ``mark_complete_with_cash`` (orchestrator's idempotency
        path returns the existing COMPLETED booking) must not write a second
        commission row.

        Tests that the adapter's ``JobCommission`` 1:1 guard short-circuits
        before any ledger work — even when called outside the orchestrator's
        re-entry guard.
        """
        booking = JobBookingInProgressFactory(
            final_cash_to_collect=Decimal('1000.00'),
        )
        booking.technician.current_wallet_balance = Decimal('5000.00')
        booking.technician.save(update_fields=['current_wallet_balance'])

        adapter = WalletFinanceAdapter()

        with django_capture_on_commit_callbacks(execute=True):
            mark_complete_with_cash(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                cash_amount=Decimal('1000.00'),
                method='cash',
                finance=adapter,
            )

        # Direct second call to the adapter mimics retries / out-of-order
        # event processing.
        booking.refresh_from_db()
        adapter.record_commission(booking=booking, amount=Decimal('1000.00'))

        assert WalletTransaction.objects.filter(
            technician=booking.technician,
            transaction_type=TransactionType.COMMISSION_DEBIT,
        ).count() == 1
        assert JobCommission.objects.filter(booking=booking).count() == 1
        booking.technician.refresh_from_db()
        # 20% of 1000 = 200; only deducted once.
        assert booking.technician.current_wallet_balance == Decimal('4800.00')

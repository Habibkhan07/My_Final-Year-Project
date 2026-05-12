"""Tests for ``wallet.services.ledger.record_transaction``.

These pin the ACID guarantees and audit invariants:
* balance_after is computed and written under the same lock as the tech
  row update — no skew between snapshot and denormalized balance.
* Idempotency via ``transaction_reference_number`` returns the existing
  row without re-mutating the balance.
* The post-commit broadcast fires once (and not on rollback).
"""
from __future__ import annotations

from decimal import Decimal
from unittest.mock import patch

import pytest
from django.db import transaction

from technicians.models import TechnicianProfile
from tests.factories.technicians import TechnicianProfileFactory
from wallet.models import TransactionType, WalletTransaction
from wallet.services.ledger import record_transaction


@pytest.mark.django_db
class TestRecordTransaction:
    def test_credit_increases_balance(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('100.00'))

        wt = record_transaction(
            technician=tech,
            transaction_type=TransactionType.TOPUP_CREDIT,
            amount=Decimal('500.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('600.00')
        assert wt.amount == Decimal('500.00')
        assert wt.balance_after == Decimal('600.00')

    def test_debit_decreases_balance(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('1000.00'))

        wt = record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-200.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('800.00')
        assert wt.balance_after == Decimal('800.00')

    def test_balance_after_invariant_holds_across_multiple_rows(self):
        """``MAX(balance_after)`` per tech must match ``current_wallet_balance``."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))

        record_transaction(technician=tech, transaction_type=TransactionType.TOPUP_CREDIT, amount=Decimal('1000.00'))
        record_transaction(technician=tech, transaction_type=TransactionType.COMMISSION_DEBIT, amount=Decimal('-200.00'))
        record_transaction(technician=tech, transaction_type=TransactionType.COMMISSION_DEBIT, amount=Decimal('-150.00'))

        tech.refresh_from_db()
        latest = (
            WalletTransaction.objects
            .filter(technician=tech)
            .order_by('-timestamp')
            .first()
        )
        assert tech.current_wallet_balance == Decimal('650.00')
        assert latest.balance_after == tech.current_wallet_balance

    def test_idempotency_returns_existing_row_no_double_write(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))

        first = record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-100.00'),
            transaction_reference_number='booking:42:commission',
        )

        # Retry with same idempotency key.
        second = record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-100.00'),
            transaction_reference_number='booking:42:commission',
        )

        tech.refresh_from_db()
        assert first.pk == second.pk
        # Balance only moved once.
        assert tech.current_wallet_balance == Decimal('-100.00')
        assert WalletTransaction.objects.filter(technician=tech).count() == 1

    def test_empty_reference_allows_multiple_rows(self):
        """Empty ``transaction_reference_number`` is not unique — multiple
        rows can co-exist (e.g. ADJUSTMENT entries by admin)."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.ADJUSTMENT,
            amount=Decimal('50.00'),
            is_manual_adjustment=True,
        )
        record_transaction(
            technician=tech,
            transaction_type=TransactionType.ADJUSTMENT,
            amount=Decimal('25.00'),
            is_manual_adjustment=True,
        )

        assert WalletTransaction.objects.filter(technician=tech).count() == 2

    def test_amount_coerced_to_decimal(self):
        """Caller passing a float is coerced to Decimal — no silent precision loss."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))

        wt = record_transaction(
            technician=tech,
            transaction_type=TransactionType.TOPUP_CREDIT,
            amount=100,  # int — not Decimal
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('100.00')
        assert isinstance(wt.amount, Decimal)

    def test_broadcast_scheduled_on_commit(self, django_capture_on_commit_callbacks):
        """``WALLET_BALANCE_UPDATED`` is queued via on_commit, fires on commit.

        ``pytest.mark.django_db`` wraps the test in a transaction that's
        rolled back at teardown, so on_commit hooks never fire naturally.
        ``django_capture_on_commit_callbacks(execute=True)`` is the pytest-
        django fixture that flushes them at block exit, simulating commit.
        """
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))

        with patch(
            'wallet.services.ledger._broadcast_wallet_balance_updated'
        ) as mock_broadcast:
            with django_capture_on_commit_callbacks(execute=True):
                record_transaction(
                    technician=tech,
                    transaction_type=TransactionType.TOPUP_CREDIT,
                    amount=Decimal('100.00'),
                )
                # Inside the captured block, the broadcast has NOT fired yet.
                assert mock_broadcast.call_count == 0

            # Block exit flushed the on_commit queue.
            assert mock_broadcast.call_count == 1
            kwargs = mock_broadcast.call_args.kwargs
            assert kwargs['tech_user_id'] == tech.user_id
            assert kwargs['balance'] == '100.00'

    def test_broadcast_not_fired_on_rollback(self, django_capture_on_commit_callbacks):
        """If the surrounding transaction rolls back, the broadcast NEVER fires."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))

        class _Boom(Exception):
            pass

        with patch(
            'wallet.services.ledger._broadcast_wallet_balance_updated'
        ) as mock_broadcast:
            with pytest.raises(_Boom):
                with django_capture_on_commit_callbacks(execute=True):
                    with transaction.atomic():
                        record_transaction(
                            technician=tech,
                            transaction_type=TransactionType.TOPUP_CREDIT,
                            amount=Decimal('100.00'),
                        )
                        raise _Boom()

            assert mock_broadcast.call_count == 0

        # And the row was rolled back.
        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('0.00')
        assert not WalletTransaction.objects.filter(technician=tech).exists()

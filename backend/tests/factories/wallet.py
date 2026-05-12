"""Factories for the wallet domain.

These build INSTANCES directly via factory_boy. They DO NOT invoke
``wallet.services.ledger.record_transaction`` — tests that exercise the
balance/audit invariants must go through the ledger; tests that only need
a pre-existing row use these factories.
"""
from decimal import Decimal

import factory

from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingCompletedFactory
from tests.factories.technicians import TechnicianProfileFactory
from wallet.models import (
    JobCommission,
    RefundDeduction,
    TechnicianBankAccount,
    TechnicianJazzCashAccount,
    TopupStatus,
    TransactionType,
    WalletTopup,
    WalletTransaction,
    WithdrawalFulfilment,
    WithdrawalRequest,
    WithdrawalStatus,
)


class WalletTransactionFactory(factory.django.DjangoModelFactory):
    """Direct WalletTransaction row. Bypasses ledger guarantees.

    For invariant-checking tests that need raw rows, set ``balance_after``
    explicitly and don't trust ``technician.current_wallet_balance``.
    """
    class Meta:
        model = WalletTransaction

    technician = factory.SubFactory(TechnicianProfileFactory)
    amount = Decimal('-100.00')
    transaction_type = TransactionType.COMMISSION_DEBIT
    balance_after = Decimal('900.00')
    gateway_reference = ''
    transaction_reference_number = ''
    is_manual_adjustment = False
    memo = ''


class WalletTopupFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = WalletTopup

    technician = factory.SubFactory(TechnicianProfileFactory)
    wallet_transaction = None  # nullable until COMPLETED
    amount_attempted = Decimal('500.00')
    gateway_name = 'mock'
    gateway_status = TopupStatus.PENDING


class JobCommissionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = JobCommission

    wallet_transaction = factory.SubFactory(WalletTransactionFactory)
    booking = factory.SubFactory(JobBookingCompletedFactory)
    payout_amount = Decimal('1000.00')
    commission_rate = Decimal('0.20')
    commission_amount = Decimal('200.00')


class RefundDeductionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = RefundDeduction

    wallet_transaction = factory.SubFactory(WalletTransactionFactory)
    penalty_reason = 'Test refund'


class TechnicianBankAccountFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TechnicianBankAccount

    technician = factory.SubFactory(TechnicianProfileFactory)
    bank_name = 'HBL'
    account_title = 'Test Tech'
    account_number_or_iban = factory.Sequence(lambda n: f'PK00HBL000000000{n:04d}')
    is_active = True


class TechnicianJazzCashAccountFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TechnicianJazzCashAccount

    technician = factory.SubFactory(TechnicianProfileFactory)
    account_title = 'Test Tech'
    mobile_number = factory.Sequence(lambda n: f'+9230012{n:05d}')
    is_active = True


class WithdrawalRequestFactory(factory.django.DjangoModelFactory):
    """Default ties to a bank account; pass ``payout_jazzcash_account=...``
    to flip the XOR side. The CheckConstraint requires exactly one set.
    """
    class Meta:
        model = WithdrawalRequest

    technician = factory.SubFactory(TechnicianProfileFactory)
    amount = Decimal('500.00')
    status = WithdrawalStatus.PENDING_REVIEW
    payout_bank_account = factory.SubFactory(
        TechnicianBankAccountFactory,
        technician=factory.SelfAttribute('..technician'),
    )
    payout_jazzcash_account = None


class WithdrawalFulfilmentFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = WithdrawalFulfilment

    withdrawal_request = factory.SubFactory(WithdrawalRequestFactory)
    wallet_transaction = factory.SubFactory(WalletTransactionFactory)
    processing_note = ''

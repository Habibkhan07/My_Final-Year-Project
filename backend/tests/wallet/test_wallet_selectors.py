"""Tests for ``wallet.selectors.wallet_selectors.list_transactions``."""
from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

import pytest
from django.utils import timezone

from tests.factories.bookings import JobBookingCompletedFactory
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.wallet import (
    JobCommissionFactory,
    RefundDeductionFactory,
    WalletTopupFactory,
    WalletTransactionFactory,
    WithdrawalFulfilmentFactory,
    WithdrawalRequestFactory,
)
from wallet.models import TopupStatus, TransactionType
from wallet.selectors.wallet_selectors import (
    DEFAULT_PAGE_SIZE,
    InvalidCursor,
    _decode_cursor,
    _encode_cursor,
    list_transactions,
)


def _make_commission(tech, *, when, amount=Decimal('-200.00')):
    """Build a COMMISSION_DEBIT row + its JobCommission subtype."""
    booking = JobBookingCompletedFactory(technician=tech)
    txn = WalletTransactionFactory(
        technician=tech,
        amount=amount,
        transaction_type=TransactionType.COMMISSION_DEBIT,
        balance_after=Decimal('800.00'),
    )
    JobCommissionFactory(wallet_transaction=txn, booking=booking)
    _stamp_timestamp(txn, when)
    return txn


def _make_topup(tech, *, when, gateway='jazzcash', amount=Decimal('500.00')):
    txn = WalletTransactionFactory(
        technician=tech,
        amount=amount,
        transaction_type=TransactionType.TOPUP_CREDIT,
        balance_after=Decimal('1500.00'),
    )
    WalletTopupFactory(
        technician=tech,
        wallet_transaction=txn,
        gateway_name=gateway,
        gateway_status=TopupStatus.COMPLETED,
    )
    _stamp_timestamp(txn, when)
    return txn


def _make_withdrawal(tech, *, when, external_ref=''):
    request = WithdrawalRequestFactory(technician=tech, admin_external_ref=external_ref)
    txn = WalletTransactionFactory(
        technician=tech,
        amount=Decimal('-300.00'),
        transaction_type=TransactionType.WITHDRAWAL_DEBIT,
        balance_after=Decimal('500.00'),
    )
    WithdrawalFulfilmentFactory(withdrawal_request=request, wallet_transaction=txn)
    _stamp_timestamp(txn, when)
    return txn


def _make_refund(tech, *, when, reason='Customer overcharge dispute'):
    txn = WalletTransactionFactory(
        technician=tech,
        amount=Decimal('-150.00'),
        transaction_type=TransactionType.REFUND_DEBIT,
        balance_after=Decimal('350.00'),
    )
    RefundDeductionFactory(wallet_transaction=txn, penalty_reason=reason)
    _stamp_timestamp(txn, when)
    return txn


def _make_adjustment(tech, *, when, memo='Goodwill credit'):
    txn = WalletTransactionFactory(
        technician=tech,
        amount=Decimal('+100.00'),
        transaction_type=TransactionType.ADJUSTMENT,
        balance_after=Decimal('450.00'),
        memo=memo,
        is_manual_adjustment=True,
    )
    _stamp_timestamp(txn, when)
    return txn


def _stamp_timestamp(txn, when):
    """Force a specific ``timestamp`` past the auto_now_add default."""
    type(txn).objects.filter(pk=txn.pk).update(timestamp=when)
    txn.refresh_from_db(fields=['timestamp'])


@pytest.mark.django_db
class TestListTransactionsOrdering:
    def test_newest_first(self):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        old = _make_commission(tech, when=now - timedelta(days=2))
        mid = _make_topup(tech, when=now - timedelta(days=1))
        new = _make_withdrawal(tech, when=now)

        page = list_transactions(tech)

        ids = [r['id'] for r in page['results']]
        assert ids == [new.id, mid.id, old.id]

    def test_only_scopes_to_the_technician(self):
        """IDOR: another tech's rows must never leak into this page."""
        me = TechnicianProfileFactory()
        other = TechnicianProfileFactory()
        now = timezone.now()
        mine = _make_commission(me, when=now)
        _make_commission(other, when=now)  # noise — must not appear

        page = list_transactions(me)

        assert [r['id'] for r in page['results']] == [mine.id]


@pytest.mark.django_db
class TestListTransactionsPagination:
    def test_next_cursor_round_trip(self):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        # Five rows spaced 1 minute apart.
        txns = [
            _make_commission(tech, when=now - timedelta(minutes=offset))
            for offset in range(5)
        ]

        page1 = list_transactions(tech, page_size=2)
        assert [r['id'] for r in page1['results']] == [txns[0].id, txns[1].id]
        assert page1['next_cursor'] is not None

        page2 = list_transactions(tech, page_size=2, cursor=page1['next_cursor'])
        assert [r['id'] for r in page2['results']] == [txns[2].id, txns[3].id]
        assert page2['next_cursor'] is not None

        page3 = list_transactions(tech, page_size=2, cursor=page2['next_cursor'])
        assert [r['id'] for r in page3['results']] == [txns[4].id]
        # Last page → no further cursor.
        assert page3['next_cursor'] is None

    def test_invalid_cursor_raises(self):
        tech = TechnicianProfileFactory()
        with pytest.raises(InvalidCursor):
            list_transactions(tech, cursor='not-base64-***')

    def test_cursor_encode_decode_round_trip(self):
        now = timezone.now()
        cursor = _encode_cursor(now, 42)
        ts, row_id = _decode_cursor(cursor)
        assert row_id == 42
        # Microseconds-and-tz preserved.
        assert ts == now


@pytest.mark.django_db
class TestDumbUIShaping:
    def test_commission_row_subtitle_is_booking_id(self):
        tech = TechnicianProfileFactory()
        txn = _make_commission(tech, when=timezone.now())
        result = list_transactions(tech)['results'][0]
        assert result['ui_icon'] == 'commission'
        assert result['ui_title'] == 'Platform commission'
        assert result['ui_subtitle'].startswith('Booking #')
        assert result['ui_amount_color'] == 'debit'
        assert result['type'] == 'COMMISSION_DEBIT'

    def test_topup_row_subtitle_is_gateway_display(self):
        tech = TechnicianProfileFactory()
        _make_topup(tech, when=timezone.now(), gateway='jazzcash')
        result = list_transactions(tech)['results'][0]
        assert result['ui_icon'] == 'topup'
        assert result['ui_title'] == 'Wallet top-up'
        assert result['ui_subtitle'] == 'via JazzCash'
        assert result['ui_amount_color'] == 'credit'

    def test_withdrawal_row_uses_external_ref_when_present(self):
        tech = TechnicianProfileFactory()
        _make_withdrawal(tech, when=timezone.now(), external_ref='JC-XYZ-9999')
        result = list_transactions(tech)['results'][0]
        assert result['ui_icon'] == 'withdrawal'
        assert result['ui_title'] == 'Withdrawal'
        assert 'JC-XYZ-9999' in result['ui_subtitle']
        assert result['ui_amount_color'] == 'debit'

    def test_refund_row_subtitle_is_penalty_reason(self):
        tech = TechnicianProfileFactory()
        _make_refund(tech, when=timezone.now(), reason='Wrong service rendered')
        result = list_transactions(tech)['results'][0]
        assert result['ui_icon'] == 'refund'
        assert result['ui_subtitle'] == 'Wrong service rendered'
        assert result['ui_amount_color'] == 'debit'

    def test_adjustment_row_subtitle_is_memo(self):
        tech = TechnicianProfileFactory()
        _make_adjustment(tech, when=timezone.now(), memo='Welcome bonus')
        result = list_transactions(tech)['results'][0]
        assert result['ui_icon'] == 'adjustment'
        assert result['ui_subtitle'] == 'Welcome bonus'
        assert result['ui_amount_color'] == 'credit'


@pytest.mark.django_db
class TestListTransactionsEmpty:
    def test_no_rows_returns_empty_page(self):
        tech = TechnicianProfileFactory()
        page = list_transactions(tech)
        assert page == {'results': [], 'next_cursor': None}


@pytest.mark.django_db
class TestQueryCount:
    """Selector must stay N+1-free even with all five subtype joins active."""

    def test_one_query_for_mixed_page(self, django_assert_max_num_queries):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        _make_commission(tech, when=now - timedelta(minutes=1))
        _make_topup(tech, when=now - timedelta(minutes=2))
        _make_withdrawal(tech, when=now - timedelta(minutes=3), external_ref='X')
        _make_refund(tech, when=now - timedelta(minutes=4))
        _make_adjustment(tech, when=now - timedelta(minutes=5))

        # One query for the rows (select_related folds the four subtype
        # joins into the same SELECT).
        with django_assert_max_num_queries(1):
            page = list_transactions(tech, page_size=DEFAULT_PAGE_SIZE)
            # Force evaluation of every Dumb-UI lookup.
            _ = [r['ui_subtitle'] for r in page['results']]

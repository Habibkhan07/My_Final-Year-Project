"""Tests for ``GET /api/technicians/wallet/`` + ``/transactions/``."""
from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingCompletedFactory
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.wallet import (
    JobCommissionFactory,
    WalletTransactionFactory,
)
from wallet.models import TransactionType


@pytest.mark.django_db
class TestWalletBalanceView:
    URL = '/api/technicians/wallet/'

    def test_unauthenticated_returns_401(self):
        client = APIClient()
        resp = client.get(self.URL)
        assert resp.status_code == 401

    def test_non_technician_user_returns_403(self):
        """A customer-role user has no tech_profile → permission_denied envelope."""
        customer = UserFactory()
        client = APIClient()
        client.force_authenticate(user=customer)

        resp = client.get(self.URL)
        # AttributeError on .tech_profile becomes RelatedObjectDoesNotExist,
        # which the view catches as TechnicianProfile.DoesNotExist → 403.
        assert resp.status_code == 403
        body = resp.json()
        assert body['code'] == 'permission_denied'

    def test_authenticated_technician_gets_balance(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('1500.00'))
        client = APIClient()
        client.force_authenticate(user=tech.user)

        resp = client.get(self.URL)
        assert resp.status_code == 200
        body = resp.json()
        assert body['balance'] == '1500.00'
        assert 'as_of' in body

    def test_zero_balance_renders_correctly(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))
        client = APIClient()
        client.force_authenticate(user=tech.user)

        resp = client.get(self.URL)
        assert resp.status_code == 200
        assert resp.json()['balance'] == '0.00'

    def test_balance_is_string_not_number(self):
        """Decimal precision must survive the wire — string serialization."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('1234.56'))
        client = APIClient()
        client.force_authenticate(user=tech.user)

        resp = client.get(self.URL)
        assert isinstance(resp.json()['balance'], str)

    # --- Lockout fields (Dumb-UI payload from lockout_status) -----------

    def test_positive_balance_payload_has_lockout_fields_unlocked(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('1500.00'))
        client = APIClient()
        client.force_authenticate(user=tech.user)

        body = client.get(self.URL).json()
        assert body['is_locked_out'] is False
        assert body['balance_pkr'] == 1500
        assert body['owed_pkr'] == 0

    def test_zero_balance_is_not_locked(self):
        """Boundary: zero is NOT lockout — strict ``< 0``."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))
        client = APIClient()
        client.force_authenticate(user=tech.user)

        body = client.get(self.URL).json()
        assert body['is_locked_out'] is False
        assert body['balance_pkr'] == 0
        assert body['owed_pkr'] == 0

    def test_negative_balance_payload_carries_owed_amount(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-495.00'))
        client = APIClient()
        client.force_authenticate(user=tech.user)

        body = client.get(self.URL).json()
        assert body['is_locked_out'] is True
        assert body['balance_pkr'] == -495
        assert body['owed_pkr'] == 495

    def test_paisa_fraction_owed_rounds_up(self):
        """Owed must round up so paying it clears the lockout — see the
        lockout-selector tests for the reasoning."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-100.01'))
        client = APIClient()
        client.force_authenticate(user=tech.user)

        body = client.get(self.URL).json()
        assert body['is_locked_out'] is True
        assert body['balance_pkr'] == -101
        assert body['owed_pkr'] == 101


def _make_commission_row(tech, *, when):
    booking = JobBookingCompletedFactory(technician=tech)
    txn = WalletTransactionFactory(
        technician=tech,
        amount=Decimal('-200.00'),
        transaction_type=TransactionType.COMMISSION_DEBIT,
        balance_after=Decimal('800.00'),
    )
    JobCommissionFactory(wallet_transaction=txn, booking=booking)
    type(txn).objects.filter(pk=txn.pk).update(timestamp=when)
    txn.refresh_from_db(fields=['timestamp'])
    return txn


@pytest.mark.django_db
class TestWalletTransactionListView:
    URL = '/api/technicians/wallet/transactions/'

    def test_unauthenticated_returns_401(self):
        client = APIClient()
        resp = client.get(self.URL)
        assert resp.status_code == 401

    def test_non_technician_user_returns_403(self):
        customer = UserFactory()
        client = APIClient()
        client.force_authenticate(user=customer)

        resp = client.get(self.URL)
        assert resp.status_code == 403
        assert resp.json()['code'] == 'permission_denied'

    def test_returns_paginated_results_envelope(self):
        tech = TechnicianProfileFactory()
        _make_commission_row(tech, when=timezone.now())
        client = APIClient()
        client.force_authenticate(user=tech.user)

        resp = client.get(self.URL)

        assert resp.status_code == 200
        body = resp.json()
        assert 'results' in body
        assert 'next_cursor' in body
        assert len(body['results']) == 1
        row = body['results'][0]
        assert row['ui_icon'] == 'commission'
        assert row['ui_title'] == 'Platform commission'
        assert row['ui_amount_color'] == 'debit'

    def test_cursor_round_trip_via_http(self):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        rows = [
            _make_commission_row(tech, when=now - timedelta(minutes=offset))
            for offset in range(3)
        ]
        client = APIClient()
        client.force_authenticate(user=tech.user)

        resp1 = client.get(self.URL, {'page_size': 2})
        assert resp1.status_code == 200
        body1 = resp1.json()
        assert [r['id'] for r in body1['results']] == [rows[0].id, rows[1].id]
        assert body1['next_cursor'] is not None

        resp2 = client.get(self.URL, {'page_size': 2, 'cursor': body1['next_cursor']})
        body2 = resp2.json()
        assert [r['id'] for r in body2['results']] == [rows[2].id]
        assert body2['next_cursor'] is None

    def test_bad_cursor_returns_400_validation_error(self):
        tech = TechnicianProfileFactory()
        client = APIClient()
        client.force_authenticate(user=tech.user)

        resp = client.get(self.URL, {'cursor': '!!!not-base64!!!'})
        assert resp.status_code == 400
        body = resp.json()
        assert body['code'] == 'validation_error'
        assert 'cursor' in body['errors']

    def test_bad_page_size_returns_400(self):
        tech = TechnicianProfileFactory()
        client = APIClient()
        client.force_authenticate(user=tech.user)

        resp = client.get(self.URL, {'page_size': 'abc'})
        assert resp.status_code == 400
        assert resp.json()['code'] == 'validation_error'

    def test_cannot_see_another_techs_rows(self):
        me = TechnicianProfileFactory()
        other = TechnicianProfileFactory()
        _make_commission_row(other, when=timezone.now())
        client = APIClient()
        client.force_authenticate(user=me.user)

        resp = client.get(self.URL)
        assert resp.status_code == 200
        assert resp.json()['results'] == []

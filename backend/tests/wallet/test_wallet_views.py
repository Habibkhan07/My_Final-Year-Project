"""Tests for ``GET /api/technicians/wallet/``."""
from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework.test import APIClient

from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory


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

"""HTTP-layer tests for the topup flow.

Three views under test:

1. ``TopupCreateView`` — POST /api/technicians/wallet/topups/
2. ``TopupStatusView`` — GET /api/technicians/wallet/topups/<id>/
3. ``TopupBridgeView`` — GET /api/technicians/wallet/topups/<id>/bridge/
4. ``JazzCashReturnView`` — POST /api/wallet/gateway/jazzcash/return/

Tests pin auth gates, IDOR (tech A can't see tech B's topup), error
envelope shape, signed-token enforcement on the bridge, the mock vs
real-gateway template branch, and the end-to-end callback flow.
"""
from __future__ import annotations

from decimal import Decimal

import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory
from wallet.models import TopupStatus, WalletTopup
from wallet.services.topup_service import sign_bridge_token, start_topup


pytestmark = pytest.mark.django_db


@pytest.fixture
def tech_client(settings):
    """An APIClient authenticated as a technician."""
    settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
    settings.SITE_URL = 'http://testserver'
    tech = TechnicianProfileFactory()
    client = APIClient()
    client.force_authenticate(user=tech.user)
    return client, tech


# ---------------------------------------------------------------------------
# TopupCreateView
# ---------------------------------------------------------------------------

class TestTopupCreate:
    def test_unauthenticated_rejected(self):
        client = APIClient()
        response = client.post('/api/technicians/wallet/topups/', {'amount': 500}, format='json')
        assert response.status_code == 401

    def test_customer_user_rejected(self, settings):
        # User exists but has no tech_profile — _require_technician → 403.
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        user = UserFactory()
        client = APIClient()
        client.force_authenticate(user=user)
        response = client.post('/api/technicians/wallet/topups/', {'amount': 500}, format='json')
        assert response.status_code == 403
        assert response.data['code'] == 'permission_denied'

    def test_happy_path_returns_topup_id_and_redirect(self, tech_client):
        client, tech = tech_client
        response = client.post('/api/technicians/wallet/topups/', {'amount': 1000}, format='json')
        assert response.status_code == 201, response.data
        data = response.data
        assert 'topup_id' in data
        assert 'redirect_url' in data
        assert f'/topups/{data["topup_id"]}/bridge/' in data['redirect_url']

        topup = WalletTopup.objects.get(pk=data['topup_id'])
        assert topup.technician_id == tech.id
        assert topup.amount_attempted == Decimal('1000')

    def test_invalid_amount_returns_error_envelope(self, tech_client):
        client, _ = tech_client
        response = client.post('/api/technicians/wallet/topups/', {'amount': 'abc'}, format='json')
        assert response.status_code == 400
        assert response.data['code'] == 'validation_error'
        assert 'amount' in response.data['errors']

    def test_amount_out_of_range_returns_error_envelope(self, tech_client):
        client, _ = tech_client
        response = client.post('/api/technicians/wallet/topups/', {'amount': 1}, format='json')
        assert response.status_code == 400
        assert response.data['code'] == 'validation_error'
        assert 'amount' in response.data['errors']


# ---------------------------------------------------------------------------
# TopupStatusView
# ---------------------------------------------------------------------------

class TestTopupStatus:
    def test_returns_status_for_own_topup(self, tech_client):
        client, tech = tech_client
        topup = start_topup(technician=tech, amount_rs=500)
        response = client.get(f'/api/technicians/wallet/topups/{topup.topup_id}/')
        assert response.status_code == 200
        data = response.data
        assert data['topup_id'] == topup.topup_id
        assert data['status'] == TopupStatus.REDIRECTED
        # DecimalField(decimal_places=2) → str() always renders 2dp.
        assert data['amount'] == '500.00'

    def test_idor_returns_404(self, settings):
        # Tech A's topup, tech B's request → 404 (not 403, to avoid
        # confirming existence).
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech_a = TechnicianProfileFactory()
        tech_b = TechnicianProfileFactory()
        topup_a = start_topup(technician=tech_a, amount_rs=500)

        client = APIClient()
        client.force_authenticate(user=tech_b.user)
        response = client.get(f'/api/technicians/wallet/topups/{topup_a.topup_id}/')
        assert response.status_code == 404
        assert response.data['code'] == 'not_found'


# ---------------------------------------------------------------------------
# TopupBridgeView
# ---------------------------------------------------------------------------

class TestTopupBridge:
    def test_no_token_rejected(self, tech_client):
        client, tech = tech_client
        topup = start_topup(technician=tech, amount_rs=500)
        # Bridge is no-auth; using plain Client.
        from django.test import Client
        plain = Client()
        response = plain.get(f'/api/technicians/wallet/topups/{topup.topup_id}/bridge/')
        assert response.status_code == 400

    def test_bad_token_rejected(self, tech_client):
        client, tech = tech_client
        topup = start_topup(technician=tech, amount_rs=500)
        from django.test import Client
        plain = Client()
        response = plain.get(
            f'/api/technicians/wallet/topups/{topup.topup_id}/bridge/?t=garbage'
        )
        assert response.status_code == 400

    def test_token_for_wrong_topup_rejected(self, tech_client):
        client, tech = tech_client
        topup_a = start_topup(technician=tech, amount_rs=500)
        topup_b = start_topup(technician=tech, amount_rs=500)
        # Sign with A's id, hit B's bridge URL → reject.
        token_for_a = sign_bridge_token(topup_a.topup_id)
        from django.test import Client
        plain = Client()
        response = plain.get(
            f'/api/technicians/wallet/topups/{topup_b.topup_id}/bridge/?t={token_for_a}'
        )
        assert response.status_code == 400

    def test_mock_bridge_renders_pay_decline_buttons(self, tech_client):
        client, tech = tech_client
        result = start_topup(technician=tech, amount_rs=500)
        token = sign_bridge_token(result.topup_id)
        from django.test import Client
        plain = Client()
        response = plain.get(
            f'/api/technicians/wallet/topups/{result.topup_id}/bridge/?t={token}'
        )
        assert response.status_code == 200
        body = response.content.decode('utf-8')
        assert 'Mock JazzCash sandbox' in body
        # Two forms — Pay + Decline. The action target is the return URL.
        assert body.count('<form') >= 2
        assert 'Pay Rs. 500' in body
        assert 'Decline' in body


# ---------------------------------------------------------------------------
# JazzCashReturnView
# ---------------------------------------------------------------------------

class TestJazzCashReturn:
    def test_post_with_known_txn_ref_completes_topup(self, tech_client):
        client, tech = tech_client
        result = start_topup(technician=tech, amount_rs=500)
        topup = WalletTopup.objects.get(pk=result.topup_id)

        from django.test import Client
        plain = Client()
        response = plain.post(
            '/api/wallet/gateway/jazzcash/return/',
            data={
                'pp_TxnRefNo': topup.gateway_session_id,
                'pp_ResponseCode': '000',
            },
        )
        assert response.status_code == 200

        topup.refresh_from_db()
        assert topup.gateway_status == TopupStatus.COMPLETED

    def test_post_with_unknown_txn_ref_still_returns_200(self):
        # JazzCash retries on non-200; we MUST return 200 even when we
        # can't match the ref so JazzCash stops retrying.
        from django.test import Client
        plain = Client()
        response = plain.post(
            '/api/wallet/gateway/jazzcash/return/',
            data={'pp_TxnRefNo': 'STALE-REF', 'pp_ResponseCode': '000'},
        )
        assert response.status_code == 200

    def test_post_with_failure_payload_marks_failed_returns_200(self, tech_client):
        client, tech = tech_client
        result = start_topup(technician=tech, amount_rs=500)
        topup = WalletTopup.objects.get(pk=result.topup_id)

        from django.test import Client
        plain = Client()
        response = plain.post(
            '/api/wallet/gateway/jazzcash/return/',
            data={
                'pp_TxnRefNo': topup.gateway_session_id,
                'status': 'failed',
                'reason': 'cancelled_by_customer',
            },
        )
        assert response.status_code == 200

        topup.refresh_from_db()
        assert topup.gateway_status == TopupStatus.FAILED

    def test_get_returns_placeholder_200(self):
        # Some gateways issue a GET preview. We accept it gracefully.
        from django.test import Client
        plain = Client()
        response = plain.get('/api/wallet/gateway/jazzcash/return/')
        assert response.status_code == 200

"""
HTTP-level pins for POST /api/technicians/me/online/.

The endpoint counterpart to the ledger's auto-offline gate in
wallet/services/ledger.py — these tests pin both directions of the
toggle and every refusal path (lockout, status, auth, validation).
"""
from decimal import Decimal

import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from technicians.models import TechnicianProfile
from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db


class TestTechnicianOnlineToggleView:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('tech-online-toggle')

    # -- AuthN / 401 -------------------------------------------------------

    def test_unauthenticated_returns_401(self):
        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )
        assert response.status_code == 401

    # -- Happy path: APPROVED + unlocked ----------------------------------

    def test_unlocked_tech_can_go_online(self):
        tech = TechnicianProfileFactory(
            is_online=False,
            current_wallet_balance=Decimal('500.00'),
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )

        assert response.status_code == 200
        body = response.json()
        assert body['is_online'] is True
        assert body['current_wallet_balance'] == '500.00'

        # DB column flipped — not just the response payload.
        tech.refresh_from_db()
        assert tech.is_online is True

    def test_online_tech_can_go_offline(self):
        tech = TechnicianProfileFactory(
            is_online=True,
            current_wallet_balance=Decimal('500.00'),
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': False}, format='json',
        )

        assert response.status_code == 200
        assert response.json()['is_online'] is False
        tech.refresh_from_db()
        assert tech.is_online is False

    def test_idempotent_same_state_returns_200_unchanged(self):
        """Tap online when already online — no error, no state change.
        Defends against rapid double-taps from a sticky toggle."""
        tech = TechnicianProfileFactory(
            is_online=True,
            current_wallet_balance=Decimal('100.00'),
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )

        assert response.status_code == 200
        assert response.json()['is_online'] is True
        tech.refresh_from_db()
        assert tech.is_online is True

    # -- Lockout gate (the headline behaviour) ----------------------------

    def test_locked_tech_cannot_go_online_returns_403_wallet_lockout(self):
        """The headline pin: balance < 0 means is_online=true is refused
        with the same envelope as accept_job_booking. The FE's existing
        wallet_lockout handler reuses this contract unchanged."""
        tech = TechnicianProfileFactory(
            is_online=False,
            current_wallet_balance=Decimal('-101.00'),
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )

        assert response.status_code == 403
        body = response.json()
        assert body['code'] == 'wallet_lockout'
        # Envelope shape matches the existing WalletLockoutError contract.
        assert 'errors' in body
        assert body['errors']['balance_pkr'] == ['-101']
        assert body['errors']['owed_pkr'] == ['101']

        # The refusal MUST NOT mutate the column.
        tech.refresh_from_db()
        assert tech.is_online is False

    def test_locked_tech_can_still_go_offline(self):
        """Opting OUT of work is always safe — even when locked. Mirrors
        the ledger's auto-offline rule: locked techs can always be offline,
        they just can't be online."""
        tech = TechnicianProfileFactory(
            is_online=True,
            current_wallet_balance=Decimal('-50.00'),
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': False}, format='json',
        )

        assert response.status_code == 200
        assert response.json()['is_online'] is False
        tech.refresh_from_db()
        assert tech.is_online is False

    def test_zero_balance_can_go_online(self):
        """Strict-negative boundary pin: balance == 0 is NOT lockout.
        Matches wallet/selectors/lockout.is_wallet_locked which uses
        `< Decimal('0')` (strict)."""
        tech = TechnicianProfileFactory(
            is_online=False,
            current_wallet_balance=Decimal('0.00'),
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )

        assert response.status_code == 200
        assert response.json()['is_online'] is True

    # -- Status guard ------------------------------------------------------

    def test_pure_customer_returns_403(self):
        """User has no tech profile at all — refuse with 403 (not 404)
        so the FE doesn't get a different envelope shape per failure."""
        user = UserFactory()
        self.client.force_authenticate(user=user)

        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )

        assert response.status_code == 403

    def test_pending_tech_returns_403(self):
        tech = TechnicianProfileFactory(status='PENDING', is_online=False)
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )

        assert response.status_code == 403

    def test_suspended_tech_returns_403(self):
        """Admin-suspended tech (is_active=False) cannot self-promote
        back to online. Mirrors the suspend admin action's invariant
        that is_active=False ↔ is_online=False — flipping is_online=True
        on a suspended row would create a contradiction."""
        tech = TechnicianProfileFactory(
            status='APPROVED',
            is_active=False,
            is_online=False,
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )

        assert response.status_code == 403
        # The refusal MUST NOT mutate the column.
        tech.refresh_from_db()
        assert tech.is_online is False
        assert tech.is_active is False

    def test_rejected_tech_returns_403(self):
        # rejection_reason satisfies the CHECK constraint
        # technicianprofile_rejected_requires_reason — REJECTED rows
        # must carry a non-empty reason.
        tech = TechnicianProfileFactory(
            status='REJECTED',
            is_online=False,
            rejection_reason='Demo rejection',
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': True}, format='json',
        )

        assert response.status_code == 403

    # -- Input validation --------------------------------------------------

    def test_missing_is_online_returns_400(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(self.url, data={}, format='json')

        assert response.status_code == 400

    def test_non_bool_is_online_returns_400(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url, data={'is_online': 'not-a-bool'}, format='json',
        )

        assert response.status_code == 400

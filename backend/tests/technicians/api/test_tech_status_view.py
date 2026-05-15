import pytest
from rest_framework.test import APIClient
from django.urls import reverse

from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db


class TestTechnicianStatusView:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('tech-status')

    def test_unauthenticated_returns_401(self):
        response = self.client.get(self.url)
        assert response.status_code == 401

    def test_pure_customer_returns_no_profile(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        assert response.json() == {
            "has_profile": False,
            "status": None,
            "status_display": None,
            "rejection_reason": None,
            "submitted_at": None,
        }

    def test_pending_tech_returns_pending_payload(self):
        tech = TechnicianProfileFactory(status='PENDING')
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        data = response.json()
        assert data["has_profile"] is True
        assert data["status"] == 'PENDING'
        assert data["status_display"] == 'Pending Approval'
        assert data["rejection_reason"] is None

    def test_approved_tech_returns_approved_payload(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        assert response.json()["status"] == 'APPROVED'

    def test_rejected_tech_returns_reason(self):
        tech = TechnicianProfileFactory(
            status='REJECTED',
            rejection_reason='CNIC image was illegible — please reupload.',
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == 'REJECTED'
        assert data["rejection_reason"] == 'CNIC image was illegible — please reupload.'

    def test_only_returns_status_for_authenticated_user(self):
        """SECURITY: caller B sees their own row, not caller A's. No IDOR via the OneToOne."""
        tech_a = TechnicianProfileFactory(status='APPROVED')
        tech_b = TechnicianProfileFactory(status='PENDING')

        self.client.force_authenticate(user=tech_b.user)
        response = self.client.get(self.url)

        assert response.json()["status"] == 'PENDING'

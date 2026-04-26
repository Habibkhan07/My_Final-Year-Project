import pytest
from rest_framework.test import APIClient
from django.urls import reverse
from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db

class TestTechnicianDashboardView:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('tech-dashboard')

    def test_dashboard_unauthenticated(self):
        """Ensure 401 Unauthorized for anonymous users."""
        response = self.client.get(self.url)
        assert response.status_code == 401

    def test_dashboard_not_technician(self):
        """Ensure 403 Forbidden for a logged-in user who is not a technician."""
        user = UserFactory()
        self.client.force_authenticate(user=user)
        
        response = self.client.get(self.url)
        assert response.status_code == 403
        data = response.json()
        assert data["code"] == "permission_denied"
        assert data["message"] == "User is not a registered technician."
        assert "user" in data["errors"]

    def test_dashboard_success(self, mocker):
        """Ensure 200 OK for a valid technician with correct data payload."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=2500.00,
            is_online=True
        )
        self.client.force_authenticate(user=tech.user)
        
        # Test without any jobs just to verify the basic JSON contract is met
        response = self.client.get(self.url)
        assert response.status_code == 200
        
        data = response.json()
        assert data["wallet_balance"] == 2500.00
        assert data["is_online"] is True
        assert "profile_picture" in data
        assert data["up_next_job"] is None
        assert data["later_today_jobs"] == []
        assert data["metrics"]["jobs_completed_today"] == 0
        assert data["metrics"]["cash_collected_today"] == 0.0

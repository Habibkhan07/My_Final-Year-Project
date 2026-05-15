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
            is_online=True,
            work_address_label='Gulberg, Lahore',
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
        assert "metrics" not in data
        # ``has_work_location`` + ``work_address_label`` are read by the
        # Flutter dashboard banner. Factory defaults provide non-null lat/lng,
        # so a tech created via the factory is always discoverable.
        assert data["has_work_location"] is True
        assert data["work_address_label"] == 'Gulberg, Lahore'

    def test_dashboard_reports_no_work_location_when_coords_null(self):
        """Tech with null base_latitude/_longitude must surface
        ``has_work_location: False`` so the FE banner can prompt them to fix
        the discovery hole their profile creates."""
        tech = TechnicianProfileFactory(
            base_latitude=None,
            base_longitude=None,
            work_address_label=None,
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        data = response.json()
        assert data["has_work_location"] is False
        assert data["work_address_label"] is None

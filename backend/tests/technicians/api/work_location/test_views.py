import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from technicians.models import TechnicianProfile
from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db


class TestTechnicianWorkLocationView:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('tech-work-location')

    # -- AuthN / 401 -------------------------------------------------------

    def test_unauthenticated_get_returns_401(self):
        assert self.client.get(self.url).status_code == 401

    def test_unauthenticated_patch_returns_401(self):
        response = self.client.patch(
            self.url,
            data={'latitude': 31.5, 'longitude': 74.3},
            format='json',
        )
        assert response.status_code == 401

    # -- GET ---------------------------------------------------------------

    def test_get_pure_customer_returns_has_profile_false(self):
        """Pure customer hits the endpoint — returns the no-profile shape so
        the FE router can branch without a 404 round-trip."""
        user = UserFactory()
        self.client.force_authenticate(user=user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        data = response.json()
        assert data['has_profile'] is False
        assert data['is_set'] is False
        assert data['latitude'] is None
        assert data['longitude'] is None
        assert data['max_travel_radius_km'] == 10
        # Strict-null contract — FE branches on null. DRF's allow_null=True
        # on CharField outputs JSON null for None on the wire.
        assert data['work_address_label'] is None

    def test_get_tech_with_location_returns_is_set_true(self):
        tech = TechnicianProfileFactory(
            base_latitude=31.5204,
            base_longitude=74.3587,
            max_travel_radius_km=15,
            work_address_label='Block 12, DHA Phase 4, Lahore',
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        data = response.json()
        assert data['has_profile'] is True
        assert data['is_set'] is True
        assert data['latitude'] == pytest.approx(31.5204)
        assert data['longitude'] == pytest.approx(74.3587)
        assert data['max_travel_radius_km'] == 15
        assert data['work_address_label'] == 'Block 12, DHA Phase 4, Lahore'

    def test_get_tech_with_null_coords_returns_is_set_false(self):
        """Newly-onboarded tech with null lat/lng — must return is_set=False
        so the FE banner stays visible."""
        tech = TechnicianProfileFactory(
            base_latitude=None,
            base_longitude=None,
            work_address_label=None,
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        data = response.json()
        assert data['has_profile'] is True
        assert data['is_set'] is False
        assert data['latitude'] is None
        assert data['longitude'] is None
        assert data['work_address_label'] is None

    # -- PATCH happy path --------------------------------------------------

    def test_patch_writes_location_and_returns_read_shape(self):
        tech = TechnicianProfileFactory(
            base_latitude=None,
            base_longitude=None,
            work_address_label=None,
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.patch(
            self.url,
            data={
                'latitude': 31.5204,
                'longitude': 74.3587,
                'max_travel_radius_km': 8,
                'work_address_label': 'Gulberg, Lahore',
            },
            format='json',
        )

        assert response.status_code == 200
        data = response.json()
        assert data['is_set'] is True
        assert data['latitude'] == pytest.approx(31.5204)
        assert data['longitude'] == pytest.approx(74.3587)
        assert data['max_travel_radius_km'] == 8
        assert data['work_address_label'] == 'Gulberg, Lahore'

        tech.refresh_from_db()
        assert tech.base_latitude == pytest.approx(31.5204)
        assert tech.base_longitude == pytest.approx(74.3587)
        assert tech.max_travel_radius_km == 8
        assert tech.work_address_label == 'Gulberg, Lahore'

    def test_patch_optional_radius_keeps_existing_value(self):
        """Omitting max_travel_radius_km must NOT clobber the existing value."""
        tech = TechnicianProfileFactory(max_travel_radius_km=20)
        self.client.force_authenticate(user=tech.user)

        response = self.client.patch(
            self.url,
            data={'latitude': 31.0, 'longitude': 74.0},
            format='json',
        )

        assert response.status_code == 200
        tech.refresh_from_db()
        assert tech.max_travel_radius_km == 20

    def test_patch_null_label_clears_label(self):
        tech = TechnicianProfileFactory(work_address_label='Old Label')
        self.client.force_authenticate(user=tech.user)

        response = self.client.patch(
            self.url,
            data={
                'latitude': 31.0,
                'longitude': 74.0,
                'work_address_label': None,
            },
            format='json',
        )

        assert response.status_code == 200
        tech.refresh_from_db()
        assert tech.work_address_label is None

    # -- PATCH validation envelopes ---------------------------------------

    def test_patch_missing_lat_returns_400_envelope(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.patch(
            self.url,
            data={'longitude': 74.0},
            format='json',
        )

        assert response.status_code == 400
        data = response.json()
        assert 'latitude' in data['errors']

    def test_patch_lat_out_of_range_returns_400(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.patch(
            self.url,
            data={'latitude': 200.0, 'longitude': 74.0},
            format='json',
        )

        assert response.status_code == 400
        data = response.json()
        assert 'latitude' in data['errors']

    def test_patch_lng_out_of_range_returns_400(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.patch(
            self.url,
            data={'latitude': 31.0, 'longitude': 250.0},
            format='json',
        )

        assert response.status_code == 400
        assert 'longitude' in response.json()['errors']

    def test_patch_radius_out_of_range_returns_400(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.patch(
            self.url,
            data={
                'latitude': 31.0,
                'longitude': 74.0,
                'max_travel_radius_km': 500,
            },
            format='json',
        )

        assert response.status_code == 400
        assert 'max_travel_radius_km' in response.json()['errors']

    # -- PATCH for pure customer -----------------------------------------

    def test_patch_pure_customer_returns_404(self):
        """Caller with no TechnicianProfile cannot PATCH a non-existent row."""
        user = UserFactory()
        self.client.force_authenticate(user=user)

        response = self.client.patch(
            self.url,
            data={'latitude': 31.0, 'longitude': 74.0},
            format='json',
        )

        assert response.status_code == 404

    # -- IDOR --------------------------------------------------------------

    def test_patch_does_not_affect_other_techs_row(self):
        """SECURITY: caller B's PATCH writes only their own profile, never A's."""
        tech_a = TechnicianProfileFactory(
            base_latitude=10.0, base_longitude=10.0,
        )
        tech_b = TechnicianProfileFactory(
            base_latitude=None, base_longitude=None,
        )

        self.client.force_authenticate(user=tech_b.user)
        response = self.client.patch(
            self.url,
            data={'latitude': 50.0, 'longitude': 50.0},
            format='json',
        )

        assert response.status_code == 200

        tech_a.refresh_from_db()
        tech_b.refresh_from_db()
        # B writes B's row.
        assert tech_b.base_latitude == pytest.approx(50.0)
        assert tech_b.base_longitude == pytest.approx(50.0)
        # A's row is untouched.
        assert tech_a.base_latitude == pytest.approx(10.0)
        assert tech_a.base_longitude == pytest.approx(10.0)

    # -- Rejected tech path ----------------------------------------------

    def test_rejected_tech_can_still_set_work_location(self):
        """A REJECTED tech may reapply; setting location during the rejected
        window is allowed by design (see service docstring)."""
        tech = TechnicianProfileFactory(
            status='REJECTED',
            rejection_reason='CNIC illegible',
            base_latitude=None,
            base_longitude=None,
        )
        self.client.force_authenticate(user=tech.user)

        response = self.client.patch(
            self.url,
            data={'latitude': 31.0, 'longitude': 74.0},
            format='json',
        )

        assert response.status_code == 200
        tech.refresh_from_db()
        assert tech.base_latitude == pytest.approx(31.0)

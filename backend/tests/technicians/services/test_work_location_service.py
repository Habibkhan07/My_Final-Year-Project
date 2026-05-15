import pytest
from rest_framework.exceptions import NotFound

from technicians.services.work_location_service import update_work_location
from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db


class TestUpdateWorkLocationService:
    def test_writes_lat_lng_radius_and_label(self):
        tech = TechnicianProfileFactory(
            base_latitude=None,
            base_longitude=None,
            max_travel_radius_km=10,
            work_address_label=None,
        )

        update_work_location(
            user=tech.user,
            validated_data={
                'latitude': 31.5204,
                'longitude': 74.3587,
                'max_travel_radius_km': 15,
                'work_address_label': 'Gulberg, Lahore',
            },
        )

        tech.refresh_from_db()
        assert tech.base_latitude == pytest.approx(31.5204)
        assert tech.base_longitude == pytest.approx(74.3587)
        assert tech.max_travel_radius_km == 15
        assert tech.work_address_label == 'Gulberg, Lahore'

    def test_omitted_radius_is_preserved(self):
        tech = TechnicianProfileFactory(max_travel_radius_km=25)

        update_work_location(
            user=tech.user,
            validated_data={'latitude': 31.0, 'longitude': 74.0},
        )

        tech.refresh_from_db()
        assert tech.max_travel_radius_km == 25

    def test_empty_label_is_normalised_to_null(self):
        """Empty-string label gets stored as None — UIs that show
        ``work_address_label`` should branch on null, not on truthy string."""
        tech = TechnicianProfileFactory(work_address_label='Old')

        update_work_location(
            user=tech.user,
            validated_data={
                'latitude': 31.0,
                'longitude': 74.0,
                'work_address_label': '',
            },
        )

        tech.refresh_from_db()
        assert tech.work_address_label is None

    def test_pure_customer_raises_notfound(self):
        user = UserFactory()

        with pytest.raises(NotFound):
            update_work_location(
                user=user,
                validated_data={'latitude': 31.0, 'longitude': 74.0},
            )

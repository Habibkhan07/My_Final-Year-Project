"""
Tests for POST /api/bookings/instant-book/
bookings/api/instant_book/views.py

Coverage:
  - 401 when unauthenticated
  - 400 for each missing required field (technician_id, address_id, scheduled_start, scheduled_end, price_amount)
  - 400 for malformed datetime
  - 400 for scheduled_end <= scheduled_start
  - 400 envelope structure matches contract (status, code, message, errors)
  - 400 out_of_service_area (correct code, correct HTTP status)
  - 400 invalid/missing address (opaque — same code whether absent or wrong user)
  - 404 for non-existent technician
  - 404 for PENDING technician
  - 409 slot_unavailable when a conflicting booking already exists
  - 201 happy path: response body is {"booking_id": <int>}
  - 201 verifies booking exists in DB with status CONFIRMED
"""
import datetime
import zoneinfo
import pytest
from rest_framework.test import APIClient
from django.urls import reverse

from bookings.models import JobBooking
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.customers import CustomerProfileFactory, SavedAddressFactory
from tests.factories.bookings import JobBookingFactory

pytestmark = pytest.mark.django_db

PKT = zoneinfo.ZoneInfo("Asia/Karachi")
URL = '/api/bookings/instant-book/'


def _pkt_iso(h: int, m: int = 0) -> str:
    """Return a PKT-aware ISO 8601 datetime string."""
    dt = datetime.datetime(2026, 4, 7, h, m, tzinfo=PKT)
    return dt.isoformat()


def _make_payload(tech, address, start_h=10, end_h=11):
    return {
        'technician_id': tech.id,
        'address_id': address.id,
        'scheduled_start': _pkt_iso(start_h),
        'scheduled_end': _pkt_iso(end_h),
        'price_amount': '1500.00',
        'price_context': 'AC Repair',
    }


class TestInstantBookView:

    def setup_method(self):
        self.client = APIClient()

    def _auth(self, user):
        self.client.force_authenticate(user=user)

    # ------------------------------------------------------------------
    # 401 — AUTHENTICATION
    # ------------------------------------------------------------------

    def test_401_when_unauthenticated(self):
        response = self.client.post(URL, {}, format='json')
        assert response.status_code == 401

    # ------------------------------------------------------------------
    # 400 — VALIDATION ERRORS
    # ------------------------------------------------------------------

    def test_400_missing_technician_id(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['technician_id']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'technician_id' in response.json()['errors']

    def test_400_missing_address_id(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['address_id']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'address_id' in response.json()['errors']

    def test_400_missing_scheduled_start(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['scheduled_start']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'scheduled_start' in response.json()['errors']

    def test_400_missing_scheduled_end(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['scheduled_end']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'scheduled_end' in response.json()['errors']

    def test_400_missing_price_amount(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['price_amount']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'price_amount' in response.json()['errors']

    def test_400_malformed_scheduled_start(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        payload['scheduled_start'] = 'not-a-date'

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'scheduled_start' in response.json()['errors']

    def test_400_scheduled_end_before_start(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        payload['scheduled_end'] = _pkt_iso(9)    # before start (10:00)
        payload['scheduled_start'] = _pkt_iso(10)

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'scheduled_end' in response.json()['errors']

    def test_400_scheduled_end_equal_to_start(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        payload['scheduled_start'] = _pkt_iso(10)
        payload['scheduled_end'] = _pkt_iso(10)   # equal → not strictly after

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400

    def test_400_envelope_matches_contract(self):
        """Standard envelope: status, code, message, errors."""
        profile = CustomerProfileFactory()
        self._auth(profile.user)

        response = self.client.post(URL, {}, format='json')
        data = response.json()
        assert response.status_code == 400
        assert set(data.keys()) >= {'status', 'code', 'message', 'errors'}
        assert data['code'] == 'validation_error'
        assert data['status'] == 400

    # ------------------------------------------------------------------
    # 400 — BUSINESS RULE ERRORS
    # ------------------------------------------------------------------

    def test_400_invalid_address(self):
        """Non-existent address_id → opaque 400, code validation_error."""
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)

        payload = {
            'technician_id': tech.id,
            'address_id': 999999,
            'scheduled_start': _pkt_iso(10),
            'scheduled_end': _pkt_iso(11),
            'price_amount': '1500.00',
        }
        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        data = response.json()
        assert data['code'] == 'validation_error'
        assert 'address_id' in data['errors']

    def test_400_address_belonging_to_other_user_is_opaque(self):
        """
        Address exists but belongs to another customer — must return the same
        400 as a non-existent address (IDOR: caller can't distinguish the two).
        """
        other_profile = CustomerProfileFactory()
        other_address = SavedAddressFactory(customer=other_profile)

        attacker_profile = CustomerProfileFactory()
        self._auth(attacker_profile.user)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)

        payload = {
            'technician_id': tech.id,
            'address_id': other_address.id,
            'scheduled_start': _pkt_iso(10),
            'scheduled_end': _pkt_iso(11),
            'price_amount': '1500.00',
        }
        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert response.json()['code'] == 'validation_error'

    def test_400_out_of_service_area(self):
        """Lahore technician, Karachi address → out_of_service_area."""
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,   # Lahore
            max_travel_radius_km=10,
        )
        far_address = SavedAddressFactory(
            customer=profile,
            latitude=24.8607, longitude=67.0011,             # Karachi
        )

        response = self.client.post(URL, _make_payload(tech, far_address), format='json')
        assert response.status_code == 400
        data = response.json()
        assert data['code'] == 'out_of_service_area'
        assert data['status'] == 400

    # ------------------------------------------------------------------
    # 404 — TECHNICIAN NOT FOUND
    # ------------------------------------------------------------------

    def test_404_nonexistent_technician(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = SavedAddressFactory(customer=profile)

        payload = {
            'technician_id': 999999,
            'address_id': address.id,
            'scheduled_start': _pkt_iso(10),
            'scheduled_end': _pkt_iso(11),
            'price_amount': '1500.00',
        }
        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 404
        assert response.json()['code'] == 'not_found'

    def test_404_pending_technician(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(status='PENDING')
        address = SavedAddressFactory(customer=profile)

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 404

    # ------------------------------------------------------------------
    # 409 — SLOT UNAVAILABLE
    # ------------------------------------------------------------------

    def test_409_slot_unavailable_when_overlap_exists(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        address = SavedAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        # Pre-existing CONFIRMED booking occupies the exact same slot
        JobBookingFactory(
            technician=tech,
            scheduled_start=datetime.datetime(2026, 4, 7, 10, 0, tzinfo=PKT),
            scheduled_end=datetime.datetime(2026, 4, 7, 11, 0, tzinfo=PKT),
            status=JobBooking.STATUS_CONFIRMED,
        )

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 409
        data = response.json()
        assert data['code'] == 'slot_unavailable'
        assert data['status'] == 409

    # ------------------------------------------------------------------
    # 201 — HAPPY PATH
    # ------------------------------------------------------------------

    def test_201_returns_booking_id(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        address = SavedAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 201
        data = response.json()
        assert 'booking_id' in data
        assert isinstance(data['booking_id'], int)

    def test_201_booking_confirmed_in_db(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        address = SavedAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 201

        booking_id = response.json()['booking_id']
        booking = JobBooking.objects.get(pk=booking_id)
        assert booking.status == JobBooking.STATUS_CONFIRMED
        assert booking.customer == profile.user
        assert booking.technician == tech
        assert booking.address == address

    def test_201_price_context_optional(self):
        """price_context is optional — booking succeeds without it."""
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        address = SavedAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        payload = _make_payload(tech, address)
        del payload['price_context']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 201

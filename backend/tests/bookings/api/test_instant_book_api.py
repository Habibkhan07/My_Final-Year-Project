"""
Tests for POST /api/bookings/instant-book/
bookings/api/instant_book/views.py

Coverage:
  - 401 when unauthenticated
  - 400 for each missing required field (technician_id, address_id, scheduled_start, scheduled_end, service_id)
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
  - 201 verifies persisted price_amount is the server-derived figure (no client value on the wire)
"""
import datetime
import decimal
import zoneinfo
import pytest
from rest_framework.test import APIClient
from django.urls import reverse

from bookings.models import JobBooking
from tests.factories.technicians import TechnicianProfileFactory, TechnicianSkillFactory
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory
from tests.factories.bookings import JobBookingFactory
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory

pytestmark = pytest.mark.django_db

PKT = zoneinfo.ZoneInfo("Asia/Karachi")
URL = '/api/bookings/instant-book/'


def _pkt_iso(h: int, m: int = 0) -> str:
    """Return a PKT-aware ISO 8601 datetime string."""
    dt = datetime.datetime(2026, 4, 7, h, m, tzinfo=PKT)
    return dt.isoformat()


def _make_payload(tech, address, start_h=10, end_h=11, service=None):
    """
    Default payload: an inspection-fee booking (Scenario C). The server
    derives ``price_amount`` from the resolved catalog references, so the
    payload doesn't carry a price field at all.
    """
    if service is None:
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
    return {
        'technician_id': tech.id,
        'address_id': address.id,
        'service_id': service.id,
        'scheduled_start': _pkt_iso(start_h),
        'scheduled_end': _pkt_iso(end_h),
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
        address = CustomerAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['technician_id']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'technician_id' in response.json()['errors']

    def test_400_missing_address_id(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = CustomerAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['address_id']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'address_id' in response.json()['errors']

    def test_400_missing_scheduled_start(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = CustomerAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['scheduled_start']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'scheduled_start' in response.json()['errors']

    def test_400_missing_scheduled_end(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = CustomerAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['scheduled_end']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'scheduled_end' in response.json()['errors']

    def test_400_missing_service_id(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = CustomerAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        del payload['service_id']

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'service_id' in response.json()['errors']

    def test_400_malformed_scheduled_start(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = CustomerAddressFactory(customer=profile)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        payload = _make_payload(tech, address)
        payload['scheduled_start'] = 'not-a-date'

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        assert 'scheduled_start' in response.json()['errors']

    def test_400_scheduled_end_before_start(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = CustomerAddressFactory(customer=profile)
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
        address = CustomerAddressFactory(customer=profile)
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
            'service_id': ServiceFactory().id,
            'scheduled_start': _pkt_iso(10),
            'scheduled_end': _pkt_iso(11),
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
        other_address = CustomerAddressFactory(customer=other_profile)

        attacker_profile = CustomerProfileFactory()
        self._auth(attacker_profile.user)
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)

        payload = {
            'technician_id': tech.id,
            'address_id': other_address.id,
            'service_id': ServiceFactory().id,
            'scheduled_start': _pkt_iso(10),
            'scheduled_end': _pkt_iso(11),
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
        far_address = CustomerAddressFactory(
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
        address = CustomerAddressFactory(customer=profile)

        payload = {
            'technician_id': 999999,
            'address_id': address.id,
            'service_id': ServiceFactory().id,
            'scheduled_start': _pkt_iso(10),
            'scheduled_end': _pkt_iso(11),
        }
        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 404
        assert response.json()['code'] == 'not_found'

    def test_404_pending_technician(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(status='PENDING')
        address = CustomerAddressFactory(customer=profile)

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
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

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
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 201
        data = response.json()
        assert 'booking_id' in data
        assert isinstance(data['booking_id'], int)

    def test_201_booking_persisted_awaiting_in_db(self):
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 201

        booking_id = response.json()['booking_id']
        booking = JobBooking.objects.get(pk=booking_id)
        # Newly created bookings sit in AWAITING until the dispatched
        # technician accepts (separate sprint). Flag #1 closure.
        assert booking.status == JobBooking.STATUS_AWAITING_TECH_ACCEPT
        assert booking.customer == profile.user
        assert booking.technician == tech
        assert booking.address == address

    # ------------------------------------------------------------------
    # 400 — WRITE-PATH CATALOG / PROMO / PRICE VALIDATION
    # ------------------------------------------------------------------

    def _approved_tech_and_owned_address(self):
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = CustomerAddressFactory(
            customer=profile, latitude=31.5204, longitude=74.3587,
        )
        return tech, profile, address

    def test_400_inconsistent_sub_service_parent(self):
        tech, _, address = self._approved_tech_and_owned_address()
        service_a = ServiceFactory()
        service_b = ServiceFactory()
        sub = SubServiceFactory(service=service_b, is_fixed_price=False)

        payload = _make_payload(tech, address, service=service_a)
        payload['sub_service_id'] = sub.id

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        data = response.json()
        assert data['code'] == 'validation_error'
        assert 'sub_service_id' in data['errors']

    def test_400_promo_firewall_on_fixed_gig(self):
        tech, _, address = self._approved_tech_and_owned_address()
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=True, base_price=decimal.Decimal('1500.00'),
        )
        promo = PromotionFactory(target_service=service)

        payload = _make_payload(tech, address, service=service)
        payload['sub_service_id'] = sub.id
        payload['promotion_id'] = promo.id

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 400
        data = response.json()
        assert data['code'] == 'validation_error'
        assert 'promotion_id' in data['errors']

    def test_201_labor_gig_persists_subservice_base_price(self):
        """The persisted ``price_amount`` is the catalog's
        ``SubService.base_price`` — the platform-set figure that
        replaced per-tech ``labor_rate`` in the 2026-05-17 refactor.
        No price field is on the wire.
        """
        tech, _, address = self._approved_tech_and_owned_address()
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=False,
            base_price=decimal.Decimal('1200.00'),
        )
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        payload = _make_payload(tech, address, service=service)
        payload['sub_service_id'] = sub.id

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 201

        booking = JobBooking.objects.get(pk=response.json()['booking_id'])
        assert booking.sub_service == sub
        assert booking.price_amount == decimal.Decimal('1200.00')
        assert booking.price_context == 'Labor Fee'

    # ------------------------------------------------------------------
    # 201 — HAPPY PATH (CONTINUED)
    # ------------------------------------------------------------------

    def test_201_price_context_is_server_derived(self):
        """
        price_context is no longer an ingress field — the server derives the
        customer-receipt label from the resolved catalog references. A
        Scenario-C inspection booking should produce ``Inspection Fee``.
        """
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        # Even if a client sends price_context, the serializer ignores it.
        payload = _make_payload(tech, address)
        payload['price_context'] = 'CLIENT-SUPPLIED-IGNORED'

        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 201

        booking = JobBooking.objects.get(pk=response.json()['booking_id'])
        assert booking.price_context == 'Inspection Fee'


# ======================================================================
# Realtime side-effect coverage at the API boundary.
#
# The service-layer tests in test_instant_book_service.py already prove the
# on_commit semantics. These tests prove the same contract holds when the
# request flows through the DRF view: a 201 fans the dispatcher exactly
# once, a 4xx fans it zero times. Use transaction=True so on_commit fires.
# ======================================================================

@pytest.mark.django_db(transaction=True)
class TestInstantBookViewDispatchSideEffect:

    def setup_method(self):
        self.client = APIClient()

    def _auth(self, user):
        self.client.force_authenticate(user=user)

    def test_201_dispatches_once(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        address = CustomerAddressFactory(
            customer=profile, latitude=31.5204, longitude=74.3587,
        )

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 201
        assert dispatch.call_count == 1

    def test_4xx_validation_error_does_not_dispatch(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        profile = CustomerProfileFactory()
        self._auth(profile.user)

        # Empty body → DRF validation error → 400, no dispatch.
        response = self.client.post(URL, {}, format='json')
        assert response.status_code == 400
        assert dispatch.call_count == 0

    def test_4xx_out_of_service_area_does_not_dispatch(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,    # Lahore
            max_travel_radius_km=10,
        )
        address = CustomerAddressFactory(
            customer=profile, latitude=24.8607, longitude=67.0011,  # Karachi
        )

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 400
        assert response.json()['code'] == 'out_of_service_area'
        assert dispatch.call_count == 0

    def test_4xx_slot_unavailable_does_not_dispatch(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        address = CustomerAddressFactory(
            customer=profile, latitude=31.5204, longitude=74.3587,
        )
        # Pre-seed an exactly-conflicting CONFIRMED booking.
        JobBookingFactory(
            technician=tech,
            scheduled_start=datetime.datetime(2026, 4, 7, 10, tzinfo=PKT),
            scheduled_end=datetime.datetime(2026, 4, 7, 11, tzinfo=PKT),
            status=JobBooking.STATUS_CONFIRMED,
        )

        response = self.client.post(URL, _make_payload(tech, address), format='json')
        assert response.status_code == 409
        assert dispatch.call_count == 0

    def test_404_technician_not_found_does_not_dispatch(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        profile = CustomerProfileFactory()
        self._auth(profile.user)
        address = CustomerAddressFactory(customer=profile)

        payload = {
            'technician_id': 999_999,
            'address_id': address.id,
            'service_id': ServiceFactory().id,
            'scheduled_start': _pkt_iso(10),
            'scheduled_end': _pkt_iso(11),
        }
        response = self.client.post(URL, payload, format='json')
        assert response.status_code == 404
        assert dispatch.call_count == 0

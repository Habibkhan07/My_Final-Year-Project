"""
Tests for GET /api/customers/technicians/{pk}/availability/
customers/api/availability/views.py

Coverage:
  - 200 with correct slot shape (4 keys: time_string, iso_start, iso_end, period)
  - 200 empty array when technician has no schedule for the requested day
  - 400 when date param is missing
  - 400 when date param is malformed (not YYYY-MM-DD)
  - 404 for PENDING technician
  - 404 for REJECTED technician
  - 404 for non-existent technician ID
  - Booking conflict removes the affected slot; adjacent slot survives
  - Garbage service_id / sub_service_id handled gracefully (no 500)
  - 404 error envelope matches standard contract
  - 400 error envelope matches standard contract
"""
import datetime
import zoneinfo
import pytest
from rest_framework.test import APIClient
from django.urls import reverse

from bookings.models import JobBooking
from tests.factories.technicians import (
    TechnicianProfileFactory,
    TechnicianScheduleFactory,
)
from tests.factories.bookings import JobBookingFactory

pytestmark = pytest.mark.django_db

PKT = zoneinfo.ZoneInfo("Asia/Karachi")
DATE_STR = '2026-04-06'       # Monday
DATE_OBJ = datetime.date(2026, 4, 6)


def _pkt(h: int, m: int = 0) -> datetime.datetime:
    return datetime.datetime(2026, 4, 6, h, m, tzinfo=PKT)


class TestTechnicianAvailabilityView:

    def setup_method(self):
        self.client = APIClient()

    def _url(self, pk):
        return reverse('technician-availability', kwargs={'pk': pk})

    # ------------------------------------------------------------------
    # 400 — VALIDATION ERRORS
    # ------------------------------------------------------------------

    def test_400_when_date_missing(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(self._url(tech.id))
        assert response.status_code == 400
        data = response.json()
        assert data['code'] == 'validation_error'
        assert data['status'] == 400
        assert 'date' in data['errors']

    def test_400_when_date_malformed(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(self._url(tech.id), {'date': '07-04-2026'})
        assert response.status_code == 400
        data = response.json()
        assert data['code'] == 'validation_error'
        assert 'date' in data['errors']

    def test_400_envelope_matches_contract(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        data = self.client.get(self._url(tech.id)).json()
        assert set(data.keys()) >= {'status', 'code', 'message', 'errors'}

    # ------------------------------------------------------------------
    # 404 — ACCESS CONTROL
    # ------------------------------------------------------------------

    def test_404_for_nonexistent_id(self):
        response = self.client.get(self._url(999999), {'date': DATE_STR})
        assert response.status_code == 404
        data = response.json()
        assert data['code'] == 'not_found'
        assert data['status'] == 404
        assert data['errors'] == {}

    def test_404_for_pending_technician(self):
        tech = TechnicianProfileFactory(status='PENDING')
        response = self.client.get(self._url(tech.id), {'date': DATE_STR})
        assert response.status_code == 404

    def test_404_for_rejected_technician(self):
        tech = TechnicianProfileFactory(status='REJECTED')
        response = self.client.get(self._url(tech.id), {'date': DATE_STR})
        assert response.status_code == 404

    # ------------------------------------------------------------------
    # 200 — HAPPY PATH
    # ------------------------------------------------------------------

    def test_200_empty_when_no_schedule(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(self._url(tech.id), {'date': DATE_STR})
        assert response.status_code == 200
        assert response.json() == []

    def test_200_slot_shape(self):
        """Every slot must have exactly: time_string, iso_start, iso_end, period."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=DATE_OBJ.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(10, 0),
        )
        response = self.client.get(self._url(tech.id), {'date': DATE_STR})
        assert response.status_code == 200
        slots = response.json()
        assert len(slots) == 1
        assert set(slots[0].keys()) == {'time_string', 'iso_start', 'iso_end', 'period'}

    def test_200_slot_values(self):
        """Verify the exact values for a 9:00 AM slot on a 9–10 schedule."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=DATE_OBJ.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(10, 0),
        )
        slots = self.client.get(self._url(tech.id), {'date': DATE_STR}).json()
        slot = slots[0]
        assert slot['time_string'] == '9:00 AM'
        assert slot['period'] == 'AM'
        # iso_start must be 9:00 PKT
        start = datetime.datetime.fromisoformat(slot['iso_start'])
        assert start.hour == 9
        assert start.utcoffset() == datetime.timedelta(hours=5)

    def test_200_multiple_slots_returned(self):
        """9:00–12:00 → 3 slots (9:00, 10:00, 11:00)."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=DATE_OBJ.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(12, 0),
        )
        slots = self.client.get(self._url(tech.id), {'date': DATE_STR}).json()
        assert len(slots) == 3

    # ------------------------------------------------------------------
    # CONFLICT FILTER VIA API
    # ------------------------------------------------------------------

    def test_confirmed_booking_removes_slot(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=DATE_OBJ.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(12, 0),
        )
        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(10, 0),
            scheduled_end=_pkt(11, 0),
            status=JobBooking.STATUS_CONFIRMED,
        )
        slots = self.client.get(self._url(tech.id), {'date': DATE_STR}).json()
        times = [s['time_string'] for s in slots]
        assert '10:00 AM' not in times
        assert '9:00 AM' in times
        assert '11:00 AM' in times

    # ------------------------------------------------------------------
    # ROBUSTNESS — GARBAGE INPUT
    # ------------------------------------------------------------------

    def test_garbage_service_id_does_not_crash(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(
            self._url(tech.id), {'date': DATE_STR, 'service_id': 'DROP_TABLE'}
        )
        assert response.status_code == 200

    def test_nonexistent_service_id_falls_back_gracefully(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(
            self._url(tech.id), {'date': DATE_STR, 'service_id': 999999}
        )
        assert response.status_code == 200  # falls back to Scenario C / 60-min default

    def test_garbage_sub_service_id_does_not_crash(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(
            self._url(tech.id), {'date': DATE_STR, 'sub_service_id': 'abc'}
        )
        assert response.status_code == 200

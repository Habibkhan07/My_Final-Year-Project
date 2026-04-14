"""
Tests for technicians/selectors/availability_selector.py
get_technician_availability()

Coverage:
  - Happy path: returns slots between schedule start and end
  - No schedule for day → empty list
  - is_working=False → empty list
  - End-of-day truncation: slots that overrun end_time are dropped
  - Booking conflict removes the overlapping slot
  - Non-overlapping booking does not remove the slot
  - Scenario A: sub_service_id → SubService.estimated_duration_minutes drives clipping
  - Scenario A fallback: estimated_duration_minutes=None → inherits Service.default_duration_minutes
  - Scenario B: service_id only → Service.default_duration_minutes
  - Scenario C: neither → primary service duration (most skills); fallback to 60 if no skills
  - Invalid tech_id raises TechnicianProfile.DoesNotExist
  - PENDING tech raises TechnicianProfile.DoesNotExist
"""
import datetime
import zoneinfo
import pytest

from technicians.models import TechnicianProfile
from technicians.selectors.availability_selector import get_technician_availability
from tests.factories.technicians import (
    TechnicianProfileFactory,
    TechnicianScheduleFactory,
    TechnicianSkillFactory,
)
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.bookings import JobBookingFactory
from bookings.models import JobBooking

pytestmark = pytest.mark.django_db

PKT = zoneinfo.ZoneInfo("Asia/Karachi")
TODAY = datetime.date(2026, 4, 6)   # Monday (weekday=0)


def _pkt(h: int, m: int = 0) -> datetime.datetime:
    """Build a PKT-aware datetime on TODAY at HH:MM."""
    return datetime.datetime(2026, 4, 6, h, m, tzinfo=PKT)


class TestGetTechnicianAvailability:

    # ------------------------------------------------------------------
    # HAPPY PATH
    # ------------------------------------------------------------------

    def test_returns_slots_within_schedule(self):
        """9 AM–11 AM schedule, 60-min job → exactly 2 slots: 9:00 and 10:00."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(11, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert len(slots) == 2
        assert slots[0]['time_string'] == '9:00 AM'
        assert slots[1]['time_string'] == '10:00 AM'

    def test_slot_shape_is_correct(self):
        """Each slot has exactly the 4 required keys with correct types."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(10, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert len(slots) == 1
        slot = slots[0]
        assert set(slot.keys()) == {'time_string', 'iso_start', 'iso_end', 'period'}
        assert slot['period'] in ('AM', 'PM')
        # iso_start and iso_end must be parseable datetimes
        start = datetime.datetime.fromisoformat(slot['iso_start'])
        end = datetime.datetime.fromisoformat(slot['iso_end'])
        assert end > start

    def test_iso_datetimes_are_pkt(self):
        """iso_start and iso_end must carry UTC+5 offset."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(10, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        start = datetime.datetime.fromisoformat(slots[0]['iso_start'])
        assert start.utcoffset() == datetime.timedelta(hours=5)

    def test_am_and_pm_periods(self):
        """Slots before noon get 'AM', at noon and after get 'PM'."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(11, 0),
            end_time=datetime.time(13, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert slots[0]['period'] == 'AM'  # 11:00 AM
        assert slots[1]['period'] == 'PM'  # 12:00 PM

    # ------------------------------------------------------------------
    # EMPTY SCHEDULE CASES
    # ------------------------------------------------------------------

    def test_no_schedule_returns_empty(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        # No TechnicianSchedule created
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert slots == []

    def test_is_working_false_returns_empty(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(17, 0),
            is_working=False,
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert slots == []

    # ------------------------------------------------------------------
    # END-OF-DAY TRUNCATION
    # ------------------------------------------------------------------

    def test_slot_overrunning_end_time_is_dropped(self):
        """
        9:00–9:30 schedule with 60-min job → 9:00 slot needs to end at 10:00
        which overruns end_time (9:30). Must return 0 slots.
        """
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(9, 30),  # only 30 min window — too short for 60-min job
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert slots == []

    def test_last_valid_slot_exactly_fills_window(self):
        """
        9:00–11:00 → slots at 9:00 (ends 10:00) and 10:00 (ends 11:00 exactly).
        11:00 slot (ends 12:00) must NOT appear.
        """
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(11, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert len(slots) == 2
        assert slots[-1]['time_string'] == '10:00 AM'

    # ------------------------------------------------------------------
    # CONFLICT FILTER
    # ------------------------------------------------------------------

    def test_booking_conflict_removes_slot(self):
        """A CONFIRMED booking at 10:00–11:00 removes the 10:00 slot."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(12, 0),
        )
        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(10, 0),
            scheduled_end=_pkt(11, 0),
            status=JobBooking.STATUS_CONFIRMED,
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        times = [s['time_string'] for s in slots]
        assert '10:00 AM' not in times
        assert '9:00 AM' in times
        assert '11:00 AM' in times

    def test_pending_booking_also_blocks_slot(self):
        """
        PENDING bookings must block the overlapping slot.
        Schedule 9:00–11:00 → slots at 9:00 and 10:00.
        Booking: 9:00–10:00 (PENDING) → 9:00 slot is blocked.
        10:00 slot starts exactly when the booking ends (non-overlapping) → survives.
        """
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(11, 0),
        )
        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(9, 0),
            scheduled_end=_pkt(10, 0),
            status=JobBooking.STATUS_PENDING,
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        times = [s['time_string'] for s in slots]
        assert '9:00 AM' not in times   # blocked by the PENDING booking
        assert '10:00 AM' in times      # starts at booking end — non-overlapping, survives

    def test_cancelled_booking_does_not_block_slot(self):
        """CANCELLED/REJECTED bookings must NOT remove any slot."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(11, 0),
        )
        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(9, 0),
            scheduled_end=_pkt(10, 0),
            status=JobBooking.STATUS_CANCELLED,
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert len(slots) == 2  # both slots survive

    def test_non_overlapping_booking_leaves_slot_intact(self):
        """A booking on a completely different day must not affect today's slots."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(11, 0),
        )
        tomorrow = _pkt(9, 0) + datetime.timedelta(days=1)
        JobBookingFactory(
            technician=tech,
            scheduled_start=tomorrow,
            scheduled_end=tomorrow + datetime.timedelta(hours=1),
            status=JobBooking.STATUS_CONFIRMED,
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert len(slots) == 2

    # ------------------------------------------------------------------
    # DURATION RESOLUTION — SCENARIO A/B/C
    # ------------------------------------------------------------------

    def test_scenario_a_uses_subservice_estimated_duration(self):
        """
        sub_service_id with estimated_duration_minutes=120 (2 hours) on a 3-hour window
        → slots at 9:00 and 10:00 only (11:00 would overrun 12:00 end_time,
        but 10:00 ends at 12:00 exactly — that's valid, so 2 slots).
        Wait: 9:00–12:00 = 3h. 120-min job.
        Slot 9:00→11:00 ✓, Slot 10:00→12:00 ✓, Slot 11:00→13:00 ✗ → 2 slots.
        """
        service = ServiceFactory(default_duration_minutes=60)
        sub = SubServiceFactory(service=service, estimated_duration_minutes=120)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(12, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY, sub_service_id=sub.id)
        assert len(slots) == 2
        assert slots[0]['time_string'] == '9:00 AM'
        assert slots[1]['time_string'] == '10:00 AM'

    def test_scenario_a_inherits_service_duration_when_subservice_is_null(self):
        """estimated_duration_minutes=None → falls back to parent Service.default_duration_minutes."""
        service = ServiceFactory(default_duration_minutes=60)
        sub = SubServiceFactory(service=service, estimated_duration_minutes=None)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(10, 0),  # exactly 60 min → 1 slot
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY, sub_service_id=sub.id)
        assert len(slots) == 1

    def test_scenario_b_uses_service_duration(self):
        """service_id only → Service.default_duration_minutes=120. 3-hour window → 2 slots."""
        service = ServiceFactory(default_duration_minutes=120)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(12, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY, service_id=service.id)
        assert len(slots) == 2

    def test_scenario_c_uses_primary_service_duration(self):
        """
        Neither param → primary service = service with most skills.
        Service A: 2 skills (default 90 min). Service B: 1 skill (default 60 min).
        Primary = A → 90-min job. On a 3-hour window → 2 slots (9:00→10:30, 10:00→11:30).
        """
        service_a = ServiceFactory(default_duration_minutes=90)
        service_b = ServiceFactory(default_duration_minutes=60)
        sub_a1 = SubServiceFactory(service=service_a)
        sub_a2 = SubServiceFactory(service=service_a)
        sub_b  = SubServiceFactory(service=service_b)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub_a1)
        TechnicianSkillFactory(technician=tech, sub_service=sub_a2)
        TechnicianSkillFactory(technician=tech, sub_service=sub_b)
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(12, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        # 90-min job: 9:00→10:30 ✓, 10:00→11:30 ✓, 11:00→12:30 ✗ → 2 slots
        assert len(slots) == 2

    def test_scenario_c_falls_back_to_60_when_no_skills(self):
        """No skills at all → 60-min default. 2-hour window → 2 slots."""
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianScheduleFactory(
            technician=tech,
            day_of_week=TODAY.weekday(),
            start_time=datetime.time(9, 0),
            end_time=datetime.time(11, 0),
        )
        slots = get_technician_availability(tech_id=tech.id, date_obj=TODAY)
        assert len(slots) == 2

    # ------------------------------------------------------------------
    # STATUS GUARD
    # ------------------------------------------------------------------

    def test_raises_for_pending_technician(self):
        tech = TechnicianProfileFactory(status='PENDING')
        with pytest.raises(TechnicianProfile.DoesNotExist):
            get_technician_availability(tech_id=tech.id, date_obj=TODAY)

    def test_raises_for_nonexistent_id(self):
        with pytest.raises(TechnicianProfile.DoesNotExist):
            get_technician_availability(tech_id=999999, date_obj=TODAY)

"""
Selector: get_technician_availability

Answers the question: "What 1-hour slots can a customer book with tech X on date Y,
given the intended job type?"

Inputs
------
tech_id         : int   — TechnicianProfile PK (must be APPROVED)
date_obj        : date  — the calendar day being queried
service_id      : int?  — parent service category (Scenario B)
sub_service_id  : int?  — specific gig (Scenario A)

Duration resolution (mutually exclusive, priority order)
---------------------------------------------------------
A  sub_service_id supplied → SubService.estimated_duration_minutes
                             (falls back to parent Service.default_duration_minutes if null)
B  service_id only          → Service.default_duration_minutes
C  neither supplied         → primary_service of this technician (service with most skills);
                             uses its default_duration_minutes. Defaults to 60 if no skills.

Algorithm
---------
1. Resolve job_duration_minutes via A/B/C above.
2. Fetch TechnicianSchedule for date_obj.weekday(). Return [] if missing or is_working=False.
3. Generate candidate 1-hour slots from work_start to work_end - job_duration (step = 60 min).
4. Load PENDING/CONFIRMED JobBookings for this tech on that date.
5. Drop any candidate whose [slot_start, slot_end) overlaps a booking window.
6. Return formatted slot list in PKT (UTC+5).
"""
from __future__ import annotations

import datetime
import zoneinfo
from typing import Optional

from django.db.models import Count

from catalog.models import Service, SubService
from technicians.models import TechnicianProfile, TechnicianSchedule

PKT = zoneinfo.ZoneInfo("Asia/Karachi")   # UTC+5, no DST
SLOT_INTERVAL_MINUTES = 60               # 1-hour slots act as a natural travel buffer


def _resolve_duration(
    tech_id: int,
    sub_service_id: Optional[int],
    service_id: Optional[int],
) -> int:
    """
    Return job_duration_minutes for the given context.
    Never raises — always returns a positive integer.
    """
    # --- Scenario A: specific gig ---
    if sub_service_id is not None:
        try:
            sub = SubService.objects.select_related('service').get(pk=sub_service_id)
            return sub.estimated_duration_minutes or sub.service.default_duration_minutes
        except SubService.DoesNotExist:
            pass  # fall through to Scenario C default

    # --- Scenario B: parent service category ---
    if service_id is not None:
        try:
            svc = Service.objects.get(pk=service_id)
            return svc.default_duration_minutes
        except Service.DoesNotExist:
            pass  # fall through to Scenario C default

    # --- Scenario C: technician's primary service ---
    primary = (
        TechnicianProfile.objects
        .filter(pk=tech_id)
        .values('skills__service')
        .annotate(skill_count=Count('skills'))
        .order_by('-skill_count', 'skills__service')  # tie-break: lowest service id
        .first()
    )
    if primary and primary['skills__service']:
        try:
            svc = Service.objects.get(pk=primary['skills__service'])
            return svc.default_duration_minutes
        except Service.DoesNotExist:
            pass

    return 60  # ultimate fallback


def _generate_slots(
    date_obj: datetime.date,
    start_time: datetime.time,
    end_time: datetime.time,
    job_duration_minutes: int,
) -> list[dict]:
    """
    Generate every candidate slot on date_obj between start_time and end_time.
    A slot is valid only if slot_end <= work_end_time (no overrun).
    All datetimes are PKT-aware.
    """
    slots: list[dict] = []
    job_delta = datetime.timedelta(minutes=job_duration_minutes)
    step = datetime.timedelta(minutes=SLOT_INTERVAL_MINUTES)

    # Build PKT-aware boundary datetimes
    work_start = datetime.datetime.combine(date_obj, start_time, tzinfo=PKT)
    work_end   = datetime.datetime.combine(date_obj, end_time,   tzinfo=PKT)

    current = work_start
    while current + job_delta <= work_end:
        slot_start = current
        slot_end   = current + job_delta
        slots.append({
            'time_string': slot_start.strftime('%-I:%M %p'),   # e.g. "9:00 AM"
            'iso_start':   slot_start.isoformat(),
            'iso_end':     slot_end.isoformat(),
            'period':      slot_start.strftime('%p'),           # "AM" or "PM"
        })
        current += step

    return slots


def get_technician_availability(
    tech_id: int,
    date_obj: datetime.date,
    sub_service_id: Optional[int] = None,
    service_id: Optional[int] = None,
) -> list[dict]:
    """
    Return the list of bookable 1-hour slots for `tech_id` on `date_obj`.
    Raises TechnicianProfile.DoesNotExist if the tech is not APPROVED.
    """
    # SECURITY: only APPROVED technicians expose availability
    TechnicianProfile.objects.filter(status='APPROVED').get(pk=tech_id)

    # --- Step 1: Resolve job duration ---
    job_duration = _resolve_duration(tech_id, sub_service_id, service_id)

    # --- Step 2: Get working hours for that weekday ---
    try:
        schedule = TechnicianSchedule.objects.get(
            technician_id=tech_id,
            day_of_week=date_obj.weekday(),
        )
    except TechnicianSchedule.DoesNotExist:
        return []  # technician has not set a schedule for this day

    if not schedule.is_working:
        return []

    # --- Step 3: Generate candidate slots ---
    candidates = _generate_slots(
        date_obj, schedule.start_time, schedule.end_time, job_duration
    )

    if not candidates:
        return []

    # --- Step 4: Fetch conflicts ---
    # Lazy import avoids circular dependency (bookings → technicians)
    from bookings.models import JobBooking

    # Convert date boundaries to UTC for DB query (USE_TZ=True stores in UTC)
    day_start_pkt = datetime.datetime.combine(date_obj, datetime.time.min, tzinfo=PKT)
    day_end_pkt   = datetime.datetime.combine(date_obj, datetime.time.max, tzinfo=PKT)

    conflicts = list(
        JobBooking.objects.filter(
            technician_id=tech_id,
            scheduled_start__gte=day_start_pkt,
            scheduled_start__lte=day_end_pkt,
            status__in=[JobBooking.STATUS_PENDING, JobBooking.STATUS_CONFIRMED],
        ).values('scheduled_start', 'scheduled_end')
    )

    if not conflicts:
        return candidates

    # --- Step 5: Drop overlapping slots ---
    def overlaps(slot: dict, booking: dict) -> bool:
        """True when the slot window [iso_start, iso_end) intersects the booking window."""
        import datetime as _dt
        s_start = _dt.datetime.fromisoformat(slot['iso_start'])
        s_end   = _dt.datetime.fromisoformat(slot['iso_end'])
        b_start = booking['scheduled_start'].astimezone(PKT)
        b_end   = booking['scheduled_end'].astimezone(PKT)
        return s_start < b_end and s_end > b_start

    available = [
        slot for slot in candidates
        if not any(overlaps(slot, b) for b in conflicts)
    ]

    return available

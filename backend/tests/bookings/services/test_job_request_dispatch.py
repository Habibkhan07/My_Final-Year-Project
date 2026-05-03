"""
Tests for bookings/services/job_request_dispatch.py.

Covers the three pure helpers (payout, two-tier timer, ISO formatter) and
the dispatcher's contract: it builds the right payload — including the
``booking_type`` discriminator and ``payout_context`` prose used by the
technician's job card — broadcasts it once via EventDispatchService, and
arms the SLA scheduler exactly once with the same ``expires_in_seconds``
it sent on the wire.

EventDispatchService is mocked so tests don't touch Channels / Celery / the
EventLog. The Port-and-Adapter split lets us pass a fake JobDispatchScheduler
directly — no Celery broker, no apply_async.
"""
from __future__ import annotations

import datetime
import decimal
import zoneinfo

import pytest

from bookings.selectors import (
    BOOKING_TYPE_FIXED_GIG,
    BOOKING_TYPE_INSPECTION,
    BOOKING_TYPE_LABOR_GIG,
)
from bookings.services import job_request_dispatch as dispatch_module
from bookings.services.job_request_dispatch import (
    ASAP_TIMER_SECONDS,
    MIN_DISPATCH_SLA,
    SCHEDULED_TIMER_SECONDS,
    _to_iso_utc,
    compute_dispatch_timer_seconds,
    compute_technician_payout,
    dispatch_job_new_request_event,
)
from tests.factories.bookings import JobBookingFactory
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.customers import CustomerAddressFactory, CustomerProfileFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db

PKT = zoneinfo.ZoneInfo("Asia/Karachi")
UTC = datetime.timezone.utc


class _FakeScheduler:
    """In-memory JobDispatchScheduler — captures schedule_sla_timeout calls."""

    def __init__(self) -> None:
        self.calls: list[dict] = []

    def schedule_sla_timeout(self, *, booking_id: int, delay_seconds: int) -> None:
        self.calls.append({"booking_id": booking_id, "delay_seconds": delay_seconds})


# =====================================================================
# compute_technician_payout
# =====================================================================

class TestComputeTechnicianPayout:

    def test_returns_string(self):
        assert isinstance(compute_technician_payout(decimal.Decimal("1500.00")), str)

    def test_simple_value_is_eighty_percent(self):
        # 1500 × 0.80 = 1200 — the contract example.
        assert compute_technician_payout(decimal.Decimal("1500.00")) == "1200"

    def test_drops_decimals_via_half_up_rounding(self):
        # 1234 × 0.80 = 987.20 → "987"
        assert compute_technician_payout(decimal.Decimal("1234.00")) == "987"

    def test_half_up_rounding_rounds_up_at_exactly_half(self):
        # 1234.375 × 0.80 = 987.50 → "988" (HALF_UP, not banker's rounding).
        assert compute_technician_payout(decimal.Decimal("1234.375")) == "988"

    def test_zero_amount(self):
        assert compute_technician_payout(decimal.Decimal("0.00")) == "0"

    def test_no_float_drift(self):
        # If the implementation used float, 0.1 + 0.2 errors would compound.
        # Decimal arithmetic must give the exact answer.
        assert compute_technician_payout(decimal.Decimal("100.10")) == "80"


# =====================================================================
# compute_dispatch_timer_seconds (two-tier SLA)
# =====================================================================

class TestComputeDispatchTimerSeconds:

    def test_within_two_hours_is_asap_tier(self):
        from django.utils import timezone
        scheduled = timezone.now() + datetime.timedelta(hours=1)
        assert compute_dispatch_timer_seconds(scheduled) == ASAP_TIMER_SECONDS

    def test_just_over_two_hours_is_scheduled_tier(self):
        from django.utils import timezone
        scheduled = timezone.now() + datetime.timedelta(hours=2, minutes=1)
        assert compute_dispatch_timer_seconds(scheduled) == SCHEDULED_TIMER_SECONDS

    def test_far_future_is_scheduled_tier(self):
        from django.utils import timezone
        scheduled = timezone.now() + datetime.timedelta(days=2)
        assert compute_dispatch_timer_seconds(scheduled) == SCHEDULED_TIMER_SECONDS

    def test_exactly_two_hours_is_asap_tier(self):
        # delta == 2h exactly — boundary collapses to ASAP (≤ 2h).
        from django.utils import timezone
        scheduled = timezone.now() + datetime.timedelta(hours=2)
        assert compute_dispatch_timer_seconds(scheduled) == ASAP_TIMER_SECONDS

    def test_past_scheduled_start_collapses_to_asap(self):
        # Defensive: stale slot or clock skew → most-urgent tier, never miss.
        from django.utils import timezone
        scheduled = timezone.now() - datetime.timedelta(hours=5)
        assert compute_dispatch_timer_seconds(scheduled) == ASAP_TIMER_SECONDS


# =====================================================================
# _to_iso_utc
# =====================================================================

class TestToIsoUtc:

    def test_utc_input_emits_z_suffix(self):
        dt = datetime.datetime(2026, 4, 8, 5, 0, 0, tzinfo=UTC)
        assert _to_iso_utc(dt) == "2026-04-08T05:00:00Z"

    def test_pkt_input_is_converted_to_utc(self):
        # 10:00 PKT == 05:00 UTC (PKT = UTC+5).
        dt = datetime.datetime(2026, 4, 8, 10, 0, 0, tzinfo=PKT)
        assert _to_iso_utc(dt) == "2026-04-08T05:00:00Z"

    def test_no_offset_in_output(self):
        # The Z suffix replaces the +00:00 — never both.
        dt = datetime.datetime(2026, 4, 8, 5, 0, 0, tzinfo=UTC)
        out = _to_iso_utc(dt)
        assert "+00:00" not in out
        assert out.endswith("Z")


# =====================================================================
# dispatch_job_new_request_event
# =====================================================================

class TestDispatchJobNewRequestEvent:

    def _build_booking(self, **overrides):
        tech = TechnicianProfileFactory(status="APPROVED")
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        kwargs = dict(
            technician=tech,
            customer=profile.user,
            address=address,
            price_amount=decimal.Decimal("1500.00"),
            price_context="Inspection Fee",
        )
        kwargs.update(overrides)
        return JobBookingFactory(**kwargs)

    def test_calls_broadcast_event_exactly_once(self, mocker):
        booking = self._build_booking()
        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())
        assert broadcast.call_count == 1

    def test_broadcast_targets_the_assigned_technicians_user(self, mocker):
        booking = self._build_booking()
        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())
        kwargs = broadcast.call_args.kwargs
        assert kwargs["user"] == booking.technician.user
        assert kwargs["target_role"] == "technician"
        assert kwargs["event_type"] == "job_new_request"

    def test_payload_shape_matches_contract(self, mocker):
        # Far-future Scenario-C booking → SCHEDULED_TIMER_SECONDS, INSPECTION.
        from django.utils import timezone
        service = ServiceFactory(name="AC Service")
        booking = self._build_booking(
            service=service,
            scheduled_start=timezone.now() + datetime.timedelta(days=1),
            price_amount=decimal.Decimal("1500.00"),
        )
        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())

        payload = broadcast.call_args.kwargs["payload"]
        assert set(payload.keys()) == {
            "job_id",
            "service_name",
            "booking_type",
            "scheduled_start_iso",
            "payout",
            "payout_context",
            "expires_in_seconds",
            "ui_location_label",
        }
        assert payload["job_id"] == booking.id
        # service_name derived from the parent Service when no sub_service.
        assert payload["service_name"] == "AC Service"
        assert payload["booking_type"] == BOOKING_TYPE_INSPECTION
        assert payload["payout_context"] == "Inspection visit — quote built on-site"
        assert payload["payout"] == "1200"
        assert payload["expires_in_seconds"] == SCHEDULED_TIMER_SECONDS
        # scheduled_start_iso must be UTC, not the source PKT offset.
        assert payload["scheduled_start_iso"].endswith("Z")

    def test_fixed_gig_payload_uses_subservice_name_and_correct_type(self, mocker):
        service = ServiceFactory(name="AC Service")
        sub = SubServiceFactory(
            service=service, name="AC Deep Wash", is_fixed_price=True,
        )
        booking = self._build_booking(service=service, sub_service=sub)

        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())
        payload = broadcast.call_args.kwargs["payload"]

        # sub_service overrides parent service for the technician's headline.
        assert payload["service_name"] == "AC Deep Wash"
        assert payload["booking_type"] == BOOKING_TYPE_FIXED_GIG
        assert payload["payout_context"] == "Fixed-price gig — full payout"

    def test_labor_gig_payload_uses_subservice_name_and_correct_type(self, mocker):
        service = ServiceFactory(name="Plumbing")
        sub = SubServiceFactory(
            service=service, name="Faucet Repair", is_fixed_price=False,
        )
        booking = self._build_booking(service=service, sub_service=sub)

        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())
        payload = broadcast.call_args.kwargs["payload"]

        assert payload["service_name"] == "Faucet Repair"
        assert payload["booking_type"] == BOOKING_TYPE_LABOR_GIG
        assert payload["payout_context"] == "Labor agreed up front"

    def test_arms_scheduler_with_matching_expires_in_seconds(self, mocker):
        # Arming the SLA timer with a delay that diverges from the value sent
        # on the wire would desync the technician's countdown UI from the
        # server-side expiry — assert they are the same integer.
        from django.utils import timezone
        booking = self._build_booking(
            scheduled_start=timezone.now() + datetime.timedelta(minutes=30),
        )
        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        scheduler = _FakeScheduler()
        dispatch_job_new_request_event(booking, scheduler=scheduler)

        wire_value = broadcast.call_args.kwargs["payload"]["expires_in_seconds"]
        assert len(scheduler.calls) == 1
        assert scheduler.calls[0]["booking_id"] == booking.id
        assert scheduler.calls[0]["delay_seconds"] == wire_value
        # Within-2h booking → ASAP tier (60s raw) lifted to the 5-minute
        # swipe-to-accept floor on the wire. The matching-equality check
        # above already proves wire and Celery countdown stay locked.
        assert wire_value == int(MIN_DISPATCH_SLA.total_seconds())

    def test_default_scheduler_resolved_lazily_when_none_passed(self, mocker):
        # Verify the lazy-import wiring: when no scheduler is injected,
        # bookings.adapters.get_default_scheduler is called and its result
        # is the one that gets schedule_sla_timeout invoked on it.
        booking = self._build_booking()
        mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        fake = _FakeScheduler()
        # Patch where it's looked up — the lazy import resolves
        # bookings.adapters.get_default_scheduler at call time.
        mocker.patch(
            "bookings.adapters.get_default_scheduler",
            return_value=fake,
        )
        dispatch_job_new_request_event(booking)  # no scheduler kwarg
        assert len(fake.calls) == 1
        assert fake.calls[0]["booking_id"] == booking.id


# =====================================================================
# MIN_DISPATCH_SLA — 5-minute wire-contract floor (flag #17)
# =====================================================================

class TestMinDispatchSlaFloor:
    """The technician swipe-to-accept UI is unusable below ~5 minutes:
    the user has to notice the offer, read the four blocks of detail,
    decide, and physically swipe across the runway. The dispatcher
    enforces a hard wire floor so any future per-booking-type policy
    can't silently break the technician UI. The floor is applied at the
    dispatch site, NOT inside `compute_dispatch_timer_seconds` — the
    pure tier function still reports the raw tier value for callers
    that want it; the dispatcher is the one with the wire contract.
    """

    def _build_booking(self, **overrides):
        tech = TechnicianProfileFactory(status="APPROVED")
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        kwargs = dict(
            technician=tech,
            customer=profile.user,
            address=address,
            price_amount=decimal.Decimal("1500.00"),
            price_context="Inspection Fee",
        )
        kwargs.update(overrides)
        return JobBookingFactory(**kwargs)

    def test_asap_tier_is_floored_to_minimum_dispatch_sla(self, mocker):
        # Within-2h booking: raw tier value is 60s, well below the
        # 5-minute floor. Wire payload must report the floored value
        # so the technician's countdown UI has enough runway.
        from django.utils import timezone
        booking = self._build_booking(
            scheduled_start=timezone.now() + datetime.timedelta(minutes=30),
        )
        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())

        floored = int(MIN_DISPATCH_SLA.total_seconds())
        assert floored == 300
        assert ASAP_TIMER_SECONDS < floored  # documents the lift
        assert broadcast.call_args.kwargs["payload"]["expires_in_seconds"] == floored
        # The envelope-level top-level expires_in_seconds (used to derive
        # envelope.expires_at) must match the floored payload value;
        # otherwise the EventLog row would expire on a different clock
        # than the wire countdown the technician sees.
        assert broadcast.call_args.kwargs["expires_in_seconds"] == floored

    def test_scheduled_tier_above_floor_is_unchanged(self, mocker):
        # Far-future booking: raw tier value is 900s (15 min), above the
        # 5-minute floor. max() is a no-op — the scheduled tier survives
        # untouched so customers booking days out still get the longer
        # acceptance window.
        from django.utils import timezone
        booking = self._build_booking(
            scheduled_start=timezone.now() + datetime.timedelta(days=1),
        )
        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())

        assert SCHEDULED_TIMER_SECONDS > int(MIN_DISPATCH_SLA.total_seconds())
        assert (
            broadcast.call_args.kwargs["payload"]["expires_in_seconds"]
            == SCHEDULED_TIMER_SECONDS
        )

    def test_scheduler_armed_with_floored_value_for_asap_tier(self, mocker):
        # Single source of truth: the same floored `expires_in` feeds
        # both the broadcast payload AND the Celery SLA countdown.
        # If they drifted, AWAITING → REJECTED would fire before the
        # tech's drain visually reached zero — accept-just-past-expiry
        # would surface as a silent 409.
        from django.utils import timezone
        booking = self._build_booking(
            scheduled_start=timezone.now() + datetime.timedelta(minutes=30),
        )
        mocker.patch.object(dispatch_module.EventDispatchService, "broadcast_event")
        scheduler = _FakeScheduler()
        dispatch_job_new_request_event(booking, scheduler=scheduler)

        floored = int(MIN_DISPATCH_SLA.total_seconds())
        assert len(scheduler.calls) == 1
        assert scheduler.calls[0]["delay_seconds"] == floored

    def test_compute_dispatch_timer_seconds_pure_function_unaffected(self):
        # The floor lives at the dispatch site, not in the tier function.
        # This is intentional: callers that want the raw tier value (for
        # logging, analytics, or a future per-booking-type policy) still
        # see the unfloored result. Dispatcher is the wire boundary;
        # tier function is a pure helper.
        from django.utils import timezone
        scheduled_asap = timezone.now() + datetime.timedelta(hours=1)
        assert compute_dispatch_timer_seconds(scheduled_asap) == ASAP_TIMER_SECONDS
        assert ASAP_TIMER_SECONDS < int(MIN_DISPATCH_SLA.total_seconds())


# =====================================================================
# ui_location_label — locality echoed onto the technician's job card
# =====================================================================

class TestUiLocationLabel:
    """The pre-composed `CustomerAddress.locality_label` rides the
    `job_new_request` payload as `ui_location_label` so the technician's
    card can render the locality verbatim (Dumb-UI). Three null paths must
    all serialize as JSON null without exploding:
      1. address row has a populated `locality_label` → string echoed
      2. address row has `locality_label = None` (legacy / pre-session-4)
      3. booking's `address` FK is None (SET_NULL on address delete)
    """

    def _build_booking(self, **overrides):
        tech = TechnicianProfileFactory(status="APPROVED")
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        kwargs = dict(
            technician=tech,
            customer=profile.user,
            address=address,
            price_amount=decimal.Decimal("1500.00"),
            price_context="Inspection Fee",
        )
        kwargs.update(overrides)
        return JobBookingFactory(**kwargs)

    def test_populated_locality_label_appears_in_payload(self, mocker):
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(
            customer=profile,
            locality_label="Gulberg, Lahore",
        )
        booking = self._build_booking(customer=profile.user, address=address)

        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())

        payload = broadcast.call_args.kwargs["payload"]
        assert payload["ui_location_label"] == "Gulberg, Lahore"

    def test_null_locality_label_serializes_as_null(self, mocker):
        # Default factory leaves locality_label as None (legacy / pre-rollout).
        booking = self._build_booking()

        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())

        payload = broadcast.call_args.kwargs["payload"]
        assert payload["ui_location_label"] is None

    def test_detached_address_fk_serializes_as_null(self, mocker):
        # `address` FK is `on_delete=SET_NULL` — bookings can outlive the
        # address row. Dispatcher must not blow up when address_id is None.
        booking = self._build_booking(address=None)

        broadcast = mocker.patch.object(
            dispatch_module.EventDispatchService, "broadcast_event"
        )
        dispatch_job_new_request_event(booking, scheduler=_FakeScheduler())

        payload = broadcast.call_args.kwargs["payload"]
        assert payload["ui_location_label"] is None

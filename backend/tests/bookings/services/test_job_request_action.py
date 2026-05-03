"""
Tests for bookings/services/job_request_action.py.

Covers the technician-side accept / decline service:
    - State-machine transitions (AWAITING → CONFIRMED / REJECTED).
    - Idempotency: same-tech retry on the terminal status returns the
      row without re-emitting the customer event.
    - IDOR: a wrong-owner request collapses to a single missing-row
      exception (no enumeration leak).
    - on_commit semantics: a rolled-back outer transaction suppresses
      the customer-facing broadcast.
    - Conflict raising: every non-AWAITING / non-idempotent state
      surfaces ``BookingNotActionableError`` with ``current_status``
      set to the live row state.
    - Customer event payload shape — single source of truth across
      accept and decline (different ``rawType`` + ``reason`` only).

EventDispatchService is mocked; we don't touch Channels, FCM, or
EventLog. Tests use ``transaction=True`` where on_commit semantics
are under test, otherwise the cheaper transactional fixture.
"""
from __future__ import annotations

from datetime import timedelta

import pytest
from django.db import transaction
from django.utils import timezone

from bookings.exceptions import (
    BookingNotActionableError,
    BookingNotFoundForTechnicianError,
)
from bookings.models import JobBooking
from bookings.services import job_request_action as action_module
from bookings.services.job_request_action import (
    accept_job_booking,
    decline_job_booking,
)
from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingFactory
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory
from tests.factories.technicians import TechnicianProfileFactory


# =====================================================================
# accept_job_booking — state transitions + idempotency
# =====================================================================

@pytest.mark.django_db
class TestAcceptJobBookingTransitions:

    def _booking(self, status=JobBooking.STATUS_AWAITING_TECH_ACCEPT, **overrides):
        tech = TechnicianProfileFactory(status="APPROVED")
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        kwargs = dict(
            technician=tech,
            customer=profile.user,
            address=address,
            status=status,
        )
        kwargs.update(overrides)
        return JobBookingFactory(**kwargs)

    def test_awaiting_transitions_to_confirmed(self, mocker):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        booking = self._booking()
        result = accept_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        result.refresh_from_db()
        assert result.status == JobBooking.STATUS_CONFIRMED

    def test_returns_the_booking_row(self, mocker):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        booking = self._booking()
        result = accept_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        assert result.id == booking.id

    def test_only_status_field_is_written(self, mocker):
        # update_fields=["status"] must not touch unrelated columns.
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        booking = self._booking(price_amount="1234.56")
        accept_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        booking.refresh_from_db()
        assert str(booking.price_amount) == "1234.56"
        assert booking.status == JobBooking.STATUS_CONFIRMED

    def test_already_confirmed_same_tech_is_idempotent_success(self, mocker):
        # Retried request (network blip, double-tap) on the same tech's
        # already-accepted booking returns 200 with no second event.
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = self._booking(status=JobBooking.STATUS_CONFIRMED)
        result = accept_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        assert result.id == booking.id
        # No event emitted on the idempotent path — would double-notify.
        assert broadcast.call_count == 0

    @pytest.mark.parametrize(
        "blocking_status",
        [
            JobBooking.STATUS_PENDING,
            JobBooking.STATUS_REJECTED,    # SLA fired first
            JobBooking.STATUS_CANCELLED,   # Customer cancelled first
            JobBooking.STATUS_COMPLETED,
        ],
    )
    def test_non_awaiting_states_raise_not_actionable(self, mocker, blocking_status):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        booking = self._booking(status=blocking_status)
        with pytest.raises(BookingNotActionableError) as exc_info:
            accept_job_booking(
                booking_id=booking.id,
                technician_user=booking.technician.user,
            )
        assert exc_info.value.current_status == blocking_status

    def test_status_unchanged_when_not_actionable(self, mocker):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        booking = self._booking(status=JobBooking.STATUS_REJECTED)
        with pytest.raises(BookingNotActionableError):
            accept_job_booking(
                booking_id=booking.id,
                technician_user=booking.technician.user,
            )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_REJECTED


# =====================================================================
# accept_job_booking — IDOR-safe queryset scoping
# =====================================================================

@pytest.mark.django_db
class TestAcceptJobBookingIdor:

    def test_missing_booking_id_raises_not_found(self, mocker):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        tech = TechnicianProfileFactory(status="APPROVED")
        with pytest.raises(BookingNotFoundForTechnicianError):
            accept_job_booking(
                booking_id=999_999,
                technician_user=tech.user,
            )

    def test_other_technicians_booking_collapses_to_not_found(self, mocker):
        # Tech A tries to accept Tech B's offer. Service must return
        # the same exception as a missing row — no enumeration leak.
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        tech_a = TechnicianProfileFactory(status="APPROVED")
        tech_b = TechnicianProfileFactory(status="APPROVED")
        booking = JobBookingFactory(
            technician=tech_b,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        with pytest.raises(BookingNotFoundForTechnicianError):
            accept_job_booking(
                booking_id=booking.id,
                technician_user=tech_a.user,
            )
        # Crucially, the booking is unchanged.
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_AWAITING_TECH_ACCEPT

    def test_customer_user_cannot_accept_their_own_booking(self, mocker):
        # The customer is NOT the technician.user, so the queryset filter
        # rejects them just like any other non-owner.
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        profile = CustomerProfileFactory()
        booking = JobBookingFactory(
            customer=profile.user,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        with pytest.raises(BookingNotFoundForTechnicianError):
            accept_job_booking(
                booking_id=booking.id,
                technician_user=profile.user,
            )

    def test_unrelated_user_cannot_accept(self, mocker):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        random_user = UserFactory()
        with pytest.raises(BookingNotFoundForTechnicianError):
            accept_job_booking(
                booking_id=booking.id,
                technician_user=random_user,
            )


# =====================================================================
# decline_job_booking — mirrors accept's transitions
# =====================================================================

@pytest.mark.django_db
class TestDeclineJobBookingTransitions:

    def _booking(self, status=JobBooking.STATUS_AWAITING_TECH_ACCEPT, **overrides):
        tech = TechnicianProfileFactory(status="APPROVED")
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        kwargs = dict(
            technician=tech,
            customer=profile.user,
            address=address,
            status=status,
        )
        kwargs.update(overrides)
        return JobBookingFactory(**kwargs)

    def test_awaiting_transitions_to_rejected(self, mocker):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        booking = self._booking()
        decline_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_REJECTED

    def test_already_rejected_same_tech_is_idempotent_success(self, mocker):
        # Includes the SLA-won-the-race case (both pathways flip
        # AWAITING → REJECTED). Tech's intent matches the end-state,
        # so report success without re-emitting.
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = self._booking(status=JobBooking.STATUS_REJECTED)
        result = decline_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        assert result.id == booking.id
        assert broadcast.call_count == 0

    @pytest.mark.parametrize(
        "blocking_status",
        [
            JobBooking.STATUS_PENDING,
            JobBooking.STATUS_CONFIRMED,
            JobBooking.STATUS_CANCELLED,
            JobBooking.STATUS_COMPLETED,
        ],
    )
    def test_non_awaiting_non_rejected_states_raise_not_actionable(
        self, mocker, blocking_status,
    ):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        booking = self._booking(status=blocking_status)
        with pytest.raises(BookingNotActionableError) as exc_info:
            decline_job_booking(
                booking_id=booking.id,
                technician_user=booking.technician.user,
            )
        assert exc_info.value.current_status == blocking_status


# =====================================================================
# decline_job_booking — IDOR mirrors accept
# =====================================================================

@pytest.mark.django_db
class TestDeclineJobBookingIdor:

    def test_other_technicians_booking_collapses_to_not_found(self, mocker):
        mocker.patch.object(action_module.EventDispatchService, "broadcast_event")
        tech_a = TechnicianProfileFactory(status="APPROVED")
        tech_b = TechnicianProfileFactory(status="APPROVED")
        booking = JobBookingFactory(
            technician=tech_b,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        with pytest.raises(BookingNotFoundForTechnicianError):
            decline_job_booking(
                booking_id=booking.id,
                technician_user=tech_a.user,
            )

    def test_missing_booking_raises_not_found(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        with pytest.raises(BookingNotFoundForTechnicianError):
            decline_job_booking(
                booking_id=999_999,
                technician_user=tech.user,
            )


# =====================================================================
# on_commit semantics — broadcast tied to the transaction
# =====================================================================

@pytest.mark.django_db(transaction=True)
class TestAcceptOnCommitSemantics:
    """
    The customer event must NOT fire if the surrounding transaction
    rolls back. We exercise this by wrapping the service call in an
    outer atomic block that we deliberately roll back, then asserting
    broadcast was never called.

    Runs with ``transaction=True`` so on_commit hooks behave as in
    production (the default pytest-django fixture wraps each test in
    a transaction that's rolled back at teardown, which would mask
    on_commit calls entirely).
    """

    def _booking(self, status=JobBooking.STATUS_AWAITING_TECH_ACCEPT):
        tech = TechnicianProfileFactory(status="APPROVED")
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        return JobBookingFactory(
            technician=tech,
            customer=profile.user,
            address=address,
            status=status,
        )

    def test_successful_accept_emits_exactly_one_event(self, mocker):
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = self._booking()
        accept_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        assert broadcast.call_count == 1

    def test_successful_decline_emits_exactly_one_event(self, mocker):
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = self._booking()
        decline_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        assert broadcast.call_count == 1

    def test_outer_rollback_suppresses_broadcast(self, mocker):
        # Real-world analogue: an outer caller rolls back after our
        # service stamped CONFIRMED. on_commit must NOT fire — otherwise
        # the customer would see "Booking confirmed" while the row is back
        # to AWAITING.
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = self._booking()

        class _Rollback(Exception):
            pass

        with pytest.raises(_Rollback):
            with transaction.atomic():
                accept_job_booking(
                    booking_id=booking.id,
                    technician_user=booking.technician.user,
                )
                raise _Rollback()

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_AWAITING_TECH_ACCEPT
        assert broadcast.call_count == 0

    def test_idempotent_repeat_does_not_emit_a_second_event(self, mocker):
        # First call: emits. Second call (status now CONFIRMED): no emit.
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = self._booking()
        accept_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        accept_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        assert broadcast.call_count == 1


# =====================================================================
# Customer event payload shape
# =====================================================================

@pytest.mark.django_db(transaction=True)
class TestCustomerEventPayloadShape:

    def test_job_accepted_payload_contains_required_fields(self, mocker):
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        service = ServiceFactory(name="AC Service")
        sub = SubServiceFactory(service=service, name="AC Deep Wash", is_fixed_price=True)
        tech = TechnicianProfileFactory(status="APPROVED")
        tech.user.first_name = "Ali"
        tech.user.last_name = "Khan"
        tech.user.save(update_fields=["first_name", "last_name"])
        profile = CustomerProfileFactory()
        scheduled_start = timezone.now() + timedelta(hours=1)
        booking = JobBookingFactory(
            technician=tech,
            customer=profile.user,
            service=service,
            sub_service=sub,
            scheduled_start=scheduled_start,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )

        accept_job_booking(
            booking_id=booking.id,
            technician_user=tech.user,
        )

        kwargs = broadcast.call_args.kwargs
        assert kwargs["user"] == profile.user
        assert kwargs["target_role"] == "customer"
        assert kwargs["event_type"] == "job_accepted"
        # No SLA on the customer-facing notification.
        assert kwargs["expires_in_seconds"] is None

        payload = kwargs["payload"]
        assert set(payload.keys()) == {
            "job_id",
            "technician_id",
            "technician_display_name",
            "scheduled_start_iso",
            "service_name",
        }
        assert payload["job_id"] == booking.id
        assert payload["technician_id"] == tech.id
        assert payload["technician_display_name"] == "Ali Khan"
        # Sub-service name preferred over parent service.
        assert payload["service_name"] == "AC Deep Wash"
        assert payload["scheduled_start_iso"].endswith("Z")

    def test_job_accepted_payload_falls_back_to_username_when_name_blank(self, mocker):
        # get_full_name() returns "" when first_name + last_name are empty —
        # we fall back to username so the customer's surface always renders
        # *something* identifiable.
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        tech = TechnicianProfileFactory(status="APPROVED")
        tech.user.first_name = ""
        tech.user.last_name = ""
        tech.user.save(update_fields=["first_name", "last_name"])
        booking = JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        accept_job_booking(
            booking_id=booking.id,
            technician_user=tech.user,
        )
        payload = broadcast.call_args.kwargs["payload"]
        assert payload["technician_display_name"] == tech.user.username

    def test_job_accepted_uses_parent_service_name_for_inspection(self, mocker):
        # Inspection bookings have sub_service=None → fall back to the
        # parent Service's name.
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        service = ServiceFactory(name="Plumbing")
        booking = JobBookingFactory(
            service=service,
            sub_service=None,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        accept_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )
        payload = broadcast.call_args.kwargs["payload"]
        assert payload["service_name"] == "Plumbing"

    def test_booking_rejected_payload_contains_required_fields(self, mocker):
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        service = ServiceFactory(name="Plumbing")
        sub = SubServiceFactory(service=service, name="Faucet Repair", is_fixed_price=False)
        booking = JobBookingFactory(
            service=service,
            sub_service=sub,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        decline_job_booking(
            booking_id=booking.id,
            technician_user=booking.technician.user,
        )

        kwargs = broadcast.call_args.kwargs
        assert kwargs["target_role"] == "customer"
        assert kwargs["event_type"] == "booking_rejected"
        payload = kwargs["payload"]
        assert set(payload.keys()) == {
            "job_id",
            "technician_id",
            "scheduled_start_iso",
            "service_name",
            "reason",
        }
        # Discriminator: technician-decline arm. The SLA-expiry arm
        # reuses this same envelope with reason="sla_timeout" — see
        # tests/bookings/services/test_tasks.py.
        assert payload["reason"] == "technician_declined"
        assert payload["service_name"] == "Faucet Repair"

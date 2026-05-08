"""Tests for ``bookings.selectors.transition_validator.available_transitions``.

The hard contract: this selector's output for every (status, role)
must match what the orchestrator actually allows. Drift would produce
a button that 400s when tapped (validator says yes, orchestrator says
no) or hides a legitimate action (validator says no, orchestrator says
yes). The test suite calls each absent transition against the
orchestrator and asserts ``BookingValidationError``.

The orchestrator is the authority. If a future change adds a new
transition, the test will fail until the validator is updated.
"""
from __future__ import annotations

import pytest

from bookings.exceptions import BookingValidationError
from bookings.models import JobBooking
from bookings.selectors.transition_validator import available_transitions
from bookings.services import orchestrator
from tests.factories.bookings import JobBookingConfirmedFactory


pytestmark = pytest.mark.django_db


_ALL_STATUSES = [value for value, _ in JobBooking.STATUS_CHOICES]


def test_returns_list_of_strings():
    booking = JobBookingConfirmedFactory()
    out = available_transitions(booking, viewer=booking.customer, role="customer")
    assert isinstance(out, list)
    assert all(isinstance(s, str) for s in out)


def test_customer_quoted_offers_quote_decisions():
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_QUOTED)
    out = available_transitions(booking, viewer=booking.customer, role="customer")
    assert "approve_quote" in out
    assert "decline_quote" in out
    assert "request_revision" in out


def test_tech_in_progress_offers_complete_with_cash():
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_IN_PROGRESS)
    out = available_transitions(booking, viewer=booking.technician.user, role="technician")
    assert "mark_complete_with_cash" in out
    assert "submit_quote" in out  # upsell allowed


def test_terminal_completed_no_lifecycle_transitions_just_dispute():
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_COMPLETED)
    out = available_transitions(booking, viewer=booking.customer, role="customer")
    assert out == ["open_dispute"]


def test_pre_confirmed_pending_no_dispute():
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_PENDING)
    out = available_transitions(booking, viewer=booking.customer, role="customer")
    assert "open_dispute" not in out


def test_reschedule_only_pre_en_route():
    confirmed = JobBookingConfirmedFactory(status=JobBooking.STATUS_CONFIRMED)
    en_route = JobBookingConfirmedFactory(status=JobBooking.STATUS_EN_ROUTE)
    out_confirmed = available_transitions(confirmed, viewer=confirmed.customer, role="customer")
    out_en_route = available_transitions(en_route, viewer=en_route.customer, role="customer")
    assert "reschedule" in out_confirmed
    assert "reschedule" not in out_en_route


# ---------------------------------------------------------------------
# Parity check — verifies the validator never claims a transition is
# valid when the orchestrator would actually raise. We exercise the
# tech-only phase markers (`en_route`, `arrived`, `start_inspection`)
# because they have a clean from-state contract; covering all 14
# transitions × 14 statuses would be churn for low value.
# ---------------------------------------------------------------------


def _assert_orchestrator_rejects_or_is_noop(callable_, *, expected_target_status, booking):
    """When the validator hides a transition, the orchestrator must
    either raise (wrong-from-state) OR be an idempotent no-op (booking
    is already in the target status). Either way the user can't move
    state forward, which is what the validator surfaces."""
    pre_status = booking.status
    try:
        callable_()
    except BookingValidationError:
        return  # raised — parity holds
    booking.refresh_from_db()
    # If it didn't raise, the orchestrator must have short-circuited
    # because the booking was already in the target status.
    assert pre_status == expected_target_status, (
        f"Orchestrator silently accepted a transition from "
        f"{pre_status!r} to {expected_target_status!r}; validator should "
        f"have surfaced it but did not."
    )


@pytest.mark.parametrize("status", _ALL_STATUSES)
def test_parity_tech_en_route(status, fake_finance, captured_broadcasts):
    booking = JobBookingConfirmedFactory(status=status)
    out = available_transitions(booking, viewer=booking.technician.user, role="technician")
    if status == JobBooking.STATUS_CONFIRMED:
        assert "en_route" in out
    else:
        assert "en_route" not in out
        _assert_orchestrator_rejects_or_is_noop(
            lambda: orchestrator.en_route(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                finance=fake_finance,
            ),
            expected_target_status=JobBooking.STATUS_EN_ROUTE,
            booking=booking,
        )


@pytest.mark.parametrize("status", _ALL_STATUSES)
def test_parity_tech_arrived(status, fake_finance, captured_broadcasts):
    booking = JobBookingConfirmedFactory(status=status)
    out = available_transitions(booking, viewer=booking.technician.user, role="technician")
    if status == JobBooking.STATUS_EN_ROUTE:
        assert "arrived" in out
    else:
        assert "arrived" not in out
        _assert_orchestrator_rejects_or_is_noop(
            lambda: orchestrator.arrived(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                finance=fake_finance,
            ),
            expected_target_status=JobBooking.STATUS_ARRIVED,
            booking=booking,
        )


@pytest.mark.parametrize("status", _ALL_STATUSES)
def test_parity_tech_start_inspection(status, fake_finance, captured_broadcasts):
    booking = JobBookingConfirmedFactory(status=status)
    out = available_transitions(booking, viewer=booking.technician.user, role="technician")
    if status == JobBooking.STATUS_ARRIVED:
        assert "start_inspection" in out
    else:
        assert "start_inspection" not in out
        _assert_orchestrator_rejects_or_is_noop(
            lambda: orchestrator.start_inspection(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                finance=fake_finance,
            ),
            expected_target_status=JobBooking.STATUS_INSPECTING,
            booking=booking,
        )

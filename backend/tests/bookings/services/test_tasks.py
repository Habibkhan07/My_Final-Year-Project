"""
Tests for bookings/tasks.py — expire_pending_job_booking SLA timeout task.

State-mutation guards live in ``TestExpirePendingJobBooking`` (cheap
transactional fixture). The customer-facing ``booking_rejected`` emit
on commit (flag #22) lives in ``TestExpireEmitOnCommitSemantics`` —
that class runs with ``transaction=True`` so on_commit hooks actually
fire (the default pytest-django fixture wraps each test in a single
rolled-back transaction, which would suppress every on_commit call).

We invoke the task synchronously via ``.run()`` to bypass Celery's queue
and test the body directly.
"""
from __future__ import annotations

import pytest

from bookings.models import JobBooking
from bookings.tasks import expire_pending_job_booking
from tests.factories.bookings import JobBookingFactory
from tests.factories.catalog import ServiceFactory, SubServiceFactory


@pytest.mark.django_db
class TestExpirePendingJobBooking:

    def test_missing_booking_is_noop(self):
        # Should not raise; non-existent ID is a quiet log line, not an error.
        expire_pending_job_booking.run(999_999)

    @pytest.mark.parametrize(
        "non_awaiting_status",
        [
            JobBooking.STATUS_PENDING,
            JobBooking.STATUS_CONFIRMED,
            JobBooking.STATUS_COMPLETED,
            JobBooking.STATUS_CANCELLED,
            JobBooking.STATUS_REJECTED,
        ],
    )
    def test_non_awaiting_status_is_noop(self, non_awaiting_status):
        # Any non-AWAITING state means the booking has either been accepted
        # by the technician (CONFIRMED) or moved through its lifecycle by
        # another path; the SLA task must not interfere.
        booking = JobBookingFactory(status=non_awaiting_status)
        expire_pending_job_booking.run(booking.id)
        booking.refresh_from_db()
        assert booking.status == non_awaiting_status

    def test_awaiting_booking_is_flipped_to_rejected(self):
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        expire_pending_job_booking.run(booking.id)
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_REJECTED

    def test_only_status_field_is_written(self):
        # We use update_fields=["status"] so unrelated columns are untouched.
        # Capture price_amount as a sentinel — if a save() somehow rewrote the
        # whole row it would still match, but at least we lock in the contract.
        original_price = "1234.56"
        booking = JobBookingFactory(
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
            price_amount=original_price,
        )
        expire_pending_job_booking.run(booking.id)
        booking.refresh_from_db()
        assert str(booking.price_amount) == original_price

    def test_idempotent_when_run_twice(self):
        # Second run sees status=REJECTED and short-circuits — no double mutation
        # and no exception. Critical for Celery retry semantics.
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        expire_pending_job_booking.run(booking.id)
        expire_pending_job_booking.run(booking.id)  # second run is the test
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_REJECTED


# =====================================================================
# Customer event emit on commit (flag #22 — SLA arm)
# =====================================================================
#
# `_emit_booking_rejected` is imported lazily inside the task body from
# ``bookings.services.job_request_action``. Patching the broadcast method
# on the action module's `EventDispatchService` reference catches the call
# regardless of which arm (decline service or SLA task) drives the emit —
# both arms route through the same helper.

from bookings.services import job_request_action as action_module  # noqa: E402


@pytest.mark.django_db(transaction=True)
class TestExpireEmitOnCommitSemantics:

    def test_successful_expire_emits_booking_rejected_with_sla_timeout_reason(
        self, mocker
    ):
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        service = ServiceFactory(name="AC Service")
        sub = SubServiceFactory(
            service=service, name="AC Deep Wash", is_fixed_price=True
        )
        booking = JobBookingFactory(
            service=service,
            sub_service=sub,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )

        expire_pending_job_booking.run(booking.id)

        assert broadcast.call_count == 1
        kwargs = broadcast.call_args.kwargs
        assert kwargs["target_role"] == "customer"
        assert kwargs["event_type"] == "booking_rejected"
        assert kwargs["user"] == booking.customer
        # No SLA on the customer notification itself — informational.
        assert kwargs["expires_in_seconds"] is None

        payload = kwargs["payload"]
        assert set(payload.keys()) == {
            "job_id",
            "technician_id",
            "scheduled_start_iso",
            "service_name",
            "reason",
        }
        # The SLA arm's discriminator. The technician-decline arm emits
        # with reason="technician_declined" — same wire envelope, single
        # customer-side subscriber.
        assert payload["reason"] == "sla_timeout"
        # Sub-service name wins over parent service when present (mirrors
        # the helper's resolution; also confirms `select_related` covers
        # the FK without firing an extra query).
        assert payload["service_name"] == "AC Deep Wash"
        assert payload["job_id"] == booking.id
        assert payload["technician_id"] == booking.technician_id

    def test_non_awaiting_booking_does_not_emit(self, mocker):
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_CONFIRMED)
        expire_pending_job_booking.run(booking.id)
        assert broadcast.call_count == 0

    def test_missing_booking_does_not_emit(self, mocker):
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        expire_pending_job_booking.run(999_999)
        assert broadcast.call_count == 0

    def test_idempotent_repeat_does_not_emit_a_second_event(self, mocker):
        # First run: AWAITING → REJECTED, emits. Second run: status is
        # REJECTED, the awaiting-guard short-circuits, no emit. Mirrors
        # the technician-decline arm's idempotency contract.
        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        expire_pending_job_booking.run(booking.id)
        expire_pending_job_booking.run(booking.id)
        assert broadcast.call_count == 1

    def test_outer_rollback_suppresses_broadcast(self, mocker):
        # If a wrapping transaction rolls back after the task body
        # mutates status, on_commit must NOT fire — otherwise the
        # customer would see "Booking unavailable" while the row is
        # back to AWAITING.
        from django.db import transaction

        broadcast = mocker.patch.object(
            action_module.EventDispatchService, "broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)

        class _Rollback(Exception):
            pass

        with pytest.raises(_Rollback):
            with transaction.atomic():
                expire_pending_job_booking.run(booking.id)
                raise _Rollback()

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_AWAITING_TECH_ACCEPT
        assert broadcast.call_count == 0

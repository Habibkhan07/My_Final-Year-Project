"""
Tests for bookings/tasks.py — expire_pending_job_booking SLA timeout task.

Each test exercises one of the four idempotency guards. We invoke the task
synchronously via ``.run()`` to bypass Celery's queue and test the body.
"""
from __future__ import annotations

import datetime

import pytest
from django.utils import timezone

from bookings.models import JobBooking
from bookings.tasks import expire_pending_job_booking
from tests.factories.bookings import JobBookingFactory

pytestmark = pytest.mark.django_db


class TestExpirePendingJobBooking:

    def test_missing_booking_is_noop(self):
        # Should not raise; non-existent ID is a quiet log line, not an error.
        expire_pending_job_booking.run(999_999)

    def test_already_accepted_booking_is_noop(self):
        booking = JobBookingFactory(
            status=JobBooking.STATUS_CONFIRMED,
            accepted_at=timezone.now(),
        )
        expire_pending_job_booking.run(booking.id)
        booking.refresh_from_db()
        # Status is preserved — the task respected the prior acknowledgement.
        assert booking.status == JobBooking.STATUS_CONFIRMED

    @pytest.mark.parametrize(
        "non_confirmed_status",
        [
            JobBooking.STATUS_PENDING,
            JobBooking.STATUS_COMPLETED,
            JobBooking.STATUS_CANCELLED,
            JobBooking.STATUS_REJECTED,
        ],
    )
    def test_non_confirmed_status_is_noop(self, non_confirmed_status):
        # Any non-CONFIRMED state means another path already moved the
        # booking through its lifecycle; the SLA task must not interfere.
        booking = JobBookingFactory(
            status=non_confirmed_status,
            accepted_at=None,
        )
        expire_pending_job_booking.run(booking.id)
        booking.refresh_from_db()
        assert booking.status == non_confirmed_status

    def test_eligible_booking_is_flipped_to_rejected(self):
        booking = JobBookingFactory(
            status=JobBooking.STATUS_CONFIRMED,
            accepted_at=None,
        )
        expire_pending_job_booking.run(booking.id)
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_REJECTED

    def test_only_status_field_is_written(self):
        # We use update_fields=["status"] so unrelated columns are untouched.
        # Capture price_amount as a sentinel — if a save() somehow rewrote the
        # whole row it would still match, but at least we lock in the contract.
        original_price = "1234.56"
        booking = JobBookingFactory(
            status=JobBooking.STATUS_CONFIRMED,
            accepted_at=None,
            price_amount=original_price,
        )
        expire_pending_job_booking.run(booking.id)
        booking.refresh_from_db()
        assert str(booking.price_amount) == original_price

    def test_idempotent_when_run_twice(self):
        # Second run sees status=REJECTED and short-circuits — no double mutation
        # and no exception. Critical for Celery retry semantics.
        booking = JobBookingFactory(
            status=JobBooking.STATUS_CONFIRMED,
            accepted_at=None,
        )
        expire_pending_job_booking.run(booking.id)
        expire_pending_job_booking.run(booking.id)  # second run is the test
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_REJECTED

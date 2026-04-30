"""
Tests for bookings/adapters/celery_scheduler.py — the production
JobDispatchScheduler binding to Celery's countdown queue.

Mocks the bound shared_task's ``apply_async`` so we never touch a broker.
"""
from __future__ import annotations

from bookings.adapters.celery_scheduler import CelerySchedulerAdapter


class TestCelerySchedulerAdapter:

    def test_calls_apply_async_with_args_and_countdown(self, mocker):
        # Patch where it is looked up — the adapter imports the task at
        # module load, so we patch on that imported reference.
        apply_async = mocker.patch(
            'bookings.adapters.celery_scheduler.expire_pending_job_booking.apply_async'
        )

        adapter = CelerySchedulerAdapter()
        adapter.schedule_sla_timeout(booking_id=42, delay_seconds=900)

        apply_async.assert_called_once_with(args=[42], countdown=900)

    def test_passes_through_short_delay_for_asap_tier(self, mocker):
        # ASAP tier delivers a 60s countdown — verify the adapter does not
        # silently floor / clamp / re-route this value.
        apply_async = mocker.patch(
            'bookings.adapters.celery_scheduler.expire_pending_job_booking.apply_async'
        )

        CelerySchedulerAdapter().schedule_sla_timeout(booking_id=7, delay_seconds=60)

        apply_async.assert_called_once_with(args=[7], countdown=60)

    def test_no_other_kwargs_leak_through(self, mocker):
        # Lock the call signature — the contract is exactly args+countdown.
        # If we ever add eta / retry / queue routing, this test fails and
        # forces an explicit decision.
        apply_async = mocker.patch(
            'bookings.adapters.celery_scheduler.expire_pending_job_booking.apply_async'
        )

        CelerySchedulerAdapter().schedule_sla_timeout(booking_id=1, delay_seconds=120)

        kwargs = apply_async.call_args.kwargs
        assert set(kwargs.keys()) == {"args", "countdown"}

"""Termination endpoints (cancel × 2, no-show, dispute, reschedule).

The orchestrator owns every state-machine guard, fee mapping, audit
column write, and broadcast. These serializers carry only the request
shape the corresponding orchestrator function accepts.
"""
from __future__ import annotations

from datetime import timedelta

from django.utils import timezone
from rest_framework import serializers

from bookings.models import JobBooking


# ----------------------------------------------------------------------
# Customer cancel
# ----------------------------------------------------------------------


class CustomerCancelRequestSerializer(serializers.Serializer):
    """No body — actor + booking are derived from auth + URL."""


class CustomerCancelResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ["id", "status", "cancel_reason", "final_cash_to_collect"]


# ----------------------------------------------------------------------
# Tech cancel
# ----------------------------------------------------------------------


class TechCancelRequestSerializer(serializers.Serializer):
    # ``reason`` is reserved for the future reliability-incident
    # surface; the orchestrator currently writes a fixed
    # ``technician_cancelled`` cancel_reason.
    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=500,
    )


class TechCancelResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ["id", "status", "cancel_reason"]


# ----------------------------------------------------------------------
# No-show (either tech or customer)
# ----------------------------------------------------------------------


class MarkNoShowRequestSerializer(serializers.Serializer):
    """No body — actor_role is derived from auth, NOT from body. A tech
    sending ``actor_role='customer'`` must not flip a customer-side
    no-show.
    """


class MarkNoShowResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ["id", "status", "no_show_actor", "no_show_at"]


# ----------------------------------------------------------------------
# Open dispute (multipart)
# ----------------------------------------------------------------------


class OpenDisputeRequestSerializer(serializers.Serializer):
    initial_reason = serializers.CharField(min_length=10, max_length=2000)
    photo = serializers.ImageField(required=False, allow_null=True)

    # Audit P1-10 — bound the upload size. DRF's ImageField does Pillow
    # validation (rejects malformed images) but doesn't bound bytes.
    # 5 MB is generous for a phone camera photo and cheap to enforce.
    MAX_PHOTO_BYTES = 5 * 1024 * 1024

    def validate_photo(self, photo):
        if photo and photo.size > self.MAX_PHOTO_BYTES:
            raise serializers.ValidationError(
                f"Photo must be under {self.MAX_PHOTO_BYTES // (1024 * 1024)} MB."
            )
        return photo


class OpenDisputeResponseSerializer(serializers.Serializer):
    ticket_id = serializers.IntegerField()
    booking_id = serializers.IntegerField()
    booking_status = serializers.CharField()
    dispute_intake_method = serializers.CharField()


# ----------------------------------------------------------------------
# Reschedule
# ----------------------------------------------------------------------


class RescheduleRequestSerializer(serializers.Serializer):
    new_scheduled_start = serializers.DateTimeField()
    new_scheduled_end = serializers.DateTimeField()

    # Audit P2 (Pass 2 / C4-new): bound the reschedule window in BOTH
    # directions. Without these, a customer could rebook into the past
    # (orchestrator overlap check is purely against other bookings, not
    # against ``now``) which corrupts matchmaking, SLA timers, and the
    # booking-detail UI's elapsed-time displays. Allowing arbitrary
    # future dates also lets a customer permanently reserve tech
    # capacity (year-2099 slot pollution).
    #
    # The 90-day cap mirrors a reasonable "next quarter" planning horizon;
    # admin-side reschedules that need a longer reach should bypass this
    # endpoint and use the Django Admin form (no equivalent exists today;
    # add when needed).
    MAX_FUTURE_DAYS = 90
    # Small grace window so a client whose clock drifts by a few seconds
    # against the server doesn't get rejected when reschedule-to-now is
    # the de-facto 'asap' UX. Fine to allow a few seconds in the past.
    PAST_GRACE_SECONDS = 60

    def validate(self, attrs):
        if attrs["new_scheduled_end"] <= attrs["new_scheduled_start"]:
            raise serializers.ValidationError({
                "new_scheduled_end": ["Must be after new_scheduled_start."],
            })
        now = timezone.now()
        earliest = now - timedelta(seconds=self.PAST_GRACE_SECONDS)
        if attrs["new_scheduled_start"] < earliest:
            raise serializers.ValidationError({
                "new_scheduled_start": ["Must not be in the past."],
            })
        latest = now + timedelta(days=self.MAX_FUTURE_DAYS)
        if attrs["new_scheduled_start"] > latest:
            raise serializers.ValidationError({
                "new_scheduled_start": [
                    f"Must be within {self.MAX_FUTURE_DAYS} days of now.",
                ],
            })
        return attrs


class RescheduleResponseSerializer(serializers.Serializer):
    original_booking_id = serializers.IntegerField()
    original_status = serializers.CharField()
    child_booking_id = serializers.IntegerField()
    child_status = serializers.CharField()

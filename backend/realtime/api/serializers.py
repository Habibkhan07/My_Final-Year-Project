"""
Realtime API Serializers — Events and Devices.
"""
from __future__ import annotations

from rest_framework import serializers

from realtime.models import EventLog, FCMDevice


class EventLogSerializer(serializers.ModelSerializer):
    """
    Read-only envelope for a persisted event.
    """
    rawType = serializers.CharField(source="event_type", read_only=True)
    targetRole = serializers.CharField(source="target_role", read_only=True)
    timestamp = serializers.DateTimeField(source="created_at", read_only=True)

    class Meta:
        model = EventLog
        fields = ("id", "rawType", "targetRole", "timestamp", "payload")
        read_only_fields = fields


class EventAckSerializer(serializers.Serializer):
    event_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        max_length=100,
    )


class DeviceRegistrationSerializer(serializers.Serializer):
    device_token = serializers.CharField(max_length=500, trim_whitespace=True)
    device_type = serializers.ChoiceField(choices=FCMDevice.DEVICE_TYPE_CHOICES)


class DeviceUnregisterSerializer(serializers.Serializer):
    device_token = serializers.CharField(max_length=500, trim_whitespace=True)

from __future__ import annotations

from rest_framework import serializers

from realtime.models.events import EventLog


class EventLogSerializer(serializers.ModelSerializer):
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

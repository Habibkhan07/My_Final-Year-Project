from __future__ import annotations

from rest_framework import serializers

from realtime.models.events import EventLog


class EventLogSerializer(serializers.ModelSerializer):
    # ``kind`` is a fixed literal — every EventLog row is, by definition, an
    # event. Streams are transient and never persisted. The field exists so
    # sync-endpoint output matches the wire envelope shape, letting the
    # frontend dispatcher use a single switch on ``kind``.
    kind = serializers.SerializerMethodField()
    rawType = serializers.CharField(source="event_type", read_only=True)
    targetRole = serializers.CharField(source="target_role", read_only=True)
    timestamp = serializers.DateTimeField(source="created_at", read_only=True)

    class Meta:
        model = EventLog
        fields = ("kind", "id", "rawType", "targetRole", "timestamp", "payload")
        read_only_fields = fields

    def get_kind(self, _obj) -> str:
        return "event"


class EventAckSerializer(serializers.Serializer):
    event_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        max_length=100,
    )

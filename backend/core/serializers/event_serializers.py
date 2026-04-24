"""
EventLog egress + ACK ingress serializers.

Egress format matches the envelope pushed over WebSocket, so the Flutter
client can use the same parser for both live events and catch-up events.
"""
from __future__ import annotations

from rest_framework import serializers

from core.models import EventLog


class EventLogSerializer(serializers.ModelSerializer):
    """
    Read-only envelope for a persisted event.

    Field renames match the WebSocket payload contract:
        event_type  → rawType
        target_role → targetRole
        created_at  → timestamp
    """
    rawType = serializers.CharField(source="event_type", read_only=True)
    targetRole = serializers.CharField(source="target_role", read_only=True)
    timestamp = serializers.DateTimeField(source="created_at", read_only=True)

    class Meta:
        model = EventLog
        # Explicit allow-list — never ``__all__`` (no mass-assignment).
        fields = ("id", "rawType", "targetRole", "timestamp", "payload")
        read_only_fields = fields


class EventAckSerializer(serializers.Serializer):
    event_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        max_length=100,
    )

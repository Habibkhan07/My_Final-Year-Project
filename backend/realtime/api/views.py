"""
Realtime API Views — Event Recovery and Device Registration.
"""
from __future__ import annotations

from datetime import datetime

from django.utils.dateparse import parse_datetime
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from realtime.selectors import (
    MAX_SYNC_LIMIT,
    list_events_since,
    list_unacknowledged_critical,
)
from realtime.api.serializers import (
    DeviceRegistrationSerializer,
    DeviceUnregisterSerializer,
    EventAckSerializer,
    EventLogSerializer,
)
from realtime.services import DeviceService, EventAckService


def _parse_since(raw: str | None) -> datetime:
    if not raw:
        raise ValidationError({"since": ["This query parameter is required."]})
    parsed = parse_datetime(raw)
    if parsed is None:
        raise ValidationError({"since": ["Must be an ISO-8601 datetime."]})
    return parsed


def _parse_limit(raw: str | None) -> int | None:
    if raw in (None, ""):
        return None
    try:
        value = int(raw)
    except (TypeError, ValueError) as exc:
        raise ValidationError({"limit": ["Must be an integer."]}) from exc
    if value <= 0:
        raise ValidationError({"limit": ["Must be positive."]})
    return min(value, MAX_SYNC_LIMIT)


class EventSyncView(APIView):
    """Replay events the client missed while disconnected."""
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        since = _parse_since(request.query_params.get("since"))
        limit = _parse_limit(request.query_params.get("limit"))

        events = list(list_events_since(user=request.user, since=since, limit=limit))
        data = EventLogSerializer(events, many=True).data

        next_cursor = events[-1].created_at.isoformat().replace("+00:00", "Z") if events else None

        return Response(
            {
                "results": data,
                "next_cursor": next_cursor,
                "count": len(data),
            }
        )


class EventAckView(APIView):
    """Idempotently mark a batch of events as acknowledged."""
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        serializer = EventAckSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        EventAckService.acknowledge_events(
            user=request.user,
            event_ids=serializer.validated_data["event_ids"],
        )
        return Response(status=status.HTTP_204_NO_CONTENT)


class UnacknowledgedCriticalView(APIView):
    """Cold-start inbox: critical events the user never acted on."""
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        events = list_unacknowledged_critical(user=request.user)
        data = EventLogSerializer(events, many=True).data
        return Response({"results": data, "count": len(data)})


class RegisterDeviceView(APIView):
    """Register or refresh an FCM device token."""
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        serializer = DeviceRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        DeviceService.register_device(
            user=request.user,
            device_token=serializer.validated_data["device_token"],
            device_type=serializer.validated_data["device_type"],
        )
        return Response(status=status.HTTP_204_NO_CONTENT)


class UnregisterDeviceView(APIView):
    """Deactivate an FCM device token."""
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        serializer = DeviceUnregisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        DeviceService.unregister_device(
            user=request.user,
            device_token=serializer.validated_data["device_token"],
        )
        return Response(status=status.HTTP_204_NO_CONTENT)

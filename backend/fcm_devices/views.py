"""
FCM device registration endpoints — thin views, auth required.

Both endpoints scope the write to ``request.user``; token ownership can
only change via explicit reassignment inside ``DeviceService.register_device``.
"""
from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from fcm_devices.serializers import (
    DeviceRegistrationSerializer,
    DeviceUnregisterSerializer,
)
from fcm_devices.services.device_service import DeviceService


class RegisterDeviceView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        # SECURITY: the authenticated request.user is the sole source of the
        # device owner — the serializer never accepts a user field, so token
        # reassignment can only happen for the logged-in principal.
        serializer = DeviceRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        DeviceService.register_device(
            user=request.user,
            device_token=serializer.validated_data["device_token"],
            device_type=serializer.validated_data["device_type"],
        )
        return Response(status=status.HTTP_204_NO_CONTENT)


class UnregisterDeviceView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        # SECURITY: deactivate is scoped by (user=request.user, token=...) so
        # a hostile client cannot silently kill another user's device token.
        serializer = DeviceUnregisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        DeviceService.unregister_device(
            user=request.user,
            device_token=serializer.validated_data["device_token"],
        )
        return Response(status=status.HTTP_204_NO_CONTENT)

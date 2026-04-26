from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from realtime.devices.api.serializers import (
    DeviceRegistrationSerializer,
    DeviceUnregisterSerializer,
)
from realtime.devices.services import DeviceService


class RegisterDeviceView(APIView):
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
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        serializer = DeviceUnregisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        DeviceService.unregister_device(
            user=request.user,
            device_token=serializer.validated_data["device_token"],
        )
        return Response(status=status.HTTP_204_NO_CONTENT)

from __future__ import annotations

from rest_framework import serializers

from realtime.models.devices import FCMDevice


class DeviceRegistrationSerializer(serializers.Serializer):
    device_token = serializers.CharField(max_length=500, trim_whitespace=True)
    device_type = serializers.ChoiceField(choices=FCMDevice.DEVICE_TYPE_CHOICES)


class DeviceUnregisterSerializer(serializers.Serializer):
    device_token = serializers.CharField(max_length=500, trim_whitespace=True)

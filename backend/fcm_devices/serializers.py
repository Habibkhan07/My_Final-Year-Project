"""
Device registration serializers — strict ingress contracts.

Writable fields are whitelisted explicitly (never ``__all__``) so the client
cannot smuggle in ``user_id`` or ``is_active``. The authenticated user is
always derived server-side in the view.
"""
from __future__ import annotations

from rest_framework import serializers

from fcm_devices.models import FCMDevice


class DeviceRegistrationSerializer(serializers.Serializer):
    device_token = serializers.CharField(max_length=500, trim_whitespace=True)
    device_type = serializers.ChoiceField(choices=FCMDevice.DEVICE_TYPE_CHOICES)


class DeviceUnregisterSerializer(serializers.Serializer):
    device_token = serializers.CharField(max_length=500, trim_whitespace=True)

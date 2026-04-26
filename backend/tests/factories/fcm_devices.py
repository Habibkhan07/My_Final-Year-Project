"""Factories for fcm_devices app."""
from __future__ import annotations

import factory

from realtime.models import FCMDevice
from tests.factories.accounts import UserFactory


class FCMDeviceFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = FCMDevice

    user = factory.SubFactory(UserFactory)
    device_token = factory.Sequence(lambda n: f"fcm-token-{n:08d}")
    device_type = FCMDevice.DEVICE_ANDROID
    is_active = True

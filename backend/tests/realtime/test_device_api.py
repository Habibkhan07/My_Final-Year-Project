"""Contract tests for /api/devices/register and /api/devices/unregister."""
from __future__ import annotations

import pytest
from django.urls import reverse
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from realtime.models import FCMDevice
from tests.factories.accounts import UserFactory
from tests.factories.fcm_devices import FCMDeviceFactory


def _client_for(user) -> APIClient:
    token, _ = Token.objects.get_or_create(user=user)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")
    return client


@pytest.mark.django_db
def test_register_requires_authentication():
    response = APIClient().post(
        reverse("realtime:devices_register"),
        data={"device_token": "t", "device_type": "android"},
        format="json",
    )
    assert response.status_code == 401


@pytest.mark.django_db
def test_register_creates_new_token():
    user = UserFactory()
    response = _client_for(user).post(
        reverse("realtime:devices_register"),
        data={"device_token": "new-token", "device_type": "android"},
        format="json",
    )
    assert response.status_code == 204
    device = FCMDevice.objects.get(device_token="new-token")
    assert device.user == user
    assert device.is_active is True


@pytest.mark.django_db
def test_register_reassigns_token_across_users():
    alice = UserFactory()
    bob = UserFactory()
    FCMDeviceFactory(user=alice, device_token="shared-device", is_active=False)

    response = _client_for(bob).post(
        reverse("realtime:devices_register"),
        data={"device_token": "shared-device", "device_type": "ios"},
        format="json",
    )
    assert response.status_code == 204

    device = FCMDevice.objects.get(device_token="shared-device")
    assert device.user == bob
    assert device.device_type == "ios"
    assert device.is_active is True


@pytest.mark.django_db
def test_unregister_deactivates_owned_token():
    user = UserFactory()
    FCMDeviceFactory(user=user, device_token="mine", is_active=True)

    response = _client_for(user).post(
        reverse("realtime:devices_unregister"),
        data={"device_token": "mine"},
        format="json",
    )
    assert response.status_code == 204
    assert FCMDevice.objects.get(device_token="mine").is_active is False


@pytest.mark.django_db
def test_unregister_cannot_kill_foreign_token():
    alice = UserFactory()
    bob = UserFactory()
    FCMDeviceFactory(user=alice, device_token="alices-phone", is_active=True)

    response = _client_for(bob).post(
        reverse("realtime:devices_unregister"),
        data={"device_token": "alices-phone"},
        format="json",
    )
    # Silent: same 204, but the row is untouched.
    assert response.status_code == 204
    assert FCMDevice.objects.get(device_token="alices-phone").is_active is True

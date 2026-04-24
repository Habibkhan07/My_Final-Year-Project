"""
Device token lifecycle — write-side business logic.

FCM tokens are **globally unique** (unique=True) and may be reassigned when
a user logs out / logs in with a different account on the same physical
device. The reassignment branch is the reason this cannot be a simple
``update_or_create`` keyed on (user, token).
"""
from __future__ import annotations

import logging
from typing import Optional

from django.db import transaction

from fcm_devices.models import FCMDevice

logger = logging.getLogger(__name__)


class DeviceService:
    @staticmethod
    @transaction.atomic
    def register_device(*, user, device_token: str, device_type: str) -> FCMDevice:
        """
        Upsert an FCM token for ``user``.

        - New token → create, active.
        - Token already owned by this user → reactivate + refresh device_type.
        - Token owned by a different user (account switch on one device) →
          reassign to ``user`` and reactivate.
        """
        device: Optional[FCMDevice] = (
            FCMDevice.objects.select_for_update()
            .filter(device_token=device_token)
            .first()
        )

        if device is None:
            return FCMDevice.objects.create(
                user=user,
                device_token=device_token,
                device_type=device_type,
                is_active=True,
            )

        # Reassignment path — same physical device, different user account.
        if device.user_id != user.id:
            logger.info(
                "Reassigning FCM token from user=%s to user=%s",
                device.user_id,
                user.id,
            )
            device.user = user

        device.device_type = device_type
        device.is_active = True
        device.save(update_fields=["user", "device_type", "is_active", "updated_at"])
        return device

    @staticmethod
    @transaction.atomic
    def unregister_device(*, user, device_token: str) -> bool:
        """
        Deactivate a token, but only if it belongs to ``user``.

        Returns True if a row was deactivated. Returns False silently when
        the token does not exist or is owned by a different user — we do
        not leak ownership information via error responses.
        """
        updated = (
            FCMDevice.objects.filter(user=user, device_token=device_token)
            .select_for_update()
            .update(is_active=False)
        )
        return bool(updated)

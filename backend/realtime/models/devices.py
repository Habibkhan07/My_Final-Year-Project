from __future__ import annotations

from django.conf import settings
from django.db import models


class FCMDevice(models.Model):
    DEVICE_ANDROID = "android"
    DEVICE_IOS = "ios"
    DEVICE_TYPE_CHOICES = (
        (DEVICE_ANDROID, "Android"),
        (DEVICE_IOS, "iOS"),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="fcm_devices",
        help_text="Owner of this device token.",
    )
    device_token = models.CharField(
        max_length=500,
        unique=True,
        help_text="FCM registration token (globally unique across devices).",
    )
    device_type = models.CharField(
        max_length=10,
        choices=DEVICE_TYPE_CHOICES,
        help_text="Platform — drives per-platform FCM payload shape.",
    )
    is_active = models.BooleanField(
        default=True,
        help_text=(
            "False when FCM returned UNREGISTERED/INVALID_ARGUMENT. "
            "Do not delete — keep for audit."
        ),
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        app_label = "realtime"
        db_table = "fcm_devices_fcmdevice"
        verbose_name = "FCM Device"
        verbose_name_plural = "FCM Devices"
        indexes = [
            models.Index(fields=["user", "is_active"]),
        ]

    def __str__(self) -> str:
        return f"{self.user_id} · {self.device_type} · {self.device_token[:16]}…"

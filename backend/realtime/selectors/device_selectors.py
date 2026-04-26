"""Read-only queries on FCMDevice."""
from __future__ import annotations

from django.db.models import QuerySet

from realtime.models import FCMDevice


def active_devices_for_user(user_id: int) -> QuerySet[FCMDevice]:
    """Active FCM devices for the given user id (no joins — just the tokens)."""
    return FCMDevice.objects.filter(user_id=user_id, is_active=True)

"""
Import the Celery app at Django startup so ``@shared_task``-decorated
functions are discoverable (e.g. ``core.tasks.send_fcm_notification``).
"""
from __future__ import annotations

from core.celery import app as celery_app

__all__ = ("celery_app",)

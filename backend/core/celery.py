"""
Celery app for Karigar — picked up on worker boot via ``core.__init__``.

Broker defaults to Redis DB 1 (Channels uses DB 0) — see settings.py.
"""
from __future__ import annotations

import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

app = Celery("karigar")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()

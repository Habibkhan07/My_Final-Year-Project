"""
Firebase Admin SDK bootstrap.

Keeps initialization out of ``settings.py`` (no side effects during settings
import) and guards against re-initialization on Celery worker reloads or
tests that import settings multiple times.
"""
from __future__ import annotations

import logging
from pathlib import Path

import firebase_admin
from django.conf import settings
from firebase_admin import credentials

logger = logging.getLogger(__name__)


def init_firebase() -> None:
    """
    Initialize the default Firebase app exactly once.

    Reads the service-account JSON path from ``settings.FIREBASE_CREDENTIALS_PATH``.
    No-op when the default app is already registered — safe to call repeatedly
    from Django app startup, Celery worker boot, and test fixtures.
    """
    if firebase_admin._apps:
        return

    path = getattr(settings, "FIREBASE_CREDENTIALS_PATH", None)
    if not path:
        logger.warning(
            "FIREBASE_CREDENTIALS_PATH not configured; FCM dispatch will no-op."
        )
        return

    credentials_path = Path(path)
    if not credentials_path.exists():
        logger.warning(
            "Firebase credentials file not found at %s; FCM dispatch will no-op.",
            credentials_path,
        )
        return

    cred = credentials.Certificate(str(credentials_path))
    firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin SDK initialized.")

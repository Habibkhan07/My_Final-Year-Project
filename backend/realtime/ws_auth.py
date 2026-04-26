"""
WebSocket token authentication helper.

Keeps the consumer logic-less: it receives an already-authenticated user
(or None) and decides only whether to ``close(4001)`` or ``accept()``.

Uses DRF's built-in ``rest_framework.authtoken.Token`` — the same token
issued by the existing REST login endpoints. No JWT / no parallel auth path.
"""
from __future__ import annotations

import logging
from typing import Optional
from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AbstractBaseUser
from rest_framework.authtoken.models import Token

logger = logging.getLogger(__name__)
User = get_user_model()


def _extract_token(scope: dict) -> Optional[str]:
    """Pull ``?token=...`` from the WebSocket query string."""
    raw_qs = scope.get("query_string", b"")
    if isinstance(raw_qs, bytes):
        raw_qs = raw_qs.decode("utf-8", errors="ignore")
    params = parse_qs(raw_qs)
    tokens = params.get("token") or []
    return tokens[0] if tokens else None


@database_sync_to_async
def _resolve_user(token_key: str) -> Optional[AbstractBaseUser]:
    try:
        token = Token.objects.select_related("user").get(key=token_key)
    except Token.DoesNotExist:
        return None
    user = token.user
    if not user.is_active:
        return None
    return user


async def get_user_from_scope(scope: dict) -> Optional[AbstractBaseUser]:
    """
    Authenticate a WebSocket connection from its handshake scope.

    Returns the ``User`` on success, or ``None`` when the token is missing,
    unknown, or belongs to a deactivated account. The consumer decides how
    to respond to ``None`` (close code 4001).
    """
    token_key = _extract_token(scope)
    if not token_key:
        return None
    return await _resolve_user(token_key)

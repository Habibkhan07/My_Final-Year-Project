"""
Channel-layer group naming — the single source of truth.

Both the consumer (which subscribes a socket to a group) and the dispatch
services (which publish to a group) must format the same string. Keeping
this constant in one place prevents silent drift if the format ever
changes.
"""
from __future__ import annotations

#: Per-user channel-layer group. Carries both event and stream frames —
#: the historical ``_events`` suffix predates streams support and is
#: retained to avoid a coordinated frontend rename. See the consumer for
#: the full naming caveat.
USER_GROUP_TEMPLATE = "user_{user_id}_events"

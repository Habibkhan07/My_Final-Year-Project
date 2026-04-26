"""
Central event-type registry.

Single source of truth for every real-time event the Central Dispatch Hub
may emit. ``broadcast_event`` reads from here to auto-classify criticality
and to build FCM notification titles.

Adding a new event type:
    1. Add an enum member below.
    2. Register its metadata in ``EVENT_REGISTRY``.
    3. (Optional) Add a body renderer in ``core.tasks._build_notification_body``.
"""
from __future__ import annotations

from enum import Enum
from typing import TypedDict


class EventType(str, Enum):
    JOB_DISPATCHED = "job_dispatched"
    JOB_ACCEPTED = "job_accepted"
    QUOTE_GENERATED = "quote_generated"
    QUOTE_APPROVED = "quote_approved"
    TECH_EN_ROUTE = "tech_en_route"
    TECH_ARRIVED = "tech_arrived"
    JOB_COMPLETED = "job_completed"
    PAYMENT_RECEIVED = "payment_received"
    CHAT_MESSAGE = "chat_message"
    DISPUTE_OPENED = "dispute_opened"
    DISPUTE_RESOLVED = "dispute_resolved"
    WALLET_LOW_BALANCE = "wallet_low_balance"


class EventMeta(TypedDict):
    is_critical: bool
    display_name: str


EVENT_REGISTRY: dict[EventType, EventMeta] = {
    EventType.JOB_DISPATCHED:     {"is_critical": True,  "display_name": "New Job Available"},
    EventType.JOB_ACCEPTED:       {"is_critical": True,  "display_name": "Job Accepted"},
    EventType.QUOTE_GENERATED:    {"is_critical": True,  "display_name": "New Quote Ready"},
    EventType.QUOTE_APPROVED:     {"is_critical": True,  "display_name": "Quote Approved"},
    EventType.TECH_EN_ROUTE:      {"is_critical": False, "display_name": "Technician On The Way"},
    EventType.TECH_ARRIVED:       {"is_critical": False, "display_name": "Technician Has Arrived"},
    EventType.JOB_COMPLETED:      {"is_critical": True,  "display_name": "Job Completed"},
    EventType.PAYMENT_RECEIVED:   {"is_critical": False, "display_name": "Payment Received"},
    EventType.CHAT_MESSAGE:       {"is_critical": False, "display_name": "New Message"},
    EventType.DISPUTE_OPENED:     {"is_critical": True,  "display_name": "Dispute Opened"},
    EventType.DISPUTE_RESOLVED:   {"is_critical": True,  "display_name": "Dispute Resolved"},
    EventType.WALLET_LOW_BALANCE: {"is_critical": False, "display_name": "Low Wallet Balance"},
}


_DEFAULT_META: EventMeta = {"is_critical": False, "display_name": "Notification"}


def get_event_meta(event_type_string: str) -> EventMeta:
    """
    Return metadata for ``event_type_string``.

    Forward-compatible: unknown event strings return a safe default
    (``is_critical=False``, ``display_name="Notification"``) so callers
    emitting a brand-new event type never crash the dispatch pipeline,
    even if this registry hasn't been updated yet.
    """
    try:
        return EVENT_REGISTRY[EventType(event_type_string)]
    except (ValueError, KeyError):
        return _DEFAULT_META

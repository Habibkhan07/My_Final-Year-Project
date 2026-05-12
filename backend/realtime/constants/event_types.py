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
    # Renamed from JOB_DISPATCHED → JOB_NEW_REQUEST so the wire string matches
    # the Flutter WsFrameDispatcher key. Bookings broadcast this when a customer
    # finalizes an instant booking — see bookings/services/job_request_dispatch.py.
    JOB_NEW_REQUEST = "job_new_request"
    JOB_ACCEPTED = "job_accepted"
    # `booking_rejected` covers BOTH the technician-decline path
    # (`reason: "technician_declined"`) and the SLA-expiry path
    # (`reason: "sla_timeout"`). One event-type with a payload
    # discriminator keeps the customer-side surface a single subscriber
    # instead of forking the registry per pathway.
    BOOKING_REJECTED = "booking_rejected"
    QUOTE_GENERATED = "quote_generated"
    QUOTE_APPROVED = "quote_approved"
    TECH_EN_ROUTE = "tech_en_route"
    TECH_ARRIVED = "tech_arrived"
    # InDrive-style ARRIVED meeting flow: customer-side "I'm coming out"
    # acknowledgement. Lets the tech see that the customer noticed and is
    # walking out, so they aren't left guessing whether to cancel as no-show.
    CUSTOMER_ARRIVING = "customer_arriving"
    # ARRIVED → INSPECTING. Two callers in the orchestrator service emit
    # this: (1) `customer_arriving` auto-advances to INSPECTING and fires
    # this to the customer-side surface (no-op in practice — the customer
    # just refreshed locally — but recorded for audit completeness); (2)
    # the tech's fallback `start_inspection` call (used when the
    # customer never tapped "I'm coming out") fires it to the customer
    # so their screen flips from the ARRIVED map to the INSPECTING body
    # without a manual pull-to-refresh. Silent on the frontend — no
    # banner, no push — because the customer is physically next to the
    # tech when this fires; a notification would be redundant.
    INSPECTION_STARTED = "inspection_started"
    JOB_COMPLETED = "job_completed"
    PAYMENT_RECEIVED = "payment_received"
    CHAT_MESSAGE = "chat_message"
    DISPUTE_OPENED = "dispute_opened"
    DISPUTE_RESOLVED = "dispute_resolved"
    WALLET_LOW_BALANCE = "wallet_low_balance"
    # Tech-facing single-field balance patch. Fired by the wallet ledger
    # service after every WalletTransaction commit. The frontend dashboard
    # notifier consumes this via ``onWalletBalanceEvent`` to patch the
    # pill in place — no full reload. The new tech-only Wallet screen
    # also subscribes. Non-critical: no ACK needed; sync replay covers
    # offline reopens.
    WALLET_BALANCE_UPDATED = "wallet_balance_updated"

    # Booking orchestrator v1 (sprint 0008). All five are non-critical: none
    # of them gate money or service delivery on the recipient's ACK. Cash
    # collection confirms via the explicit POST response, not via an ACK on
    # ``payment_received``; quote/cancel/no-show/reschedule signals just flip
    # UI state on the counterparty. ``tech_reliability_penalty`` from the
    # v0.9 plan was deliberately dropped — ``EventLog.target_role`` does not
    # accept ``"admin"``, so the broadcast would fail at save. The
    # ``TechReliabilityIncident`` table replaces it; admin reads via Django
    # Admin (see flag: admin-realtime-channel-deferred).
    QUOTE_REVISION_REQUESTED = "quote_revision_requested"
    QUOTE_DECLINED = "quote_declined"
    BOOKING_CANCELLED = "booking_cancelled"
    BOOKING_NO_SHOW = "booking_no_show"
    BOOKING_RESCHEDULED = "booking_rescheduled"


class EventMeta(TypedDict):
    is_critical: bool
    display_name: str


EVENT_REGISTRY: dict[EventType, EventMeta] = {
    EventType.JOB_NEW_REQUEST:    {"is_critical": True,  "display_name": "New Job Available"},
    # `job_accepted` and `booking_rejected` are both informational — no money
    # or service-delivery flow gates on the customer ACK'ing them. EventLog
    # persistence + sync-replay cover the offline case; the per-event ACK
    # contract that ``is_critical`` opts into would only add steady-state
    # delivery telemetry, which is overkill for "your tech accepted" /
    # "your dispatch was unsuccessful." Both started life as `True` from a
    # thoughtless mirror of the technician-side `JOB_NEW_REQUEST` registry
    # entry; the corrections landed with flag #22 (booking_rejected) and
    # flag #25 (job_accepted). `display_name` for JOB_ACCEPTED reads
    # "Booking confirmed" rather than the technician-centric "Job Accepted"
    # because the customer is the audience.
    EventType.JOB_ACCEPTED:       {"is_critical": False, "display_name": "Booking confirmed"},
    EventType.BOOKING_REJECTED:   {"is_critical": False, "display_name": "Booking unavailable"},
    EventType.QUOTE_GENERATED:    {"is_critical": True,  "display_name": "New Quote Ready"},
    EventType.QUOTE_APPROVED:     {"is_critical": True,  "display_name": "Quote Approved"},
    EventType.TECH_EN_ROUTE:      {"is_critical": False, "display_name": "Technician On The Way"},
    EventType.TECH_ARRIVED:       {"is_critical": False, "display_name": "Technician Has Arrived"},
    EventType.CUSTOMER_ARRIVING:  {"is_critical": False, "display_name": "Customer is coming out"},
    EventType.INSPECTION_STARTED: {"is_critical": False, "display_name": "Inspection started"},
    EventType.JOB_COMPLETED:      {"is_critical": True,  "display_name": "Job Completed"},
    EventType.PAYMENT_RECEIVED:   {"is_critical": False, "display_name": "Payment Received"},
    EventType.CHAT_MESSAGE:       {"is_critical": False, "display_name": "New Message"},
    EventType.DISPUTE_OPENED:     {"is_critical": True,  "display_name": "Dispute Opened"},
    EventType.DISPUTE_RESOLVED:   {"is_critical": True,  "display_name": "Dispute Resolved"},
    EventType.WALLET_LOW_BALANCE: {"is_critical": False, "display_name": "Low Wallet Balance"},
    EventType.WALLET_BALANCE_UPDATED: {"is_critical": False, "display_name": "Wallet Updated"},
    EventType.QUOTE_REVISION_REQUESTED: {"is_critical": False, "display_name": "Customer wants to bargain"},
    EventType.QUOTE_DECLINED:           {"is_critical": False, "display_name": "Quote declined"},
    EventType.BOOKING_CANCELLED:        {"is_critical": False, "display_name": "Booking cancelled"},
    EventType.BOOKING_NO_SHOW:          {"is_critical": False, "display_name": "No-show reported"},
    EventType.BOOKING_RESCHEDULED:      {"is_critical": False, "display_name": "Booking rescheduled"},
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

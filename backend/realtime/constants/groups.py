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

#: Per-booking tracking subgroup. Used by the live-tracking stream
#: (``streamType=tech_gps``) so the customer's WS connection can
#: subscribe to a specific booking's GPS feed without receiving every
#: tech's location frames. The technician's location-ingress endpoint
#: publishes to this group; ``SystemEventConsumer`` joins the connection
#: to the group only after authorization checks (booking participant
#: AND non-terminal status). See ``STREAMS_TECH_GPS.md``.
TRACKING_JOB_GROUP_TEMPLATE = "tracking_job_{booking_id}"

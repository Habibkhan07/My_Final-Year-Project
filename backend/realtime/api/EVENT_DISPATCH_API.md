# Event Dispatch Hub — API Contract

Central pipeline that fans any real-time domain event to both the
in-app WebSocket stream and FCM push notifications, while persisting
every event for offline recovery.

---

## Event Envelope (the universal payload)

Every event — whether delivered by WebSocket frame, replayed by the
sync endpoint, or surfaced as a pending critical prompt — uses this
exact JSON shape. The Flutter client has ONE parser.

```json
{
  "kind": "event",
  "id": "f1c9...-...-...-...-...",
  "rawType": "job_accepted",
  "targetRole": "customer",
  "timestamp": "2026-04-24T07:12:33.102000Z",
  "recipient_user_id": 42,
  "expires_at": "2026-04-24T07:17:33.102000Z",
  "payload": { "job_id": "abc-123", "technician_name": "Ali R." }
}
```

| Field               | Type             | Notes                                                                 |
|---------------------|------------------|-----------------------------------------------------------------------|
| `kind`              | literal          | Always `"event"`. Discriminates events from streams on the same socket. |
| `id`                | UUIDv4           | Primary key of the `EventLog` row. Use to `ACK`.                      |
| `rawType`           | string           | Registered key in `core.constants.event_types.EventType`.             |
| `targetRole`        | enum             | `"customer"` \| `"technician"`. Drives client-side routing.           |
| `timestamp`         | ISO-8601         | UTC with trailing `Z`. Server-authoritative.                          |
| `recipient_user_id` | int              | Numeric `User.id` of the intended recipient. Always set. Frontend pipeline drops frames whose recipient does not match the authenticated user (defence-in-depth against multi-account device FCM tap races, on top of channel-layer routing). |
| `expires_at`        | ISO-8601 \| null | UTC absolute expiry for SLA-bounded events. Pinned to the same instant as `timestamp` (envelope and `EventLog.expires_at` reference one server-side `now`, so /sync/ replay never drifts from the original WS frame). Frontend pipeline drops past-expiry frames at `SystemEventNotifier` ingress (server-anchored clock). `null` when the dispatcher caller passed no `expires_in_seconds` (event has no SLA). |
| `payload`           | object           | Feature-specific dict. JSON-serializable.                             |

`is_critical` is **not** sent on the wire — it lives server-side in the
registry and controls whether the Flutter client must call `/ack/`.

Stream frames travel on the same socket but use a different envelope
shape (`kind: "stream"`). See `STREAM_DISPATCH_API.md` for the contract.

**Backwards compatibility.** Both fields are tolerated as null on the
client side (`SystemEventModel` declares them optional), which kept the
phased rollout safe: the frontend pipeline filters shipped first and
stayed dormant until the backend started emitting non-null values.
The filters are now live. Pre-flag-#19 `EventLog` rows (created before
the migration) keep `expires_at = null` and replay through /sync/
unchanged.

---

## Dumb-UI Fields

The envelope intentionally contains no UI strings. The Flutter client
maps `rawType` → localized title/body using `event_types.dart`. This
matches the Dumb-UI principle used elsewhere in the app.

---

## `GET /api/events/sync/`

Catch up on events missed while disconnected. Call this on every
WebSocket reconnect.

**Auth:** DRF Token (`Authorization: Token <key>`).

**Query Parameters**

| Name    | Required | Notes                                                        |
|---------|----------|--------------------------------------------------------------|
| `since` | yes      | ISO-8601 timestamp. Returns events strictly after this.      |
| `limit` | no       | Default 50, max 100.                                         |

**200 OK**

```json
{
  "results": [ /* Event envelopes, oldest-first */ ],
  "next_cursor": "2026-04-24T07:12:33.102000Z",
  "count": 50
}
```

When `count < limit`, the client has reached the end of the backlog.
Otherwise pass `next_cursor` back as `since` on the next call.

**Error envelopes**

- `400 validation_error` — `since` missing or not ISO-8601.
- `401 unauthorized` — token missing/invalid.

```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid input data.",
  "errors": { "since": ["Must be an ISO-8601 datetime."] }
}
```

---

## `POST /api/events/ack/`

Idempotently mark critical events as acknowledged. Double-acking is a
no-op.

**Auth:** DRF Token.

**Request Body**

```json
{ "event_ids": ["uuid-1", "uuid-2", "uuid-3"] }
```

| Field       | Type         | Constraints             |
|-------------|--------------|-------------------------|
| `event_ids` | list<UUIDv4> | 1–100 items per request |

**Responses**

- `204 No Content` — one or more rows updated (or all were already ack'd).
- `400 validation_error` — malformed UUIDs or wrong type.
- `401 unauthorized`.

**Security.** Foreign `event_ids` (belonging to another user) are
silently ignored, not acknowledged, and not disclosed via the
response body.

---

## `GET /api/events/unacknowledged/`

Critical events from the last 24 h that the user never ack'd. Call
on cold start to decide whether to route the user into a pending-action
screen (e.g., a dispatched job awaiting Accept/Decline).

**Auth:** DRF Token.

**200 OK**

```json
{
  "results": [ /* Event envelopes */ ],
  "count": 3
}
```

Stale events (> 24 h) and already-ack'd events are excluded server-side.

---

## WebSocket Channel

```
ws://<host>/ws/events/?token=<drf_auth_token>
```

**Handshake**
- Missing/unknown token → socket closed with code **4001**.
- Otherwise the socket joins the Redis group `user_<id>_events`.

**Frames**
- Server → Client only. The server **ignores** anything the client sends.
- Every frame is a single JSON envelope (shape above).

**Expected client loop**

1. Receive frame → dispatch by `rawType`.
2. If the registry says `is_critical`, store the `id` in an ACK buffer.
3. On backgrounding / disconnect, drain the ACK buffer via `POST /api/events/ack/`.
4. On reconnect, call `GET /api/events/sync/?since=<last_known_timestamp>`.

---

## Integration Example (backend caller)

```python
from realtime.events.services import EventDispatchService

# Event with no SLA — expires_at on the wire is null.
EventDispatchService.broadcast_event(
    user=job.customer,
    target_role="customer",
    event_type="job_accepted",
    payload={"job_id": str(job.id), "technician_name": technician.full_name},
)

# SLA-bounded event — expires_at = now + delta, denormalized onto EventLog.
EventDispatchService.broadcast_event(
    user=technician.user,
    target_role="technician",
    event_type="job_new_request",
    payload={"job_id": str(job.id), ...},
    expires_in_seconds=300,
)
```

`recipient_user_id` is set automatically from the `user` argument — there
is no per-call kwarg for it. `expires_in_seconds` is the only knob.

This single call atomically:

1. Writes an `EventLog` row (so the event survives outages).
2. Pushes the envelope into the recipient's WebSocket group.
3. Queues `send_fcm_notification` on Celery for their active devices.

Channels down? FCM down? Broker down? Each barrel is wrapped in its
own `try/except`, so the caller's DB transaction is never rolled back
by a notification failure.

---

## Backend Implementation Structure

The `realtime` app is organized into sub-modules for traceability:

- **`realtime.events`**: Owns persistence (`EventLog`), the Dispatch/ACK services, and WebSocket transport (`consumers`, `routing`, `ws_auth`).
- **`realtime.streams`**: Owns the transient stream publisher (`publish_stream`). No persistence, no FCM. See `STREAM_DISPATCH_API.md`.
- **`realtime.devices`**: Owns FCM device registration (`FCMDevice`) and the Celery background tasks.
- **`realtime.constants`**: Cross-cutting constants (`event_types`, `groups`) shared by the above.

---

## Event registry — wire strings + criticality

Source of truth: `realtime/constants/event_types.py::EVENT_REGISTRY`. Frontend
keys off the wire string; renaming any of these requires a coordinated
mobile change.

| Wire string | `is_critical` | Display name | Producer |
|---|---|---|---|
| `job_new_request`           | true  | "New Job Available"       | `bookings.services.job_request_dispatch` |
| `job_accepted`              | false | "Booking confirmed"       | `bookings.services.job_request_action` |
| `booking_rejected`          | false | "Booking unavailable"     | `bookings.services.job_request_action` + SLA timeout |
| `quote_generated`           | true  | "New Quote Ready"         | `orchestrator.submit_quote` |
| `quote_approved`            | true  | "Quote Approved"          | `orchestrator.approve_quote` |
| `tech_en_route`             | false | "Technician On The Way"   | `orchestrator.en_route` (auto + manual) |
| `tech_arrived`              | false | "Technician Has Arrived"  | `orchestrator.arrived` (auto + manual) |
| `job_completed`             | true  | "Job Completed"           | `orchestrator.mark_complete_with_cash` |
| `payment_received`          | false | "Payment Received"        | `orchestrator.mark_complete_with_cash` |
| `chat_message`              | false | "New Message"             | (chat sprint, not yet shipped) |
| `dispute_opened`            | true  | "Dispute Opened"          | `orchestrator.open_dispute` |
| `dispute_resolved`          | true  | "Dispute Resolved"        | `orchestrator.admin_resolve_dispute` |
| `wallet_low_balance`        | false | "Low Wallet Balance"      | (finance sprint, not yet shipped) |
| `quote_revision_requested`  | false | "Customer wants to bargain" | `orchestrator.request_revision` |
| `quote_declined`            | false | "Quote declined"          | `orchestrator.decline_quote` |
| `booking_cancelled`         | false | "Booking cancelled"       | `orchestrator.cancel_by_customer` / `cancel_by_tech` |
| `booking_no_show`           | false | "No-show reported"        | `orchestrator.mark_no_show` |
| `booking_rescheduled`       | false | "Booking rescheduled"     | `orchestrator.reschedule` |

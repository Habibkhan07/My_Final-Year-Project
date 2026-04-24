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
  "id": "f1c9...-...-...-...-...",
  "rawType": "job_accepted",
  "targetRole": "customer",
  "timestamp": "2026-04-24T07:12:33.102000Z",
  "payload": { "job_id": "abc-123", "technician_name": "Ali R." }
}
```

| Field        | Type     | Notes                                                                 |
|--------------|----------|-----------------------------------------------------------------------|
| `id`         | UUIDv4   | Primary key of the `EventLog` row. Use to `ACK`.                      |
| `rawType`    | string   | Registered key in `core.constants.event_types.EventType`.             |
| `targetRole` | enum     | `"customer"` \| `"technician"`. Drives client-side routing.           |
| `timestamp`  | ISO-8601 | UTC with trailing `Z`. Server-authoritative.                          |
| `payload`    | object   | Feature-specific dict. JSON-serializable.                             |

`is_critical` is **not** sent on the wire — it lives server-side in the
registry and controls whether the Flutter client must call `/ack/`.

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
from core.services.event_dispatch_service import EventDispatchService

EventDispatchService.broadcast_event(
    user=job.customer,
    target_role="customer",
    event_type="job_accepted",
    payload={"job_id": str(job.id), "technician_name": technician.full_name},
)
```

This single call atomically:

1. Writes an `EventLog` row (so the event survives outages).
2. Pushes the envelope into the customer's WebSocket group.
3. Queues `send_fcm_notification` on Celery for their active devices.

Channels down? FCM down? Broker down? Each barrel is wrapped in its
own `try/except`, so the caller's DB transaction is never rolled back
by a notification failure.

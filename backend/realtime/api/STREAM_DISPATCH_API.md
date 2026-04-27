# Stream Dispatch — API Contract

Transient, fire-and-forget realtime channel for traffic that is **not**
an event. Examples: live GPS telemetry, the live wallet-balance display
number, AI-chatbot token streams, chat typing indicators.

Streams share the WebSocket socket, the consumer, and the per-user
channel-layer group with events — but use a different envelope, a
different publisher, and a fundamentally different contract.

---

## Why streams are not events

| Property              | Event                              | Stream                             |
|-----------------------|------------------------------------|------------------------------------|
| Semantic              | A *fact* about something happened. | A *value* of current state.        |
| Persistence           | `EventLog` row, indexed.           | None — transient.                  |
| Offline fallback      | FCM via Celery.                    | None — drop on disconnect.         |
| ACK contract          | Critical events require ACK.       | None.                              |
| Replay on reconnect   | `GET /api/events/sync/`.           | Re-fetch state via REST if needed. |
| Frequency             | Discrete, business-paced.          | Continuous, can be sub-second.     |

Routing transient state through the event pipeline would thrash the DB
and waste FCM quota for no benefit. Routing critical events through the
stream pipeline would silently lose them when the user is offline. The
two pipelines are deliberately separated at the publisher level so a
service cannot accidentally use the wrong one.

---

## Stream Envelope

Every stream frame on the wire:

```json
{
  "kind": "stream",
  "streamType": "wallet_balance",
  "timestamp": "2026-04-27T07:12:33.102000Z",
  "payload": { "balance": 4237 }
}
```

| Field        | Type     | Notes                                                                  |
|--------------|----------|------------------------------------------------------------------------|
| `kind`       | literal  | Always `"stream"`. The frontend dispatcher switches on this.           |
| `streamType` | string   | Identifies the stream (e.g. `"telemetry"`, `"wallet_balance"`).        |
| `timestamp`  | ISO-8601 | UTC with trailing `Z`. Server-authoritative.                           |
| `payload`    | object   | Stream-specific dict. JSON-serializable.                               |

No `id`, no `targetRole`, no `is_critical`. Streams are anonymous frames
that paint state — there is nothing to correlate, route by role, or
elevate to FCM.

---

## WebSocket Channel

Streams use the **same socket** as events:

```
ws://<host>/ws/events/?token=<drf_auth_token>
```

(The URL keeps the `_events` suffix for back-compat with the existing
frontend; see the consumer module docstring for the full naming caveat.)

Frames from both pipelines arrive on the same connection. The frontend
dispatcher uses `kind` to route:

```dart
switch (frame['kind']) {
  case 'event':  systemEventNotifier.processEvent(frame); break;
  case 'stream': streamRouter.dispatch(frame); break;
}
```

---

## Currently-supported `streamType` values

None yet — this patch ships the dispatch primitive without any concrete
stream callers. As stream types are added, document them here:

| `streamType` | Source | Frontend handler | Notes |
|--------------|--------|------------------|-------|
| _(none yet)_ |        |                  |       |

When adding a new stream type, also update the frontend dispatcher's
switch and the relevant feature notifier so it can consume the payload.

---

## Why no `StreamType` enum (yet)

Events have a registry (`realtime/constants/event_types.py`) because each
type carries metadata: `is_critical` controls whether the client must
ACK, `display_name` builds the FCM notification title.

Streams have no registry-worthy metadata — they are opaque pipes. A
string parameter validated by the call site is sufficient. Promote
`streamType` to an enum the day a stream type needs registered metadata
(e.g. a per-stream rate limit, a per-stream TTL on the wire). Until
then, a string keeps the surface area minimal.

---

## Publishing from a Service

```python
from realtime.streams import publish_stream

publish_stream(
    user=technician.user,
    stream_type="wallet_balance",
    payload={"balance": new_balance},
)
```

Single call. No transaction wrapping needed — the publisher does no DB
writes. Network errors (Redis down) are absorbed and logged at WARNING.
Coding errors above the `group_send` line propagate so bugs surface in
dev instead of disappearing into a log.

---

## Ingress (REST → `publish_stream`)

When a stream needs to be **client-originated** (e.g. chat typing
indicators, future client-side telemetry), the ingress path is a thin
DRF view rather than the WebSocket's `receive()` handler. The consumer
stays one-way and logic-less.

Template (no concrete endpoint shipped in this patch):

```python
class TypingIndicatorView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request, conversation_id):
        recipient = get_recipient(request.user, conversation_id)
        publish_stream(
            user=recipient,
            stream_type="chat_typing",
            payload={"from_user_id": request.user.id, "is_typing": True},
        )
        return Response(status=204)
```

Why REST, not WebSocket ingress:

* Realistic typing-indicator frequency is 1–3 frames/sec — HTTP per
  frame is fine.
* REST gives us the existing auth interceptor, error envelope, and the
  4-step error pipeline for free.
* WebSocket ingress would require reimplementing auth and validation on
  a path that cannot return clean errors anyway.

Defer the WebSocket-ingress decision until a stream type demonstrably
needs it (something genuinely high-frequency like canvas drawing or
audio levels).

---

## What this patch ships

1. The `kind` discriminator on every frame (events and streams).
2. `realtime/streams/dispatch.py` — `publish_stream(...)` primitive.
3. The consumer's `system_stream` handler — mirror of `system_event`.

It does **not** ship:

* Any concrete `streamType` (no callers yet).
* A REST ingress endpoint (lands with the first client-originated
  stream type).
* A `StreamType` enum (lands when a stream type needs metadata).
* A `/sync/` equivalent for streams (would defeat the point — streams
  are by definition not recoverable).

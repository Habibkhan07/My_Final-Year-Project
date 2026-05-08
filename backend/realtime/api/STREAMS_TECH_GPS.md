# Stream contract: `tech_gps`

Live GPS feed from a technician's foreground location service to subscribed
customers (and any future admin watcher). Delivered over the same WebSocket
as events but using the **stream envelope** (`kind: "stream"`) — no
`EventLog` row, no FCM fallback, no ACK contract.

| Property | Value |
|---|---|
| `streamType` | `tech_gps` |
| Channel-layer group | `tracking_job_{booking_id}` (per-booking, dynamic) |
| Cadence | 5-second tick from the tech's foreground location service |
| Server-side rate limit | 4 seconds per (tech, booking) at the ingress endpoint |
| Persistence | None (no `EventLog` row, no FCM, no ACK) |

---

## Wire envelope

```json
{
  "kind": "stream",
  "streamType": "tech_gps",
  "timestamp": "2026-05-08T10:23:45Z",
  "payload": {
    "lat": 31.5204,
    "lng": 74.3587,
    "accuracy_meters": 8.5,
    "heading": 145.0,
    "booking_id": 123
  }
}
```

`accuracy_meters` and `heading` are optional (the tech's device may not
provide them on every frame).

---

## Subscription

The customer's WebSocket subscribes via an upstream message:

```json
{ "action": "subscribe_tracking", "booking_id": 123 }
```

Unsubscribe (e.g. when leaving the booking-detail screen):

```json
{ "action": "unsubscribe_tracking", "booking_id": 123 }
```

### Authorization

`SystemEventConsumer` validates each subscribe call:

* The user must be the booking's customer **or** the booking's assigned
  technician.
* The booking must be in a non-terminal status (Audit P2-07 — a stale
  foreground service still publishing after CANCELLED / COMPLETED must
  not leak the tech's location to the customer).

Authorization failures **silently drop** (no error frame back) so the
existence / status of a booking is not leaked to a non-participant. A
warning is logged server-side for diagnosis.

### Connection lifecycle

* Subscriptions are connection-local. On WS reconnect, the frontend
  must re-issue `subscribe_tracking` for any booking it's still
  watching. The backend exposes the API; the frontend (Session 4)
  handles reconnect resubscription.
* `disconnect()` cleans up every joined `tracking_job_*` group before
  the user-group cleanup so an in-flight stream frame never fans out
  to a half-disconnected socket.

---

## Ingress endpoint

`POST /api/bookings/{booking_id}/tech-location/`

**Auth**: `IsAuthenticated`; the caller must be the booking's assigned
technician (other roles get `403 not_a_technician` / `403 not_assigned_to_you`).

**Body**:
```json
{
  "lat": 31.5204,
  "lng": 74.3587,
  "accuracy_meters": 8.5,
  "heading": 145.0
}
```

**Response (`200 OK`)**:
```json
{
  "published": true,
  "transition_fired": "ARRIVED"
}
```

`transition_fired` is the new `JobBooking.status` string when
`auto_transition.evaluate_on_location` flipped the booking, or `null`
when no auto-transition was triggered. The view publishes the stream
frame **before** invoking `evaluate_on_location` so customers see the
GPS dot move even on the same tick that flips the status.

**Errors**:
| Status | `code` | When |
|---|---|---|
| 400 | `validation_error` | `lat` / `lng` out of range or missing |
| 403 | `not_a_technician` | Caller has no `tech_profile` |
| 403 | `not_assigned_to_you` | Caller is not this booking's tech |
| 404 | `booking_not_found` | No booking with that id |
| 429 | `too_many_requests` | Second call within 4 s for the same (tech, booking) |

**Terminal-status no-op**: when the booking is in a terminal status
the view returns `200 OK` with `published: false` and
`transition_fired: null` — neither the stream nor the auto-transition
fires. This absorbs stale frames from a foreground service that hasn't
yet noticed the booking ended.

### Throttling

A process-local TTL dict keyed by `(tech_user.id, booking_id)` with a 4-second
window. Multi-worker Daphne deployments allow N×4s effective rate (one slot
per worker). This is acceptable for v1 — see `flag.md::tech-location-rate-limit-not-distributed`
for the proper distributed (Redis-backed token-bucket) fix.

---

## Client-side staleness

The customer's frontend should display a soft "Technician offline" banner
if no frame has arrived in 60 seconds (sprint meta §10). Stream-staleness
detection is purely a client concern — the backend does not emit
"stale" events, because stream frames are inherently best-effort.

---

## Why streams, not events

GPS frames are **state values**, not facts. A dropped frame is corrected
by the next frame; persisting them would thrash `EventLog` for no benefit.
The only reason to use the event channel for GPS would be a guaranteed-
delivery requirement, which the product spec explicitly does not have
(the customer's expectation is "approximately where the tech is now",
not "every step the tech took"). See `EVENT_DISPATCH_API.md` for the
events-vs-streams boundary.

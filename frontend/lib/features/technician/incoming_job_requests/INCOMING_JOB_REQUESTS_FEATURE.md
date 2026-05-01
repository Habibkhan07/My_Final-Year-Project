# Incoming Job Requests Feature
**Layer status**: Domain ✅ · Data ✅ (parse-side only) · Presentation ⏳ (queue + stub screen ✅, real card widget pending) · Repository ⏳ (accept/decline endpoint not yet built backend-side)

---

## Overview

Receives `job_new_request` realtime events for the technician audience and surfaces them as a list of pending requests for the technician to accept or decline within the SLA window. The backend is end-to-end authoritative on dispatch, payout, and SLA timing — the technician's app only renders typed state and (eventually) posts an accept/decline.

**Backend contract**: `backend/bookings/api/BOOKINGS_API.md` §1.2 (event payload) and §2.3–§2.5 (Flutter integration).

**Realtime channel**: shared WebSocket `ws/events/`, FCM fallback. Routed by `WsFrameDispatcher` → `SystemEventNotifier` → this feature's `IncomingJobQueueNotifier`. See `lib/core/realtime/REALTIME_EVENTS_FEATURE.md` for the transport layer.

---

## Architectural pattern — Per-event feature wiring

This feature is the reference implementation of the rule documented in `CLAUDE.md` → "Per-event feature wiring":

- **Audience-first placement**: lives under `features/technician/`, not under `features/booking/` (which is the customer's checkout). The event is *about* a booking but only *received* by the technician.
- **Subscriber pattern**: `IncomingJobQueueNotifier` (`@Riverpod(keepAlive: true)`) calls `ref.listen(systemEventProvider, …)` and filters by `SystemEventType.jobNewRequest`. Adding a future event = a new notifier in its own feature, never an edit to `core/realtime`'s notifier code.
- **List-route screen**: `EventUrgencyRouter._listRouteEvents` includes `jobNewRequest`, so subsequent events while the screen is mounted skip the push and update the list in place.
- **Wake-up at boot is load-bearing**: the notifier MUST subscribe to `systemEventProvider` before the WS connect cascade. `incomingJobQueueProvider` is registered in `realtimeBootHooksProvider` (declared at the bottom of `app_lifecycle_orchestrator.dart`); `bootAfterAuth` iterates that registry and reads every entry. Adding a future list-route event = append its queue provider to the registry, never edit `bootAfterAuth`.

---

## Domain Layer

### Entity — `JobNewRequest`
`lib/features/technician/incoming_job_requests/domain/entities/job_new_request.dart`

Freezed immutable. Fed by the `job_new_request` realtime event payload (BOOKINGS_API.md §1.2).

| Field | Type | Description |
| :--- | :--- | :--- |
| `jobId` | `int` | `JobBooking.id` — primary key the technician's accept/decline call will use. |
| `serviceName` | `String` | More-specific catalog name: sub-service if set, parent service otherwise. |
| `bookingType` | `BookingType` | `inspection` / `fixedGig` / `laborGig`. Drives the on-site flow (Build Quote vs Mark Complete). Always non-null in the domain — the mapper applies the §2.5 default. |
| `payoutRupees` | `int` | Net technician payout in rupees (server already applied 20 % platform commission). Wire is integer-string for parse-fidelity; mapper parses once. |
| `payoutContext` | `String?` | Server-picked prose ("Inspection visit — quote built on-site", etc.). Rendered verbatim under the payout (Dumb-UI). Nullable for replayed pre-rollout EventLog rows; widgets hide the line when null. |
| `scheduledStart` | `DateTime` | UTC. Widgets call `.toLocal()` for display. |
| `expiresAt` | `DateTime` | Anchored on the event's envelope `timestamp` + `expires_in_seconds`. Anchoring on receipt time would skew slightly later than the server SLA — see "Known limitations" below. |

### Enum — `BookingType`
`lib/features/technician/incoming_job_requests/domain/entities/booking_type.dart`

Three cases: `inspection`, `fixedGig`, `laborGig`. Wire enum strings (`INSPECTION` / `FIXED_GIG` / `LABOR_GIG`) → typed value at the mapper boundary.

### Failures — `IncomingJobFailure` (sealed class)
`lib/features/technician/incoming_job_requests/domain/failures/incoming_job_failure.dart`

Sparse this sprint — accept/decline endpoints don't exist yet. Only `MalformedJobPayload` is modeled. Network / validation / server failures will land alongside the repository when the accept flow ships.

### Repository Interface — `⏳ pending`
Will be added when the backend accept endpoint lands (BOOKINGS_API.md §1.1 marks it as a separate sprint).

### Use Cases — `⏳ pending`
None this sprint. Accept/decline use cases will land alongside the repository.

---

## Data Layer

### Wire Model — `JobNewRequestPayloadModel`
`lib/features/technician/incoming_job_requests/data/models/job_new_request_payload_model.dart`

Freezed + `fromJson`. **Critical**: `bookingType` and `payoutContext` are nullable on this model so replayed pre-rollout EventLog rows (BOOKINGS_API.md §2.5) deserialize without throwing. The domain entity's `BookingType` is non-null because the mapper applies the default.

### Mapper — `JobNewRequestMapper.fromSystemEvent`
`lib/features/technician/incoming_job_requests/data/mappers/job_new_request_mapper.dart`

Single boundary where wire strings become typed values:
- Integer-string `payout` → `int`. Non-numeric → returns null + logs.
- ISO-8601 `scheduledStartIso` → `DateTime` (UTC). Unparseable → returns null + logs.
- Wire enum string `bookingType` → `BookingType`. Null or unknown → defaults to `BookingType.laborGig` (§2.5 neutral layout).
- Envelope `timestamp + expires_in_seconds` → `expiresAt`.

Returns `null` on any malformed payload — the dispatcher's policy is "drop and log", and matching that policy here keeps the queue notifier's filter loop simple.

### Data Sources — `⏳ pending`
Realtime events ingest through `core/realtime`'s `EventRemoteDataSource` (WebSocket + REST sync). No feature-specific data source this sprint. Accept/decline `RemoteDataSource` will land with the repository.

### Repository Implementation — `⏳ pending`
See above.

---

## Presentation Layer

### State — `IncomingJobQueueState`
`lib/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_state.dart`

Freezed. Single field: `List<JobNewRequest> queue`. FIFO arrival order; widget layer is free to sort by `expiresAt` for display.

### Notifier — `IncomingJobQueueNotifier`
`lib/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart`

`@Riverpod(keepAlive: true)`. In `build()`:
1. Subscribes to `systemEventProvider` via `ref.listen`.
2. Skips id-equality housekeeping rebuilds (mirrors the orchestrator's pattern).
3. Filters by `SystemEventType.jobNewRequest`.
4. Maps via `JobNewRequestMapper.fromSystemEvent`; null → silent drop (mapper logged).
5. Defensive per-`jobId` dedup (system-level dedup already covers same-event-id dups; this guard covers a re-broadcast with a fresh event id for the same booking).
6. Appends to the queue.

Exposes `removeRequest(int jobId)` for the screen to call when the technician dismisses / declines / accepts.

### Screen — `IncomingJobRequestScreen` (stub)
`lib/features/technician/incoming_job_requests/presentation/screens/incoming_job_request_screen.dart`

Stub: renders the queue as a flat ListTile list. Auto-pops on empty queue (the screen is router-pushed, not user-navigated). Replace the body with the real per-`BookingType` card widget.

### Widget — `⏳ pending`
The real card widget switches on `BookingType` per BOOKINGS_API.md §2.4 (Inspection → Build Quote affordance; Fixed/Labor → Mark Complete + optional upsell). `payoutContext` rendered verbatim under the payout.

### DI — `dependency_injection.dart`
Currently empty. The queue notifier is exposed by codegen on its own. Will fill out when the repository ships.

---

## Realtime Wiring

```
job_new_request event arrives over ws/events/  (or FCM, or sync replay)
                  │
                  ▼
       WsFrameDispatcher  (kind=event)
                  │
                  ▼
       SystemEventNotifier  (dedup + same-type order guard)
                  │
                  │  state.latestEvent set
                  ├──────────────────────────────────────────────┐
                  ▼                                              ▼
       IncomingJobQueueNotifier          AppLifecycleOrchestrator
       (filter by eventType,              (drives EventUrgencyRouter)
        map, dedup by jobId,                 │
        append to state.queue)                ▼
                  │                  EventUrgencyRouter
                  │                  - high urgency
                  │                  - list-route guard:
                  │                    skip push if already on
                  │                    /technician/incoming-job-request
                  │                  - else GoRouter.push(...)
                  ▼
       IncomingJobRequestScreen
       (ref.watch(incomingJobQueueProvider))
```

**Boot sequence (load-bearing order)**:
1. `AppLifecycleOrchestrator.bootAfterAuth` is called fire-and-forget by `AuthNotifier._scheduleBoot` (cold-start `build()` and `verifyOtp` paths).
2. `eventSyncProvider.notifier.onUnauthorized` is set.
3. The for-loop in `bootAfterAuth` iterates `realtimeBootHooksProvider`, reading every entry. `incomingJobQueueProvider` is in that list — this read wakes the queue subscriber.
4. FCM initializes (drains background queue, registers token).
5. Sentinel: if teardown ran during step 4 and nulled `onUnauthorized`, `bootAfterAuth` bails. This prevents a stale-token reconnect.
6. `wsConnectionProvider.notifier.connect(token)` — triggers sync cascade; events start flowing.

If step 3 is skipped or moved after step 6, the very first `job_new_request` of the session is delivered to `SystemEventNotifier` but missed by this feature's listener (because `ref.listen` only fires on transitions *after* subscription). The orchestrator test pins this contract via `realtimeBootHooksProvider registry R1/R2` — R1 asserts the queue provider is in the registry, R2 asserts the for-loop iterates it.

---

## Known limitations / deferred work

| Item | Reason | Tracked |
| :--- | :--- | :--- |
| Real card widget | UI sprint | Stub screen in place; widget body is the only thing left to fill in. |
| Accept / decline data layer | Backend endpoint not built (BOOKINGS_API.md §1.1) | Add when endpoint lands. |
| Queue eviction sweep | Sprint scope | Queue is append-only this sprint. Bound is loose (ASAP expires in 60s, scheduled in 15m); a long session with no UI consumption can accumulate stale entries until app restart. Will track in `flag.md`. |
| Receipt-time vs envelope-time `expiresAt` | Sprint scope | Anchor is on envelope `timestamp` (server-time). Slight skew vs receipt time is fine for now; will revisit when accept endpoint lands and a tap-just-past-expiry could 409. |
| Backwards-compat tightening | Mid-rollout | `bookingType` / `payoutContext` are nullable on the wire model. Once historical EventLog rows have aged out (two acceptance-window cycles after backend rollout), they can be tightened to required (BOOKINGS_API.md §2.5). |

---

## Testing

⏳ Test plan pending approval — see the conversation that produced this feature for the proposed coverage of model deserialization, mapper §2.5 defaulting, and notifier dedup / filter behavior.

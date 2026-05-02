# Incoming Job Requests Feature
**Layer status**: Domain ✅ · Data ✅ (parse-side only) · Presentation ✅ (serialized one-offer bottom sheet + four-block card; swipe-to-accept widget pending — see commit 2 of the pivot) · Repository ⏳ (accept/decline endpoint not yet built backend-side)

---

## Overview

Receives `job_new_request` realtime events for the technician audience and surfaces them as a draggable bottom-sheet with a single offer at a time. The backend is end-to-end authoritative on dispatch, payout, and SLA timing — the technician's app only renders typed state and (eventually) posts an accept/decline.

**Backend contract**: `backend/bookings/api/BOOKINGS_API.md` §1.2 (event payload) and §2.3–§2.5 (Flutter integration).

**Realtime channel**: shared WebSocket `ws/events/`, FCM fallback. Routed by `WsFrameDispatcher` → `SystemEventNotifier` → this feature's `IncomingJobQueueNotifier`. See `lib/core/realtime/REALTIME_EVENTS_FEATURE.md` for the transport layer.

---

## Architectural pattern — Per-event feature wiring

This feature is the reference implementation of the rule documented in `CLAUDE.md` → "Per-event feature wiring":

- **Audience-first placement**: lives under `features/technician/`, not under `features/booking/` (which is the customer's checkout). The event is *about* a booking but only *received* by the technician.
- **Subscriber pattern**: `IncomingJobQueueNotifier` (`@Riverpod(keepAlive: true)`) calls `ref.listen(systemEventProvider, …)` and filters by `SystemEventType.jobNewRequest`. Adding a future event = a new notifier in its own feature, never an edit to `core/realtime`'s notifier code.
- **Bottom-sheet presentation, not a route**: `jobNewRequest` is intentionally **absent** from `EventUrgencyRouter._highUrgencyRoutes` and `_listRouteEvents`. Presentation is owned by `IncomingJobSheetHost` (a global overlay mounted at the app shell via `MaterialApp.router.builder`) which watches `incomingJobQueueProvider` and shows/hides itself on queue empty ↔ non-empty transitions. This collapses the previous "router push + list-route guard" pair into a single state-driven surface and preserves the technician's prior context (the sheet slides up over wherever they were instead of pushing a route).
- **Wake-up at boot is load-bearing**: the notifier MUST subscribe to `systemEventProvider` before the WS connect cascade. `incomingJobQueueProvider` is registered in `realtimeBootHooksProvider` (declared at the bottom of `app_lifecycle_orchestrator.dart`); `bootAfterAuth` iterates that registry and reads every entry. Adding a future event of this style = append its queue provider to the registry, never edit `bootAfterAuth`. The wake-up contract is *independent* of how the feature presents (route push, sheet overlay, banner) — the orchestrator tests pin only the registry shape.

---

## Presentation model — serialized one offer at a time

The technician sees ONE offer at a time. There is no "+N more pending" pill, no peek strip behind the card, no "ALSO PENDING" list. An earlier multi-offer surface (peek bar + stacked deck + expanded list) was removed because asking a low-literacy user to decode multiplicity (an abstract count, a stack of layered cards) failed in field testing — both designs required interpretation rather than reaction.

**The contract:**

1. New offers join the queue (in priority order — see commit 2 for the head-sticky priority queue rewrite). Today the queue is FIFO append-only with a display-time sort by `expiresAt` in the host.
2. The sheet renders the head only. The technician accepts, declines, or lets the offer expire.
3. When the head resolves, the next head slides in. The card is rebuilt with the new entity.
4. When the queue empties, the sheet slides out.

**Trade-off:** the technician cannot cherry-pick the highest-payout offer from a batch. They couldn't reliably do that in the previous deck/peek model either, because the affordances were not understood — so accepting the loss makes the UX honest about what was already true.

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
| `scheduledStart` | `DateTime` | UTC. Widgets call `.toLocal()` for display. Drives the eyebrow's ASAP detection — within 30 minutes of `now` reads as ASAP, otherwise as Today / Tomorrow / dated. |
| `expiresAt` | `DateTime` | Anchored on the event's envelope `timestamp` + `expires_in_seconds`. Anchoring on receipt time would skew slightly later than the server SLA — see "Known limitations" below. |
| `slaWindow` | `Duration` | The original SLA span (the wire's `expires_in_seconds`). The backend enforces a 5-minute floor (commit 2 obligation — see flag.md) so the swipe-to-accept drain is never twitchy. The proportion remaining `(expiresAt - now) / slaWindow` drives the green / amber / red bands consumed by the (forthcoming) swipe widget. |
| `locationLabel` | `String?` | Pre-composed locality (e.g. `"Gulberg, Lahore"`) sourced server-side from `CustomerAddress.locality_label`. Null when the address has no structured locality (legacy / pre-rollout row, address detached via SET_NULL). The card hides the address row entirely when null — never shows a placeholder. Full street address is intentionally never on the wire pre-accept (privacy + anti-poach). |

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

Freezed + `fromJson`. **Critical**: `bookingType`, `payoutContext`, and `locationLabel` are all nullable on this model so replayed pre-rollout EventLog rows (BOOKINGS_API.md §2.5) deserialize without throwing — older rows may lack any one of the three fields depending on which rollout window they predate. The domain entity's `BookingType` is non-null because the mapper applies the default; `payoutContext` and `locationLabel` stay nullable through to the entity, and widgets hide their respective UI surfaces when null.

### Mapper — `JobNewRequestMapper.fromSystemEvent`
`lib/features/technician/incoming_job_requests/data/mappers/job_new_request_mapper.dart`

Single boundary where wire strings become typed values:
- Integer-string `payout` → `int`. Non-numeric → returns null + logs.
- ISO-8601 `scheduledStartIso` → `DateTime` (UTC). Unparseable → returns null + logs.
- Wire enum string `bookingType` → `BookingType`. Null or unknown → defaults to `BookingType.laborGig` (§2.5 neutral layout).
- Envelope `timestamp + expires_in_seconds` → `expiresAt`.
- Wire `ui_location_label` → `locationLabel` (pass-through, no transformation; null preserved).

Returns `null` on any malformed payload — the dispatcher's policy is "drop and log", and matching that policy here keeps the queue notifier's filter loop simple.

### Data Sources — `⏳ pending`
Realtime events ingest through `core/realtime`'s `EventRemoteDataSource` (WebSocket + REST sync). No feature-specific data source this sprint. Accept/decline `RemoteDataSource` will land with the repository.

### Repository Implementation — `⏳ pending`
See above.

---

## Presentation Layer

### State — `IncomingJobQueueState`
`lib/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_state.dart`

Freezed. Single field: `List<JobNewRequest> queue`. FIFO arrival order today; the host applies a display sort by `expiresAt` so the head is the most-urgent. Commit 2 of the pivot moves that priority logic into the notifier so the queue is intrinsically head-sticky priority and the host's sort can be deleted.

### Notifier — `IncomingJobQueueNotifier`
`lib/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart`

`@Riverpod(keepAlive: true)`. In `build()`:
1. Subscribes to `systemEventProvider` via `ref.listen`.
2. Skips id-equality housekeeping rebuilds (mirrors the orchestrator's pattern).
3. Filters by `SystemEventType.jobNewRequest`.
4. Maps via `JobNewRequestMapper.fromSystemEvent`; null → silent drop (mapper logged).
5. Defensive per-`jobId` dedup (system-level dedup already covers same-event-id dups; this guard covers a re-broadcast with a fresh event id for the same booking).
6. Appends to the queue.

Exposes `removeRequest(int jobId)` for the sheet to call when the technician declines / accepts an offer. Exposes `debugSeedRequest(JobNewRequest)` for the preview only — production must never call it.

### Sheet host — `IncomingJobSheetHost`
`lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart`

Global overlay mounted once at the app shell via `MaterialApp.router.builder` (see `lib/main.dart`). Watches `incomingJobQueueProvider` and:

- mounts a `DraggableScrollableSheet` (with a fade-in scrim) on the empty → non-empty transition; runs the reverse animation on non-empty → empty;
- pins the sheet to a single snap fraction (≈0.68 of screen height). The technician can drag the sheet down to peek at what was behind it; on release the controller snaps back to the single fraction. There is no peek snap and no expanded snap — they were removed when the multi-offer surfaces were retired;
- fires a soft `HapticFeedback.lightImpact` when a new offer arrives while the sheet is already showing — the visible card does NOT swap (head-sticky principle), the haptic is just an acknowledgement that the queue grew;
- routes Accept / Decline taps to `removeRequest(jobId)` (the real backend call lands when the accept endpoint ships — see `flag.md` #14).

Tapping the scrim does nothing — Decline is always an explicit button to prevent a fat-finger dismissal of a high-payout offer.

### Sheet body — `IncomingJobSheet`
`lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet.dart`

Trivial dispatcher post-pivot: renders `IncomingJobCard(request: queue.first, …)` if non-empty, else an empty `SizedBox`. Owns the outer surface chrome (rounded top corners, top shadow, surface tone) so the design tokens stay in one place. The empty-queue branch covers the slide-out frame where the sheet is still mounted but the queue has just emptied.

### Card — `IncomingJobCard`
`lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_card.dart`

Five blocks, top to bottom:

1. **Eyebrow tonal bar** — drag handle, `INCOMING REQUEST` label, then a day/time line.
   - The day/time line uses the `eyebrowTimeParts` helper which reads `request.scheduledStart` (NOT `slaWindow` — see helper docstring for why the proxy was wrong). When `scheduledStart` is within 30 minutes of `now`, the line collapses to bold red `"ASAP"`. Otherwise the day part (`Today` / `Tomorrow` / `EEE, MMM d`) is heavy and the clock recedes to muted detail.
2. **Service title** — what the customer asked for (e.g. "AC general wash"). The card never names the engagement model; behavioural difference is carried only by the payout subtext below.
3. **Address row** — pin icon + `"Locality, City"` from `request.locationLabel`. The locality reads heavy and the city tail recedes (split on the first comma). Mounted only when non-null.
4. **Expected Payout** — `EXPECTED PAYOUT` eyebrow + hero rupee number + italic floor-condition subtext (one of three copies, picked from `bookingType`).
5. **Action stack** — Accept primary CTA over Decline secondary button. Today these are tap buttons; commit 2 of the pivot replaces the primary tap with a swipe-to-accept widget whose track drains as time runs out (the time-pressure signal absorbed into the action surface itself, with no separate countdown ring needed).

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
                  │                  - jobNewRequest is intentionally
                  │                    absent from _highUrgencyRoutes;
                  │                    presentation is owned by the
                  │                    sheet host below, NOT by a route.
                  │                  - ACK still fires for critical events.
                  ▼
       IncomingJobSheetHost  (mounted at MaterialApp.router.builder,
                              ref.watch(incomingJobQueueProvider))
                  │
                  ▼
       Empty queue → unmounted (slide-down + fade-out)
       Non-empty   → DraggableScrollableSheet at the single snap,
                     rendering IncomingJobCard(queue.first).
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
| Swipe-to-accept widget | Pivot in progress | Commit 1 retains the legacy tap accept; commit 2 replaces it with a draining swipe widget. |
| Head-sticky priority queue | Pivot in progress | Commit 1 keeps FIFO + display sort in the host; commit 2 moves priority into the notifier and removes the host's sort. |
| Backend SLA floor (5 min) | Pivot in progress | Frontend trusts wire `slaWindow` verbatim. A new flag.md entry (commit 2) tracks the backend obligation: `MIN_DISPATCH_SLA = timedelta(minutes=5)`, Celery timeout task armed off the same constant, parallel-fanout dispatch model so customer wait isn't `5min × N techs` serial. |
| Accept / decline data layer | Backend endpoint not built (BOOKINGS_API.md §1.1) | Add when endpoint lands. See flag.md #14. |
| Queue eviction sweep | Sprint scope | Today the queue is append-only; the swipe widget's auto-expire callback in commit 2 will pop the head when its drain hits zero, addressing the case the sweep would have covered. flag.md #6 to be revisited then. |
| Receipt-time vs envelope-time `expiresAt` | Sprint scope | Anchor is on envelope `timestamp` (server-time). Slight skew vs receipt time is fine for now; will revisit when accept endpoint lands and a tap-just-past-expiry could 409. |
| Backwards-compat tightening | Mid-rollout | `bookingType`, `payoutContext`, and `locationLabel` are all nullable on the wire model. Once historical EventLog rows have aged out (two acceptance-window cycles after each rollout), they can be tightened to required (BOOKINGS_API.md §2.5). |
| Address row null fallback | Cross-feature dependency | Bookings created against `CustomerAddress` rows that pre-date session 4 (no `locality_label` populated) and bookings whose address has been detached (`SET_NULL`) emit `null` for `ui_location_label`. The card hides the address row entirely — no placeholder string. The backfill plan for legacy addresses lives outside this feature; see `flag.md` and the customer-side address feature doc. |

---

## Testing

⏳ Test plan pending approval. With the pivot, the meaningful new pins are:
- The eyebrow's `eyebrowTimeParts` helper across the four branches (ASAP / Today / Tomorrow / dated).
- The (commit 2) swipe-to-accept widget across drain over mocked time, color band transitions at the 50% / 20% thresholds, threshold-not-reached snap-back, threshold-reached fires `onAccept`, auto-expire on drain to zero.
- The (commit 2) priority insertion + head-sticky behavior of `IncomingJobQueueNotifier`.

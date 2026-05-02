# Incoming Job Requests Feature
**Layer status**: Domain ✅ · Data ✅ (parse-side only) · Presentation ✅ (serialized one-offer bottom sheet + four-block card with swipe-to-accept) · Repository ⏳ (accept/decline endpoint not yet built backend-side)

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

Freezed. Single field: `List<JobNewRequest> queue`. The list's contract is:
* `queue.first` is the **head** — the offer the technician is currently looking at. Once an offer becomes the head it is **locked** and cannot be displaced by a later, more-urgent arrival. This is load-bearing for the swipe widget — a swap mid-decision would mean the user's finger lands on a different offer than the one they intended to accept.
* `queue.skip(1)` is the **tail**, in insertion (FIFO) order. The tail is *not* re-sorted on every event arrival because tail order only matters at one moment: when the head resolves and the next head must be picked. At that moment, `removeRequest` re-sorts the tail by current urgency before promoting the most-urgent.

### Notifier — `IncomingJobQueueNotifier`
`lib/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart`

`@Riverpod(keepAlive: true)`. In `build()`:
1. Subscribes to `systemEventProvider` via `ref.listen`.
2. Skips id-equality housekeeping rebuilds (mirrors the orchestrator's pattern).
3. Filters by `SystemEventType.jobNewRequest`.
4. Maps via `JobNewRequestMapper.fromSystemEvent`; null → silent drop (mapper logged).
5. Defensive per-`jobId` dedup (system-level dedup already covers same-event-id dups; this guard covers a re-broadcast with a fresh event id for the same booking).
6. **Head-sticky append**: the new request joins the tail in arrival order. If the queue was empty it becomes the head; otherwise the head at `queue.first` stays.

`removeRequest(int jobId)`:
* If `jobId` is the head, the tail is re-sorted by current urgency (`(remaining / slaWindow)` ascending — smallest fraction = most urgent) and the most-urgent entry is promoted to the new head. The fraction is the right metric across heterogeneous SLA windows (a 60-second remaining out of a 5-minute window is more urgent than a 60-second remaining out of a 60-minute window).
* If `jobId` is in the tail (a defensive case — the user-facing flow only ever resolves the head today), the head stays put and the tail loses one entry.
* Unknown jobId → silent no-op (defensive against double-remove, e.g. an accept-then-expire race).

`debugSeedRequest(JobNewRequest)` — preview only. Mirrors the dedup behavior of the real ingest path. Production code must never call it.

### Sheet host — `IncomingJobSheetHost`
`lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart`

Global overlay mounted once at the app shell via `MaterialApp.router.builder` (see `lib/main.dart`). Watches `incomingJobQueueProvider` and orchestrates four state transitions in `_onQueueChanged`:

1. **Empty → first arrival.** Mount the sheet, slide it up (~280ms), fade the scrim in.
2. **Non-empty → empty.** Slide the sheet down (~220ms), unmount, clear `_displayQueue`.
3. **Head changed (both states non-empty).** Run the **vanish-reappear ceremony** — see below.
4. **Head unchanged, tail grew.** Soft `HapticFeedback.lightImpact` only. The visible card does NOT swap (head-sticky principle); the haptic acknowledges that the queue grew.

The sheet is pinned to a single snap fraction (≈0.68 of screen height). The technician can drag the sheet down past 30% to peek behind it; on release the `DraggableScrollableController` snaps back. Tapping the scrim is intentionally a no-op — accept is a swipe and decline is an explicit button so a stray tap can't dismiss a high-payout offer.

#### Head-change vanish-reappear ceremony

When the head resolves (accept / decline / expire) AND there's another offer in the tail to promote, the host runs a deliberate "this is a new offer" ceremony in `_runHeadChangeCeremony`:

| Phase | Duration | What happens |
| :--- | ---: | :--- |
| Confirm hold (accept only) | ~260ms | The swipe widget plays its confirm animation (thumb → right edge, "Accepted" check). `_handleAccept` defers `removeRequest` for this duration so the user sees the action register before the sheet starts moving. Decline / expire skip this phase. |
| Slide out | ~220ms | The current sheet slides down off-screen with the OLD head still visible. `_displayQueue` is *not* updated yet — the listener freezes on the previous content during the slide-out so the user sees what they're saying goodbye to. |
| Pause | ~250ms | Sheet is off-screen. `_displayQueue` is swapped silently to the new head. Brief silence with the underlying screen visible — the deliberate gap that makes the new offer read as new. |
| Cue | (instant) | `IncomingJobSoundPlayer.playNewOfferSound()` fires + `HapticFeedback.heavyImpact()`. Redundant on purpose: sound for a tech who's looking away, haptic for one who can't hear (silent mode, noisy environment), visual (next phase) for one whose phone is muted in a pocket. |
| Slide in | ~280ms | The sheet slides up with the new head visible. The swipe widget rebuilds fresh — thumb at the left edge, drain at full. |

Total: ~1010ms accept-to-next-offer (including confirm hold), ~750ms decline/expire-to-next-offer. Slow if the technician is in rapid-fire mode, but the clarity gain over an instant content swap is the whole point.

Action handlers route to `removeRequest(jobId)` — the real backend call lands when the accept endpoint ships (see `flag.md` #14). Today's three handlers are deliberately separate methods (not a single `_resolveHead`) so the future endpoint sprint can wire different remote semantics: decline POSTs `/decline`; expire is a no-op (the server's SLA-timeout Celery task fires authoritative); accept POSTs `/accept`.

#### Sound — `IncomingJobSoundPlayer`
`lib/features/technician/incoming_job_requests/presentation/services/incoming_job_sound_player.dart`

Abstract interface with one method, `playNewOfferSound()`. Today's binding (in `dependency_injection.dart`) is `SystemSoundIncomingJobSoundPlayer` which delegates to Flutter's built-in `SystemSound.play(SystemSoundType.alert)` — no dependency, no asset, respects device silent / vibrate mode. The trade-off is that the audible output is the device's stock alert tone, not distinct from a regular system notification.

Treated as a deliberate placeholder. The swap-path to a custom chime (see `flag.md` #18):
1. Add `audioplayers` (or similar) to `pubspec.yaml`.
2. Drop a chime asset (e.g. `assets/sounds/incoming_job_chime.wav`) into the project, register in pubspec.
3. Add an `AssetIncomingJobSoundPlayer` implementation.
4. Override `incomingJobSoundPlayerProvider` in `dependency_injection.dart`.

No host changes. No widget changes. The host calls `ref.read(incomingJobSoundPlayerProvider).playNewOfferSound()` and gets whatever's bound.

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
5. **Action stack** — `IncomingJobSwipeToAccept` (primary, 72dp) over `Decline` (secondary tap, 48dp). Asymmetric: accept = commitment = swipe; decline = reversible = tap.

### Swipe-to-accept — `IncomingJobSwipeToAccept`
`lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_swipe_to_accept.dart`

A draining pill the technician slides right to accept the head offer. Replaces the prior tap-accept + separate-countdown-ring pair. **Two roles in one widget:**

1. **Action surface.** A 60dp circular thumb sits on the left of the pill and follows the user's finger horizontally. Releasing past 80% of the colored runway fires `onAccept` once and the thumb morphs into a check. Releasing short of 80% snaps the thumb back to the start with a `Curves.easeOutCubic` animation. The 80% threshold (rather than 100%) is intentional — a confident swipe shouldn't have to nudge into the very last pixel on a budget Android.

2. **Time-pressure signal.** A colored fill anchored at the left of the track recedes from the right edge as the SLA elapses. The fill width is `(remaining / slaWindow) × innerWidth`, computed every 250ms from a wall-clock `Timer.periodic` (not frame count — survives backgrounding correctly). When the fill shrinks below the thumb diameter, the swipe runway is gone and the offer is moments from auto-expiry. When the fill reaches zero the widget fires `onExpire` once and freezes red.

Color comes from `urgency_palette.urgencyAccent`: green > 50% remaining, amber 20–50%, red < 20%. The thumb tracks the same color so the band assignment reads at a single glance.

The idle thumb has a subtle shimmer animation on the chevron icon — a 0–3px horizontal nudge looping over 1.6s. The animation teaches the swipe-to-the-right affordance without moving the thumb itself (which would change the perceived swipe distance). It freezes the moment the user starts dragging.

**Why a swipe, not a tap.** Field testing showed taps fired by accident from a phone in a tool belt pocket. The horizontal-swipe affordance maps to the iPhone-call-answer metaphor most users in this market have absorbed from years of mobile-phone use, and it requires deliberate physical motion that pockets don't reproduce. Accept is the heaviest action the technician can take (driving to a location, taking the work) — the gesture should match.

**Why a drain, not a separate ring.** A separate countdown ring competes with content for the eye and forces the user to decode two surfaces. The drain encodes time pressure into the action surface itself with no second visual.

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
| Backend SLA floor (5 min) + parallel-fanout dispatch | Cross-side obligation | Frontend trusts wire `slaWindow` verbatim and the swipe widget's drain assumes a humane span. A flag.md entry tracks: `MIN_DISPATCH_SLA = timedelta(minutes=5)` constant, Celery SLA-timeout task armed off the same constant, dispatch model is parallel-fanout (not serial-per-tech) so customer wait isn't `5min × N techs`. |
| Accept / decline data layer | Backend endpoint not built (BOOKINGS_API.md §1.1) | Add when endpoint lands. See flag.md #14. |
| Queue eviction sweep | Closed by the swipe widget | The swipe widget's `onExpire` callback pops the head when its drain hits zero. flag.md #6 (the "no eviction sweep" entry) can be marked resolved by this commit. |
| Receipt-time vs envelope-time `expiresAt` | Sprint scope | Anchor is on envelope `timestamp` (server-time). Slight skew vs receipt time is fine for now; will revisit when accept endpoint lands and a tap-just-past-expiry could 409. |
| Backwards-compat tightening | Mid-rollout | `bookingType`, `payoutContext`, and `locationLabel` are all nullable on the wire model. Once historical EventLog rows have aged out (two acceptance-window cycles after each rollout), they can be tightened to required (BOOKINGS_API.md §2.5). |
| Address row null fallback | Cross-feature dependency | Bookings created against `CustomerAddress` rows that pre-date session 4 (no `locality_label` populated) and bookings whose address has been detached (`SET_NULL`) emit `null` for `ui_location_label`. The card hides the address row entirely — no placeholder string. The backfill plan for legacy addresses lives outside this feature; see `flag.md` and the customer-side address feature doc. |

---

## Testing

The feature ships with the following pinned contracts:

- **Wire model + mapper** (`data/models/`, `data/mappers/`): §1.2 round-trip, §2.5 backwards-compat defaulting (missing `booking_type` → `laborGig`, missing `payout_context` / `ui_location_label` → null on entity), malformed payouts return null without throwing.
- **Eyebrow `eyebrowTimeParts`** (`presentation/widgets/incoming_job_card_test.dart`): ASAP / Today / Tomorrow / dated branches; ASAP detection sourced from `scheduledStart` (regression net for the slaWindow proxy that broke when the 5-min SLA floor landed).
- **Swipe-to-accept widget** (`presentation/widgets/incoming_job_swipe_to_accept_test.dart`): caption renders the formatted payout, drag past 80% fires `onAccept` exactly once, drag short of 80% does not fire (snap-back), already-expired widget fires `onExpire` exactly once on the next ticker fire, post-expire drags cannot re-fire `onAccept`.
- **Queue notifier** (`presentation/providers/incoming_job_queue_notifier_test.dart`): basic ingest + dedup + filter; head-sticky behavior — head doesn't swap on a more-urgent newcomer; on head removal, the most-urgent of the tail is promoted (NOT FIFO arrival order); single-entry queue empties cleanly on head remove; non-head removal preserves head + remaining tail; `debugSeedRequest` mirrors real-event dedup.
- **Urgency palette** (`presentation/utils/urgency_palette_test.dart`): green/amber/red band thresholds at the documented fractions, defensive expiry / zero-window handling, `urgencyIsRed` agrees with `urgencyAccent` 1:1.

Cross-feature integration (the `IncomingJobSheetHost` overlay rendering against the queue notifier through to the rendered card) is not yet pinned — it would require a widget test that mounts the host with a fake queue and asserts the whole DOM, which is good follow-up but out of scope for the pivot.

# Booking Orchestrator Feature

The audience-shared full-screen surface that drives a single booking through its post-CONFIRMED lifecycle. One screen, every status, two viewer roles (customer + technician). Closes flag #26.

**Backend contract**: `backend/bookings/api/BOOKINGS_API.md` §8 (detail) + §3-§13 (16 transition endpoints). Server-resolved `ui` block from `backend/bookings/selectors/orchestrator_ui.py`.

**Sprint**: Booking Orchestrator Sprint, session 3. Sessions 4–6 fill specialized body widgets:
- Session 4 — replaces `EnRouteBodyStub` / `ArrivedBodyStub` with the live-tracking map + tech foreground GPS.
- Session 5 — replaces `InspectingBodyStub` (quote builder), `QuotedBodyStub` (rich approval sheet), `InProgressBodyStub` (cash collection sheet).
- Session 6 — cancel/reschedule/no-show/dispute rich flows, replacing today's `BookingActionPendingSheet` placeholders.

---

## Sprint Status

| Layer | Status |
|---|---|
| Domain (entities, failures, repository interface, use case) | ✅ Shipped (session 3) |
| Data (DTOs, mappers, datasources, repository impl) | ✅ Shipped (session 3) |
| Presentation / providers (DI, detail provider, events notifier, rescheduled notifier, action executor) | ✅ Shipped (session 3) |
| Presentation / screen + slots (header, timeline, body switch, primary/secondary actions) | ✅ Shipped (session 3) |
| Stub body widgets (14 statuses) | ✅ Shipped (session 3); EnRoute + Arrived rewritten to live tracking in session 4. |
| Live tracking map body + tech foreground GPS | ✅ Shipped (session 4) — `live_tracking_map.dart`, `technician_location_stream_notifier.dart`, `tracking_subscription_controller.dart`, and the tech-side broadcaster at `frontend/lib/features/technician/location_broadcaster/`. |
| Quote builder body + approval sheet + cash-collection sheet | ⏳ pending session 5 |
| Cancel/reschedule/no-show/dispute rich flows | ⏳ pending session 6 |
| Realtime: 5 new event types + router rewiring | ✅ Shipped (session 3) |
| GoRoute `/booking/:job_id` registration | ✅ Shipped (session 3) |
| Tests | ✅ Shipped (session 3) — 130 frontend + 15 backend pinning regressions across all 23 audit findings (cycles 1+2). Session 4 added ~30 net-new tests (map adapter, directions services, stream notifier, subscription controller, ws-upstream extension, marker factory, live tracking widget). |

---

## Realtime Stream Consumer Pattern (codebase reference)

Session 4 lit up the codebase's first `kind: "stream"` consumer
(`tech_gps`). The pattern below documents it for future stream features
(live wallet balance display, AI chatbot tokens, typing indicators).
The audit hardening pass (C1, C5, H5, H8) cemented several rules — they
are flagged in the touch-points below.

**Touch-points** — analogous to the per-event pattern in CLAUDE.md:

1. **Payload model + mapper in the consumer feature** (NOT in `core/realtime`).
   - Wire DTO with `fromJson` (the dispatcher passes `frame['payload']`,
     not the envelope).
   - Mapper to domain entity. **The mapper must validate payload bounds
     and may return `null` to drop a malformed frame** (audit H5). Stream
     frames bypass the envelope-layer recipient/expiry filters in
     `SystemEventNotifier`, so the mapper is the only place a
     server-bug / wire-corruption / MITM payload gets stopped.
   - If the payload omits a field the domain needs (e.g. `tech_gps`
     has no payload-level timestamp), the mapper stamps it via an
     injectable `now` callback. **Production callers should pass
     `() => ref.read(systemEventProvider.notifier).serverNow()`** so
     downstream staleness checks (also using `serverNow()`) compute on
     a single coherent clock immune to device clock skew (audit H8).
2. **A `@Riverpod(keepAlive: false)` family notifier whose `build()`
     registers the handler with `WsFrameDispatcher`.**
   - Audit P1-05: `state` mutations inside the handler MUST defer past
     `build()` via `Future.microtask` + `ref.mounted` guard.
   - Audit C5: `dispatcher.unregister(streamType, handler)` is
     **two-arg with an identity check** — pass the same handler
     reference you registered. The dispatcher only removes if the
     currently-registered handler is identical, so a late
     `ref.onDispose` against a successor notifier's registration
     becomes a safe no-op. (Single-handler-per-type still applies —
     flag #34 deferred for the multi-handler refactor.)
3. **A `TrackingSubscriptionController`-style upstream gate (only if
     the stream requires `subscribe_<topic>` upstream messages).**
   - Listens to whatever provider gates the subscription (booking
     status × role, current screen, etc.).
   - **Use `ref.listen(..., fireImmediately: true)`** (audit C1) — a
     plain `ref.listen` only fires on future *transitions*, so if the
     gating provider was already resolved when the controller's
     `build` ran (cached data, later widget mounting the controller
     after the gate resolved) the gate would silently never evaluate
     and the upstream subscribe would never fire.
   - Listens to `wsConnectionProvider.connectionEvents` and replays the
     subscribe message on every `WsConnected` (audit P1-06).
4. **The screen `ref.watch`-es the notifier in `build()` (NOT
     `ref.read` in `initState`).**
   - The same contract pinned by the session-3 regression test
     (`screen_ref_watch_keeps_event_notifier_alive_refresh_fires`)
     applies here. `keepAlive: false` notifiers MUST be watched, or
     they auto-dispose and the handler unregisters silently.
5. **No event-urgency-router changes** — streams don't navigate; they
     update state in place.

Reference impl:
- `lib/features/orchestrator/presentation/providers/technician_location_stream_notifier.dart`
- `lib/features/orchestrator/presentation/providers/tracking_subscription_controller.dart`
- `lib/features/orchestrator/data/{models,mappers}/tech_gps_frame*.dart`
- `lib/features/orchestrator/domain/entities/tech_gps_frame.dart`

---

## Domain Layer

### Entities

| File | Purpose |
|---|---|
| `domain/entities/booking_detail.dart` | Top-level entity. Nested `BookingService`, `BookingSubService`, `BookingTechnician`, `BookingCustomer`, `BookingAddress`. |
| `domain/entities/booking_status.dart` | Reuses `customer/bookings/domain/entities/booking_status.dart` — extended with 8 new lifecycle values: `enRoute`, `arrived`, `inspecting`, `quoted`, `inProgress`, `completedInspectionOnly`, `noShow`, `disputed`. The compiler-enforced exhaustive `wireValue` switch protects against silent drift. |
| `domain/entities/booking_orchestrator_role.dart` | Enum: `customer`, `technician`. Derived in the data-layer mapper from `customer.id == currentUserId` (server's 403 gate makes the inverse safe). |
| `domain/entities/booking_quote.dart` | `BookingQuote` + `BookingQuoteLineItem` + `BookingQuoteStatus` enum (DRAFT / SUBMITTED / APPROVED / DECLINED / SUPERSEDED / unknown). |
| `domain/entities/booking_item.dart` | Snapshot of the accepted quote line — survives sub-service catalog changes. |
| `domain/entities/booking_ui_block.dart` | Server-resolved UI hints. `BookingUiBlock` + `BookingUiAction` + `BookingUiActionStyle` enum. Reuses `BookingUiTone` from `customer/bookings`. |
| `domain/entities/booking_phase_timestamps.dart` | 7 nullable lifecycle anchor timestamps. |
| `domain/entities/booking_pricing.dart` | Integer-rupee snapshot of money fields (Decimal-strings on the wire are coerced once in the mapper). |
| `domain/entities/booking_cash_collection.dart` | Cash-collection state set on `mark_complete_with_cash`. |

### Sealed Failure Hierarchy

`domain/failures/booking_detail_failure.dart`

```
BookingDetailFailure
  ├── BookingDetailNotFound(int bookingId)        — 404
  ├── BookingDetailNotParticipant                  — 403 not_a_participant
  ├── BookingDetailOfflineNoCache                  — SocketException + no cache
  ├── BookingDetailNetworkFailure                  — generic transport error
  ├── BookingDetailServerFailure                   — 5xx
  └── UnknownBookingDetailFailure(String message)  — catch-all
```

### Repository Interface + Use Case

`domain/repositories/booking_detail_repository.dart` declares `IBookingDetailRepository.getBookingDetail(int)`. `domain/use_cases/get_booking_detail_use_case.dart` is a thin wrapper.

**Offline-first contract**: `SocketException` with a usable cache row returns the cached entity silently; without cache, throws `BookingDetailOfflineNoCache`. Other failures map to typed sealed-class failures.

---

## Data Layer

### DTOs

Nested freezed-with-`json_serializable` shape, matching the existing `customer/bookings/data/models/customer_booking_model.dart` pattern. All Decimal fields stay as strings on the DTO; the mapper coerces.

| File | What |
|---|---|
| `data/models/booking_detail_model.dart` | Top-level + 7 nested DTOs (service, subService, technician, customer, address, phaseTimestamps, pricing, cashCollection). |
| `data/models/booking_quote_model.dart` | `BookingQuoteModel` + `BookingQuoteLineItemModel`. |
| `data/models/booking_item_model.dart` | `BookingItemModel`. |
| `data/models/booking_ui_block_model.dart` | `BookingUiBlockModel` + `BookingUiActionModel`. |
| `data/models/booking_event_payloads.dart` | `JobIdPayload` (shared by 11 events), `QuoteGeneratedPayload`, `BookingRescheduledPayload`. |

### Mappers

| File | What |
|---|---|
| `data/mappers/booking_detail_mapper.dart` | DTO → domain. **Two non-trivial coercions**: (1) `num.parse(s).toInt()` for Decimal-string rupees — `int.parse("500.00")` would throw; (2) viewer-role from `customer.id == currentUserId`, server's 403 gate makes the else-branch always tech. |
| `data/mappers/booking_event_payload_mapper.dart` | `extractJobId(event)` + `extractChildBookingId(event)`. Defensive — null on malformed payload. |

### Data Sources

| File | What |
|---|---|
| `data/datasources/booking_detail_remote_data_source.dart` | `package:http` per sprint §24. URL: `${AppConstants.baseUrl}/bookings/$id/`. Reuses singleton `eventHttpClientProvider`. Throws `HttpFailure` on non-2xx; SocketException bubbles. |
| `data/datasources/booking_detail_local_data_source.dart` | SharedPreferences cache, key `orchestrator_booking_detail_v1_<id>`. Bump the `_v1_` suffix when response shape changes. |

### Repository Impl

`data/repositories/booking_detail_repository_impl.dart` — offline-first:

1. `await _remote.fetch(bookingId)` — primary path.
2. On success → best-effort cache write (`.ignore()` on the future) + map to domain.
3. On `SocketException` → try `_local.read`; cached hit returns silently, miss throws `BookingDetailOfflineNoCache`.
4. On `HttpFailure` → switch on status code to typed failure (404 → `NotFound`, 403 `not_a_participant` → `NotParticipant`, 5xx → `ServerFailure`).
5. Anything else → `UnknownBookingDetailFailure(e.toString())`.

---

## Presentation Layer

### DI (`presentation/providers/dependency_injection.dart`)

All providers `keepAlive: true`. Reuses `eventHttpClientProvider` from the realtime feature (sprint §24). Per-feature `orchestratorSecureStorageProvider` (codebase convention — `FlutterSecureStorage` is stateless, multiple instances cost nothing).

The repository provider reads `currentAuthUserIdProvider` (the auth ↔ realtime seam from flag #19) at construction so the mapper can derive `viewerRole`.

### State / Notifier Tree

| Provider (generated name) | Class | Family | keepAlive | Purpose |
|---|---|---|---|---|
| `bookingDetailProvider(jobId)` | `BookingDetailNotifier` | `<int>` | false | AsyncNotifier hydrating from `GET /api/bookings/<id>/`. Disposed on screen pop; next mount re-fetches. |
| `bookingOrchestratorEventsProvider(jobId)` | `BookingOrchestratorEventsNotifier` | `<int>` | false | Multi-event `ref.listen(systemEventProvider)`. 12 trigger events × matching `payload.job_id` → `ref.invalidate(bookingDetailProvider(jobId))`. |
| `bookingRescheduledProvider(jobId)` | `BookingRescheduledNotifier` | `<int>` | false | Standalone listener for `bookingRescheduled` (nav side effect: `pushReplacement('/booking/<child>')`). |
| `bookingActionExecutorProvider` | `BookingActionExecutor` | — | true | HTTP dispatch for server-emitted `BookingUiAction` (handles GET/POST/PATCH/PUT/DELETE; supports optional body). |

**Refresh UX**: both event-driven and user-initiated retry route through `ref.invalidate(bookingDetailProvider(jobId))`. Riverpod 3 preserves the prior value during the rebuild and exposes `isLoading` while the future runs — the screen renders a thin `LinearProgressIndicator` at the top of the body. No spinner flash on every realtime event.

### Screen + Slots

`presentation/screens/booking_orchestrator_screen.dart` — Scaffold + AppBar; body driven by `detailAsync.when(loading, error, data)`. On data, layout is:

```
┌───────────────────────────────┐
│   thin progress (refreshing)  │   ← 2px LinearProgressIndicator
├───────────────────────────────┤
│        HEADER SLOT             │   tone-tinted: status + counterparty
│        TIMELINE SLOT           │   phase progression dots
├───────────────────────────────┤
│                                │
│         BODY SLOT              │   exhaustive switch on status →
│        (scrollable)            │   one of 14 stub widgets
│                                │
├───────────────────────────────┤
│     SECONDARY ACTIONS SLOT     │   text buttons (wrap)
│     PRIMARY ACTION SLOT        │   FilledButton (full width)
└───────────────────────────────┘
```

The `BodySlot`'s `switch (booking.status)` is the **only** status branch in the entire feature. Dart 3 patterns enforce exhaustiveness — adding a new `BookingStatus` enum value will fail compilation here.

### Action Button Classification (`booking_orchestrator_action_button.dart`)

Each backend endpoint suffix falls into one of three buckets:

| Endpoint suffix | Behavior | Body |
|---|---|---|
| `/en-route/`, `/arrived/`, `/start-inspection/`, `/quotes/<id>/approve/`, `/quotes/<id>/decline/` | Direct POST | none |
| `/confirm-cash-received/` | Direct POST | `{cash_amount: pricing.finalCashToCollect}` (auto) |
| `/cancel/`, `/tech-cancel/` | Pending sheet → POST default reason | `{cancel_reason: 'customer_cancelled'}` (or tech equivalent) |
| `/reschedule/`, `/no-show/`, `/disputes/`, `/quotes/`, `/quotes/<id>/request-revision/` | Pending sheet (explainer only — no POST) | — |

Sessions 5/6 will replace the pending-sheet branch with rich flows.

### Stub Body Widgets

`presentation/widgets/stub_bodies/all_status_stubs.dart` — 14 widgets in one file:

- `AwaitingBodyStub`, `ConfirmedBodyStub`, `EnRouteBodyStub` (map placeholder), `ArrivedBodyStub` (map placeholder), `InspectingBodyStub`, `QuotedBodyStub` (renders the line-item card from `booking.activeQuote`), `InProgressBodyStub`, `CompletedBodyStub`, `CompletedInspectionOnlyBodyStub`, `CancelledBodyStub`, `RejectedBodyStub`, `NoShowBodyStub`, `DisputedBodyStub`, `UnknownBodyStub`.

`UnknownBodyStub` logs a warn-level `developer.log` when `booking.status == BookingStatus.pending` — legacy pre-orchestrator-era rows shouldn't surface in v1, so the log helps spot rollout-window regressions.

Every stub reads its prose from `booking.ui.bodyText` (dumb-UI principle). Sessions 4-6 keep this discipline.

---

## Realtime Integration

### Per-event payload models + mapper

`data/models/booking_event_payloads.dart` carries the freezed payloads (per CLAUDE.md "Per-event feature wiring" — payload models live with the consumer, never in `core/realtime`). `data/mappers/booking_event_payload_mapper.dart` does the extractor work.

### New event types (added to `core/realtime`)

`quoteRevisionRequested`, `quoteDeclined`, `bookingCancelled`, `bookingNoShow`, `bookingRescheduled` — added to `system_event_type.dart` (enum + lookup) and `event_urgency.dart` (mapped to `lowUrgency`). None are critical (no ACK).

### Router rewiring (`event_urgency_router.dart`)

- All orchestrator-relevant high-urgency routes (`quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved`) → `/booking/:job_id`.
- Low-urgency: `jobAccepted`, `bookingRejected`, plus the 5 new types → `/booking/:job_id`.
- `_navGuardPayloadKeys` switched to `'job_id'` for the high-urgency entries (URL is `:job_id`, not `:quote_id` / `:dispute_id`). `bookingRescheduled` intentionally not in the guard — we want the re-nav.
- New `_resolveTemplatedPath` is generic over `:<token>` substitution — works for both high and low urgency.

### Bookings list integration

`features/customer/bookings/data/mappers/booking_event_patch_mapper.dart` extended with 5 new static methods (`applyBookingCancelled`, `applyBookingNoShow`, `applyQuoteDeclined`, `applyJobCompleted`, `applyBookingRescheduled`). The list notifier's switch now routes those events through the mapper to keep list rows in lockstep with orchestrator state.

---

## Routing

`core/routing/app_router.dart` — `GoRoute(path: '/booking/:job_id', name: 'booking_orchestrator', ...)`. The pre-orchestrator route `/customer/booking/:job_id` is removed; the placeholder `CustomerBookingDetailScreen` is deleted (closes flag #26). Card-tap on `booking_card.dart` updated to the new path.

---

## Backend tweak (Phase A of session 3)

`backend/bookings/selectors/orchestrator_ui.py` — stripped the `/api/` prefix from all 12 `endpoint` strings (sprint §24: `AppConstants.baseUrl` already includes `/api`). For the 3 customer-quote-action endpoints, substituted the live `active_quote.id` via `quote_selector.get_active_quote(booking)` — pre-fix, the wire format was `/api/bookings/123/quotes/<id>/approve/`, which the frontend executor would have POSTed verbatim and crashed.

Added invariant tests in `backend/tests/bookings/selectors/test_orchestrator_ui_selector.py` asserting (a) no endpoint starts with `/api/`, (b) no endpoint contains literal `<id>`, (c) customer-quoted endpoints interpolate the actual quote id.

---

## Drift policies

| Surface | Authoritative source | Mirror |
|---|---|---|
| `BookingStatus` wire values | `backend/bookings/models.py::JobBooking.STATUS_*` | `customer/bookings/domain/entities/booking_status.dart` `_wireLookup` |
| `ui` block shape | `backend/bookings/selectors/orchestrator_ui.py::resolve_orchestrator_ui` | `BookingDetailMapper._uiBlock` + `BookingUiBlockModel` |
| Action endpoint strings | `orchestrator_ui.py` action helpers (no `/api/` prefix) | `BookingActionExecutor` + invariant tests |
| Event types | `backend/realtime/constants/event_types.py` + `EVENT_REGISTRY` | `core/realtime/domain/entities/system_event_type.dart` |
| List-card UI patches | `backend/bookings/selectors/customer_bookings_selector._resolve_ui_block` | `customer/bookings/data/mappers/booking_event_patch_mapper.dart` |

When backend changes any of these, this file MUST update in lockstep.

---

## Cross-feature changes shipped alongside this feature (session 3)

The orchestrator screen does not stand alone — it is the audience-shared
detail surface that closes flag #26 and inherits realtime / routing /
list-side traffic from elsewhere. Five sibling files moved in lockstep:

| File | Change | Why |
|---|---|---|
| `frontend/lib/core/realtime/domain/entities/system_event_type.dart` | +5 enum cases (`quoteRevisionRequested`, `quoteDeclined`, `bookingCancelled`, `bookingNoShow`, `bookingRescheduled`) + matching `_lookup` entries. | Backend session 2 added these to `EVENT_REGISTRY`; frontend wire-string parsing must mirror or all five fall into `unknown` and never reach a banner. |
| `frontend/lib/core/realtime/domain/entities/event_urgency.dart` | All 5 new types mapped to `lowUrgency`. None are critical (`is_critical=False`). `jobAccepted` flipped from `highUrgency` to `lowUrgency` (vestigial route never existed; covered separately by flag #25). | Orchestrator screen is the natural surface — banner + tap is sufficient; force-pushing a route on every quote revision is overkill. |
| `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart` | All orchestrator-relevant high-urgency events (`quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved`) repointed to the templated `/booking/:job_id`. Low-urgency tap routes for `techEnRoute`, `techArrived`, `jobAccepted`, `bookingRejected`, and the 5 new types — all `/booking/:job_id`. `bookingRescheduled` uniquely targets `/booking/:child_booking_id`. `_resolveTemplatedPath(...)` is now a generic `:<token>` substituter so a single helper covers `:job_id`, `:child_booking_id`, and any future template. `_navGuardPayloadKeys` drives "already-on-entity" suppression — `'job_id'` for the orchestrator events; `'child_booking_id'` for reschedule. `_listRouteEvents` is empty post-`IncomingJobSheetHost` pivot but kept as the mechanism for any future list-style screen. | One screen absorbs every booking-detail flavor; double-pushing the same screen with a different `quote_id` would waste the user's stack. |
| `frontend/lib/core/routing/app_router.dart` | New `/booking/:job_id` GoRoute (`name: 'booking_orchestrator'`). Path-parameter parsing rejects malformed ids (`/booking/abc`, `/booking/0`, `/booking/-3`) and renders a dedicated `_InvalidBookingLinkScreen` rather than collapsing to id=0 + a generic server 404. Pre-orchestrator placeholder route `/customer/booking/:job_id` is gone; the placeholder screen file is deleted. | The orchestrator screen is the real detail UI. Surfacing bad deep-links explicitly (versus a server round-trip) lets the user distinguish a typo from a vanished booking. |
| `frontend/lib/features/customer/bookings/domain/entities/booking_status.dart` | +8 lifecycle values (`enRoute`, `arrived`, `inspecting`, `quoted`, `inProgress`, `completedInspectionOnly`, `noShow`, `disputed`). `_wireLookup` table extended in lockstep with `JobBooking.STATUS_*`. | The bookings list and orchestrator screen share the enum — both render the new statuses (list via `ui` block from server; orchestrator via the body-slot switch). |
| `frontend/lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart` | +5 static patch methods (`applyBookingCancelled`, `applyBookingNoShow`, `applyQuoteDeclined`, `applyJobCompleted`, `applyBookingRescheduled`). Each mirrors one row of the server's `customer_bookings_selector._resolve_ui_block` table — Option (ii) inline patching, no detail round-trip. | List rows must update in lockstep with orchestrator state. Round-tripping a detail fetch on every transition would cost a network call per status flip — wasteful when the wire payload already determines the new ui block. |
| `frontend/lib/features/customer/bookings/presentation/providers/customer_bookings_list_notifier.dart` | Event switch extended for the 5 new types. `bookingRescheduled` additionally fires `refresh()` so the newly-created child booking shows up on Upcoming without a manual pull. | List-side patching only mutates rows that already exist; reschedule creates a new row (the child) which has to come from a server re-fetch. |
| `frontend/lib/features/customer/bookings/presentation/widgets/booking_card.dart` | Tap handler now routes to `/booking/<id>` (audience-neutral) instead of the deleted `/customer/booking/<id>`. | Single detail surface for both customer and tech. |

---

## Backend Phase A — three small but load-bearing patches

The feature is a frontend deliverable, but three backend tweaks were
required for the orchestrator screen to function correctly. They live in
the same uncommitted working tree as the frontend feature.

### `backend/bookings/selectors/orchestrator_ui.py` — URL convention + live quote id

- All 12 `endpoint=` strings stripped of the literal `/api/` prefix
  (`f"/api/bookings/{booking.id}/cancel/"` → `f"/bookings/{booking.id}/cancel/"`).
  `AppConstants.baseUrl` already includes `/api`; embedding the prefix
  here would have produced `http://host/api/api/bookings/...` — every
  POST 404s. Documented at file-top under "Endpoint convention (sprint §24)".
- `_customer_quoted` now imports `get_active_quote(...)` and substitutes
  the live `active_quote.id` for the previous `<id>` placeholder in the
  3 customer-facing quote endpoints (`approve`, `decline`, `request-revision`).
  Pre-fix the wire format was `/bookings/123/quotes/<id>/approve/` and the
  Flutter executor would have POSTed the literal `<id>` and crashed on the
  Django URL resolver.
- Defensive `None` branch — if `get_active_quote` returns `None` (corrupt
  row, race), `_customer_quoted` returns a degraded "Quote details are
  unavailable" body with `tone: warning` and no actions, instead of an
  AttributeError 500.
- Invariant tests in `backend/tests/bookings/selectors/test_orchestrator_ui_selector.py`
  pin: (a) no endpoint starts with `/api/`, (b) no endpoint contains
  literal `<id>`, (c) customer-quoted endpoints interpolate the actual
  quote id.

### `backend/bookings/api/booking_detail/views.py` — reschedule lineage forward-pointer

`BookingDetailView.get` now reads the most-recent child via the
`child_bookings` related_name (`booking.child_bookings.order_by('-id').only('id').first()`)
and surfaces `child_booking_id` on the response payload. Without it, a
customer or tech who returns to the cancelled original (typically via a
stale FCM tap) is stranded with no way to navigate to the live booking.
The orchestrator screen reads this field to render a "Continued on #N"
callout and route the link to the child.

### `backend/bookings/api/booking_detail/serializers.py` — BookingItem ≠ QuoteLineItem

`BookingDetailResponseSerializer` previously reused
`QuoteLineItemResponseSerializer` for the `booking_items` field, but the
two models have diverged column names: `BookingItem.price_charged` ≠
`QuoteLineItem.priced_at`. Reuse would have raised `AttributeError` at
runtime — silently undetected because no booking-detail test fixture
included a BookingItem row at the time. The new
`_BookingItemResponseSerializer` is purpose-built for the snapshot
shape: `{id, sub_service_id, sub_service_name, quantity, price_charged,
line_total, sourced_quote_id}`. The frontend `BookingItemModel` consumes
exactly this shape.

---

## Tests — 130 frontend + 15 backend pinning regressions

Phase C of the impl: all 23 audit findings (cycle 1 + cycle 2 — see
`booking_orchestrator_sprint/AUDIT.md` and `AUDIT_CYCLE_2.md`) are pinned
by regressions, plus the structural seams that have no audit ID but are
load-bearing for the realtime refresh chain.

### Frontend test files (mirrored under `frontend/test/features/orchestrator/`)

| File | # tests | Pinning purpose |
|---|---:|---|
| `_helpers/booking_detail_fixture.dart` | — | Shared `bookingDetailJson({...})` factory used by 9+ files. |
| `data/mappers/booking_detail_mapper_test.dart` | 9 | Viewer-role derivation, `child_booking_id` mapping, Decimal-string → integer rupees, booking_items `price_charged` decode, status enum decode, ISO-string `phase_timestamps` → `DateTime`. |
| `data/mappers/booking_event_payload_mapper_test.dart` | 11 | `extractJobId` int/double/string/bool/list/missing branches; `extractChildBookingId` early-out on wrong event type. |
| `data/datasources/booking_detail_remote_data_source_test.dart` | 7 | URL = `${AppConstants.baseUrl}/bookings/<id>/`, `Authorization: Token` header, HttpFailure envelope parse, non-JSON HTML 5xx fallback, 204 → FormatException. |
| `data/datasources/booking_detail_local_data_source_test.dart` | 8 | SharedPreferences round-trip, corrupted entry → null, `orchestrator_booking_detail_v1_` prefix contract, isolation across booking ids. |
| `data/repositories/booking_detail_repository_impl_test.dart` | 12 | Full sealed-failure pipeline (404 → NotFound, 403 not_a_participant → NotParticipant, 5xx → ServerFailure, other → Unknown), SocketException with/without cache, evict-on-mapper-error in both online and offline paths. |
| `presentation/providers/dependency_injection_test.dart` | 2 | Repository provider's StateError when `currentAuthUserIdProvider` is null (Riverpod 3 wraps in ProviderException — predicate-matched on `e.toString().contains('authenticated user')`). |
| `presentation/providers/booking_action_executor_test.dart` | 6 | POST with auth + body; **DELETE without body** (critical guard — verified via `verifyNever(client.delete(any(), headers: any(named:'headers'), body: any(named:'body')))`); HttpFailure mapping; non-JSON fallback; unsupported method StateError. |
| `presentation/providers/booking_orchestrator_events_notifier_test.dart` | 5 | Loop over all 12 trigger event types asserting refresh; `bookingRescheduled` NOT in trigger set; jobId mismatch dropped; previous-equals-next event id dedup. |
| `presentation/providers/booking_rescheduled_notifier_test.dart` | 5 | Pumps real GoRouter; `pushReplacement` to `/booking/<child>` on match; non-rescheduled events dropped; jobId mismatch; missing `child_booking_id`; dedup. |
| `presentation/widgets/sheets/booking_action_pending_sheet_test.dart` | 5 | Long body scrolls (descendant `SingleChildScrollView`); HttpFailure → inline error; sheet stays open on confirm error. |
| `presentation/widgets/slots/header_slot_test.dart` | 7 | "Continued on #N" link only when CANCELLED + childBookingId set; tap navigates via real GoRouter; "Rescheduled from #N"; viewer-role counterparty. |
| `presentation/widgets/slots/timeline_slot_test.dart` | 16 | Current-dot mapping (INSPECTING + QUOTED → "Quote"; IN_PROGRESS + COMPLETED + COMPLETED_INSPECTION_ONLY → "Done"); 6 terminal statuses → no current marker. Heuristic: `FontWeight.w600` on the bolded label is the only observable signal of `_PhaseState.current`. |
| `presentation/widgets/slots/body_slot_test.dart` | 15 | Exhaustive matrix across all 14 BookingStatus values × dedicated stub class; pending + unknown both → UnknownBodyStub. Catches a typo'd switch arm (e.g. `arrived → quoted`) which Dart's exhaustiveness check wouldn't. |
| `presentation/widgets/slots/secondary_actions_slot_test.dart` | 4 | `Wrap.runSpacing > 0`; dispute button visible iff `showDisputeButton`; `SizedBox.shrink` when empty. |
| `presentation/widgets/slots/primary_action_slot_test.dart` | 3 | Null primaryAction → no FilledButton; non-null renders FilledButton with EXACT server label (no `.toUpperCase()` — dumb-UI principle). |
| `presentation/widgets/booking_orchestrator_action_button_test.dart` | 8 | en-route direct POST (no body); confirm-cash auto body `{cash_amount: 1500}`; cancel opens "Cancel booking?" sheet; busy state shows `CircularProgressIndicator`; SocketException SnackBar; HttpFailure SnackBar; reschedule and dispute "coming soon" sheets. |
| `presentation/screens/booking_orchestrator_screen_test.dart` | 3 | Smoke + load-bearing **`ref.watch` contract** test: mount → push `tech_en_route` via fake `systemEventProvider` → assert `_CountingRepo.callCount` 1 → 2 (events notifier alive). Unrelated event types leave callCount at 1. |
| **Frontend total** | **~130** | |

Plus 4 sibling tests in non-orchestrator paths that ship in the same session:

| File | # tests | Pinning purpose |
|---|---:|---|
| `frontend/test/core/routing/app_router_test.dart` | 4 | `/booking/abc`, `/booking/0`, `/booking/-3` → `_InvalidBookingLinkScreen`; `/booking/42` → orchestrator. Warmed via `await container.read(authProvider.future)` so the routerProvider isn't read while auth is `AsyncLoading`. |
| `test/core/realtime/presentation/router/event_urgency_router_test.dart` | (extended) | All 5 new event types — banner copy, icon, title, tap-target substitution. |
| `test/features/customer/bookings/presentation/widgets/booking_card_test.dart` | (extended) | Tap path is `/booking/<id>` not `/customer/booking/<id>`. |

### Backend test additions

| File | # tests | Pinning purpose |
|---|---:|---|
| `tests/bookings/api/test_booking_detail_api.py` | +3 | Profile-picture URL is absolute when present (uses `request.build_absolute_uri`); null when absent; `show_dispute_button` matrix across all 13 statuses (True for IN_PROGRESS / COMPLETED / COMPLETED_INSPECTION_ONLY / NO_SHOW; False for AWAITING / CONFIRMED / EN_ROUTE / ARRIVED / INSPECTING / QUOTED / CANCELLED / REJECTED / DISPUTED — already-disputed). |
| `tests/bookings/selectors/test_orchestrator_ui_selector.py` | +12 | Endpoint-string invariants (no `/api/`, no `<id>` placeholder); customer-quoted endpoints interpolate `active_quote.id`; defensive None-branch when no active quote; the full `_customer_quoted` body shape under both branches. |
| **Backend total (session 3 additions)** | **15** | |

### Pipeline-level guarantees inherited by every event (no per-feature wiring)

The transport layer (`SystemEventNotifier`) enforces these once and the
orchestrator events ride on them — DO NOT re-implement per feature:

- Source-tagged ingestion (`ws` / `fcm` / `sync`).
- Server-time anchor (seeded only by `source: ws`).
- Recipient filter (`recipientUserId == currentAuthUserId`).
- Expiry filter (against the server-anchored now).
- 24-hour windowed dedup keyed on envelope `id`.
- BG-isolate queue cap (`_kMaxPendingBackgroundEvents = 50`).

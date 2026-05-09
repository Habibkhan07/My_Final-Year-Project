# Session 3 — Orchestrator Frontend Skeleton

> Third session of the Booking Orchestrator sprint. Builds the Flutter skeleton: one screen at `/booking/:job_id`, a status-driven slot architecture, hydration via `bookingDetailProvider`, per-event notifiers, and stub body widgets for every status. Sessions 4–6 will fill the stub bodies with real maps, quote-builder UI, and edge-case flows.
>
> **Out of scope**: real maps / live tracking widget (session 4), quote builder UI / customer approval sheet / cash collection screen (session 5), cancellation/no-show/dispute UIs (session 6), all backend changes.

---

## §0 Sprint context

This is **session 3 of 6**. Cross-cutting decisions in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md). Sessions 1–2 shipped backend foundations + endpoints. This session is the **frontend skeleton** — the screen + slot architecture + event plumbing + stubs.

Session 1+2 invariants this session relies on:
- `GET /api/bookings/<id>/` returns the full booking-detail payload (per session 2 §4.6) including `ui` block, `available_transitions`, `active_quote`, `booking_items`, `phase_timestamps`, `pricing`, `cash_collection`, `parent_booking_id`.
- All 14 transition endpoints and the 5 new event types are live.
- `tech_gps` stream + WS subscribe/unsubscribe contract is live (used by session 4, not this session).

What sessions 4–6 will fill in:
- **Session 4** — Replace the `EnRouteBodyStub` and `ArrivedBodyStub` with the real dual-provider live-tracking widget. Also Android foreground GPS service.
- **Session 5** — Replace `InspectingBodyStub`, `QuotedBodyStub`, `InProgressBodyStub`, `CompletedBodyStub`, `CompletedInspectionOnlyBodyStub` with quote-builder, approval sheet, cash-collection UIs.
- **Session 6** — Cancellation modals, no-show buttons (single-tap per §14), dispute open form, reschedule flow. Closes flag #26.

This session ships **stub widgets per status that show the correct copy + render the action buttons from the server's `ui` block** — enough to be navigable end-to-end on a happy-path demo (without real maps or quote-builder).

---

## §1 Decisions taken (session-local only)

Cross-sprint decisions in sprint meta §4. Decisions specific to this session:

1. **Feature folder name: `orchestrator`** under `frontend/lib/features/`. Per CLAUDE.md "audience-first placement," this feature is shared across customer + technician roles (the screen adapts via `viewer_role`), so it's not under `customer/` or `technician/`. New top-level folder.
2. **Single screen `BookingOrchestratorScreen`** — one widget that adapts to status. No separate screens per status. Status changes during the screen's lifetime (e.g., AWAITING → CONFIRMED via realtime event) are absorbed by the slot widgets re-rendering.
3. **Slot architecture**: `HeaderSlot`, `TimelineSlot`, `BodySlot`, `PrimaryActionSlot`, `SecondaryActionsSlot` (5 slots, fixed positions). The screen's `build()` is just a `Column` of slots. Each slot reads from `bookingDetailProvider(jobId)` independently — they don't communicate.
4. **`BodySlot` is a switch on `booking.status`** that renders the correct stub widget. This is the ONLY status-driven branch in the frontend; everything else (status label, action labels, button visibility) flows from the server's `ui` block.
5. **One Riverpod notifier handles all booking-orchestrator events for a given jobId** — `bookingOrchestratorEventsNotifier(jobId)`. It listens to `systemEventProvider`, filters by relevant event types AND `payload.job_id == jobId`, and `ref.invalidate(bookingDetailProvider(jobId))` to trigger refetch.
   - Rationale: 13 events all do the same thing (refresh detail). Per-event notifiers would be 13 nearly-identical files. CLAUDE.md's "no central switch" rule applies to `core/realtime` (we're not editing that); within a feature, a single multi-event filter is idiomatic and matches the existing `customer_bookings_list_notifier.dart` pattern.
   - Events with **additional behavior beyond refresh** (e.g., `quote_revision_requested` triggers tech-side nav to quote builder; `booking_rescheduled` triggers nav to child booking detail) DO get their own notifier. This sprint, only `booking_rescheduled` ships its own notifier — `quote_revision_requested` is just a refresh because the screen's slot architecture handles the QUOTED → INSPECTING transition naturally (the body slot re-renders on status change).
6. **`bookingDetailProvider` is `keepAlive: false` and `family<int>`** — disposed when no longer watched. The orchestrator screen is the only consumer; when navigated away, the cache is gone (next mount re-fetches).
7. **Offline-first cache**: `BookingDetailLocalDataSource` caches the most-recent detail response per jobId in `SharedPreferences` for crash recovery. Used as fallback only on `SocketException` for first fetch; subsequent fetches always hit network.
8. **Domain `BookingStatus` enum extension** — the existing `BookingStatus` enum (in `lib/features/customer/bookings/domain/entities/booking_status.dart`) is single-source for both the bookings list and the orchestrator. Extend with the 8 new statuses there; orchestrator imports from there. Existing list code unaffected.
9. **Stub widgets are NOT placeholders.** They render a usable card with copy from the server's `ui.body_text` + action buttons from `ui.primary_action` and `ui.secondary_actions`. A demo can walk happy-path with stubs alone. Sessions 4–6 replace the stub *bodies* (the specialized parts: maps, quote builder, etc.) but keep the surrounding chrome.
10. **Action buttons read from `ui` block, never compute from status.** Tap = POST to `ui.primary_action.endpoint` (or appropriate secondary). Result handling is in the action-button widget, not the screen. On 200 → invalidate `bookingDetailProvider`; on 4xx → snackbar with mapped message.
11. **`available_transitions` is informational only** for v1 — the buttons we render come from `ui.primary_action` / `ui.secondary_actions`. Frontend doesn't pre-validate transitions client-side; server is authoritative. `available_transitions` is captured in the model for future use (e.g., gating overflow menu items in session 6's tech-cancel UI).
12. **Bookings list patch mapper extension** — extend `customer/bookings/data/mappers/booking_event_patch_mapper.dart` to recognize the 5 new event types and patch the list item correctly. Reuse `BookingStatus.fromWire` for status decoding. Don't duplicate the mapper logic in the orchestrator feature — the list and the orchestrator share the same status enum.
13. **`BookingPhaseTimestamps`, `BookingPricing`, `BookingCashCollection` are flat Freezed value objects** carried inside `BookingDetail`. Not separate domain entities — they're shapes, not behaviors.
14. **`BookingUiAction` is a flat record of `{label, endpoint, method, style}`.** Frontend builds `Uri.parse(endpoint)` and POSTs with the auth token. Server's endpoint string is the source of truth — frontend never constructs its own endpoint URLs for orchestrator actions.
15. **Tests this session focus on the screen + notifier + repository.** Widget tests inject a hardcoded `BookingDetail` Freezed model and assert: correct slots render, action buttons match `ui` block, status-changes propagate (via Riverpod state changes). Notifier tests use `ProviderContainer` per CLAUDE.md.
16. **Per-event payload models live in `data/models/booking_event_payloads.dart`** (single file with all 5 new payloads + the 8 existing-but-newly-wired payloads). Mappers in `data/mappers/booking_event_payload_mapper.dart` (one file). Avoids 26 small files for what is effectively a uniform "extract job_id from payload" operation.

17. **Audit-cycle-1 fixes shipped this session** (see [`AUDIT.md`](./AUDIT.md) and sprint meta §25):
    - **P0-03 / §24 transport**: every "Dio impl" code block in this session is illustrative only. Real implementation uses `package:http` per the canonical pattern in `BOOKING_ORCHESTRATOR_SPRINT.md §24`. Substitute mentally: `Dio _dio` → `http.Client _client`; `_dio.get(url, options: Options(headers: ...))` → `_client.get(Uri.parse(url), headers: ...)`; `DioException catch` → `_ensureOk(response)` style. Provider wiring uses the existing `eventHttpClient` Riverpod provider — **do not** instantiate per-data-source.
    - **P0-04 path**: `event_urgency_router.dart` lives at `lib/core/realtime/presentation/router/`, not `lib/core/realtime/router/`.
    - **P1-11 logging**: `UnknownBodyStub` logs a warning when `booking.status == BookingStatus.pending` so legacy-row sightings surface during QA.
    - **CSC-01 provider name**: the generated provider name is `bookingDetailNotifierProvider` (class is `BookingDetailNotifier`); references throughout this session use this name.
    - **CSC-02 invalidate vs refresh**: standardize on `ref.invalidate(bookingDetailNotifierProvider(jobId))` for event-driven refetches; `notifier.refresh()` is reserved for explicit user-initiated reloads (Retry button).
    - **CSC-03 nullable signature**: `BookingStatus.fromWire` keeps the existing `(String? raw)` nullable signature; the extension preserves backward compat.

---

## §2 Files this session touches

### Frontend feature folder (all new under `frontend/lib/features/orchestrator/`)

#### Domain layer

| File | Purpose |
|---|---|
| `domain/entities/booking_detail.dart` | Top-level `BookingDetail` Freezed entity. |
| `domain/entities/booking_quote.dart` | `BookingQuote` + `BookingQuoteLineItem` Freezed entities. |
| `domain/entities/booking_item.dart` | `BookingItem` Freezed entity (final accepted line items). |
| `domain/entities/booking_ui_block.dart` | `BookingUiBlock` + `BookingUiAction` + `BookingUiTone` enum. |
| `domain/entities/booking_phase_timestamps.dart` | Flat value object for the 7 phase timestamps. |
| `domain/entities/booking_pricing.dart` | Flat value object for inspection_fee/base_services_total/discount/etc. |
| `domain/entities/booking_cash_collection.dart` | Flat value object for cash collection state. |
| `domain/entities/booking_orchestrator_role.dart` | Enum: `customer`, `technician` (derived from auth + booking). |
| `domain/failures/booking_detail_failure.dart` | Sealed failure hierarchy. |
| `domain/repositories/booking_detail_repository.dart` | Repository interface. |
| `domain/use_cases/get_booking_detail_use_case.dart` | Use case wrapper. |

Plus: extend `frontend/lib/features/customer/bookings/domain/entities/booking_status.dart` with 8 new enum values (modified, not new).

#### Data layer

| File | Purpose |
|---|---|
| `data/models/booking_detail_model.dart` | DTO + Freezed JSON serialization for the booking-detail response. |
| `data/models/booking_quote_model.dart` | Quote + line item DTOs. |
| `data/models/booking_item_model.dart` | BookingItem DTO. |
| `data/models/booking_ui_block_model.dart` | UI block DTOs. |
| `data/models/booking_event_payloads.dart` | All 13 event payload Freezed models in one file. |
| `data/mappers/booking_detail_mapper.dart` | DTO → domain entity. |
| `data/mappers/booking_event_payload_mapper.dart` | Per-event payload mappers (one function per event). |
| `data/datasources/booking_detail_remote_data_source.dart` | http-based fetch (per sprint meta §24 canonical pattern; audit P0-03). |
| `data/datasources/booking_detail_local_data_source.dart` | SharedPreferences cache. |
| `data/repositories/booking_detail_repository_impl.dart` | Offline-first impl. |

#### Presentation layer

| File | Purpose |
|---|---|
| `presentation/providers/dependency_injection.dart` | Riverpod providers for `orchestratorSecureStorage` (per-feature), datasources, repository, use case. (HTTP client reuses the existing `eventHttpClientProvider` singleton from realtime DI; do not instantiate per-data-source.) |
| `presentation/providers/booking_detail_provider.dart` | `bookingDetailProvider(jobId)` family + .g.dart. |
| `presentation/providers/booking_orchestrator_events_notifier.dart` | Multi-event listener; refreshes detail on event arrival. |
| `presentation/providers/booking_rescheduled_notifier.dart` | Standalone notifier for `booking_rescheduled` (has nav side effect). |
| `presentation/providers/booking_action_executor.dart` | Helper to POST to `ui.primary_action.endpoint` and surface errors. |
| `presentation/screens/booking_orchestrator_screen.dart` | The screen itself. |
| `presentation/widgets/slots/header_slot.dart` | Status label + tone badge + counterparty name. |
| `presentation/widgets/slots/timeline_slot.dart` | Compact phase-timestamp progression dots. |
| `presentation/widgets/slots/body_slot.dart` | Switch on status → renders the correct stub body widget. |
| `presentation/widgets/slots/primary_action_slot.dart` | Renders the primary action button from `ui.primary_action`. |
| `presentation/widgets/slots/secondary_actions_slot.dart` | Renders secondary action buttons from `ui.secondary_actions`. |
| `presentation/widgets/booking_orchestrator_action_button.dart` | The action button widget itself (handles POST, snackbar, refresh). |
| `presentation/widgets/stub_bodies/all_status_stubs.dart` | All 13 stub body widgets in one file. |

#### Routing + bootstrapping

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/core/routing/app_router.dart` | **modified** | Add `GoRoute` for `/booking/:job_id`. |
| `frontend/lib/core/realtime/domain/entities/system_event_type.dart` | **modified** | Add 5 new event types (`quoteRevisionRequested`, `quoteDeclined`, `bookingCancelled`, `bookingNoShow`, `bookingRescheduled`). |
| `frontend/lib/core/realtime/domain/entities/event_urgency.dart` | **modified** | Map new event types to urgency levels. |
| `frontend/lib/core/realtime/domain/entities/event_criticality.dart` | **modified** | Add critical types if any (per backend, none of the 5 new are critical). |
| `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart` | **modified** | Add new event routes, payload keys, banner copy. |

#### Bookings list integration (modified)

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart` | **modified** | Handle 5 new event types when patching list items. |

#### Documentation

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | **new** | Feature doc per CLAUDE.md mandate. |

#### Tests

| File | Purpose |
|---|---|
| `frontend/test/features/orchestrator/data/repositories/booking_detail_repository_impl_test.dart` | Repository offline-first behavior. |
| `frontend/test/features/orchestrator/data/mappers/booking_detail_mapper_test.dart` | DTO → entity correctness. |
| `frontend/test/features/orchestrator/data/mappers/booking_event_payload_mapper_test.dart` | All 13 event payloads parse correctly. |
| `frontend/test/features/orchestrator/presentation/providers/booking_detail_provider_test.dart` | Provider hydration + offline fallback. |
| `frontend/test/features/orchestrator/presentation/providers/booking_orchestrator_events_notifier_test.dart` | Multi-event filter + refresh trigger. |
| `frontend/test/features/orchestrator/presentation/providers/booking_rescheduled_notifier_test.dart` | Nav side effect on rescheduled event. |
| `frontend/test/features/orchestrator/presentation/screens/booking_orchestrator_screen_test.dart` | Full-screen widget test with hardcoded BookingDetail injections. |
| `frontend/test/features/orchestrator/presentation/widgets/slots/body_slot_test.dart` | Body switch by status. |
| `frontend/test/features/orchestrator/presentation/widgets/booking_orchestrator_action_button_test.dart` | Action button POST + error mapping. |
| `frontend/test/features/customer/bookings/data/mappers/booking_event_patch_mapper_test.dart` | **modified** | Add coverage for 5 new event types. |

### Files NOT touched

- All `backend/` — sessions 1–2.
- Existing widgets in other features.
- The Flutter side of realtime infra (`SystemEventNotifier`, `WsFrameDispatcher`, etc.) — used as-is.
- The Stitch design tokens / global theme (planned UI cleanup pass per memory).

---

## §3 Pre-flight

```bash
# 1. Repo + branch
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main

# 2. Confirm sessions 1 + 2 landed
ls backend/bookings/services/orchestrator.py
ls backend/bookings/api/booking_detail/views.py
ls backend/bookings/api/transitions/views.py

# 3. Confirm backend running locally (we'll hit GET /api/bookings/<id>/)
cd backend
source venv/bin/activate
python manage.py runserver &
sleep 2
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/api/bookings/1/   # 401 (no token)
kill %1
cd ..

# 4. Frontend baseline
cd frontend
flutter pub get
flutter analyze
flutter test                    # green baseline

# 5. Confirm existing realtime layer alive
grep -n "class WsFrameDispatcher" lib/core/realtime/presentation/services/ws_frame_dispatcher.dart
grep -n "class SystemEventNotifier" lib/core/realtime/presentation/notifiers/system_event_notifier.dart
grep -n "class EventUrgencyRouter" lib/core/realtime/presentation/router/event_urgency_router.dart

# 6. Confirm existing BookingStatus enum we'll extend
cat lib/features/customer/bookings/domain/entities/booking_status.dart

# 7. Confirm existing patch mapper we'll extend
cat lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart

# 8. Run build_runner once to get a clean baseline of generated files
dart run build_runner build --delete-conflicting-outputs
```

---

## §4 Per-file detailed changes

### §4.0 Architecture overview

Three-layer Clean Architecture per CLAUDE.md, mirroring the existing pattern in `lib/features/customer/bookings/`:

- **Domain** — pure Dart entities + repository interface + use case + sealed failures.
- **Data** — DTOs (Freezed + json_serializable) + mappers + datasources (remote `package:http`, local SharedPreferences) + repository impl.
- **Presentation** — Riverpod providers + notifiers + screen + widgets.

**Realtime integration** is layered:
1. Backend fires event → WS frame arrives → `WsFrameDispatcher` → `SystemEventNotifier.processEvent` (existing, unchanged).
2. `SystemEventNotifier` updates state with the latest event.
3. `bookingOrchestratorEventsNotifier(jobId)` listens, filters, calls `ref.invalidate(bookingDetailProvider(jobId))`.
4. `bookingDetailProvider(jobId)` re-fetches via repository.
5. Screen rebuilds with new state.

For events that NAV (push or replace route — `booking_rescheduled` for tech, sometimes `dispute_resolved`):
1. `EventUrgencyRouter` checks if event is on the orchestrator screen for matching jobId; if so, it does NOT push (already there).
2. The event-specific notifier (e.g. `bookingRescheduledNotifier`) handles the nav action (replace current route with `/booking/<child_id>`).

### §4.1 Domain entities

#### `domain/entities/booking_detail.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../customer/bookings/domain/entities/booking_status.dart';
import 'booking_quote.dart';
import 'booking_item.dart';
import 'booking_ui_block.dart';
import 'booking_phase_timestamps.dart';
import 'booking_pricing.dart';
import 'booking_cash_collection.dart';
import 'booking_orchestrator_role.dart';

part 'booking_detail.freezed.dart';

/// Top-level entity for the orchestrator screen. Hydrated from
/// GET /api/bookings/<id>/ (session 2 §4.6).
///
/// All status-driven UI flows from [ui]; the screen never branches on [status]
/// to compute copy or button labels. Per CLAUDE.md dumb-UI principle.
@freezed
class BookingDetail with _$BookingDetail {
  const factory BookingDetail({
    required int id,
    required BookingStatus status,
    required BookingService service,
    BookingSubService? subService,
    required BookingTechnician technician,
    required BookingCustomer customer,
    BookingAddress? address,
    required String addressSnapshot,    // denormalized, survives address deletion
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required BookingPhaseTimestamps phaseTimestamps,
    required BookingPricing pricing,
    required BookingCashCollection cashCollection,
    int? parentBookingId,                // reschedule lineage
    String? cancelReason,
    String? noShowActor,                 // 'tech' | 'customer'
    BookingQuote? activeQuote,           // present when status == QUOTED (and at IN_PROGRESS for upsell)
    @Default([]) List<BookingItem> bookingItems,  // accepted snapshots
    @Default(0) int openTicketsCount,
    required BookingUiBlock ui,
    @Default([]) List<String> availableTransitions,
    required BookingOrchestratorRole viewerRole,    // derived in mapper from auth + booking participants
  }) = _BookingDetail;
}

@freezed
class BookingService with _$BookingService {
  const factory BookingService({
    required int id,
    required String name,
    required String iconName,
  }) = _BookingService;
}

@freezed
class BookingSubService with _$BookingSubService {
  const factory BookingSubService({
    required int id,
    required String name,
    required bool isFixedPrice,
    required int basePrice,
    int? maxPrice,
  }) = _BookingSubService;
}

@freezed
class BookingTechnician with _$BookingTechnician {
  const factory BookingTechnician({
    required int id,
    required String displayName,
    String? profilePictureUrl,
  }) = _BookingTechnician;
}

@freezed
class BookingCustomer with _$BookingCustomer {
  const factory BookingCustomer({
    required int id,
    required String fullName,
    required String phoneNo,
  }) = _BookingCustomer;
}

@freezed
class BookingAddress with _$BookingAddress {
  const factory BookingAddress({
    required String label,
    required double latitude,
    required double longitude,
    required String addressText,
  }) = _BookingAddress;
}
```

#### `domain/entities/booking_quote.dart`

```dart
@freezed
class BookingQuote with _$BookingQuote {
  const factory BookingQuote({
    required int id,
    required int bookingId,
    required int revisionNumber,
    required BookingQuoteStatus status,
    required int totalAmount,           // typed integer rupees (mapper converts string → int)
    required bool isUpsell,
    required List<BookingQuoteLineItem> lineItems,
    DateTime? submittedAt,
  }) = _BookingQuote;
}

@freezed
class BookingQuoteLineItem with _$BookingQuoteLineItem {
  const factory BookingQuoteLineItem({
    required int id,
    required int subServiceId,
    required String subServiceName,
    required int quantity,
    required int pricedAt,             // typed integer rupees
    required int lineTotal,
  }) = _BookingQuoteLineItem;
}

enum BookingQuoteStatus {
  draft, submitted, approved, declined, superseded, unknown;

  static BookingQuoteStatus fromWire(String wire) => switch (wire) {
    'DRAFT' => BookingQuoteStatus.draft,
    'SUBMITTED' => BookingQuoteStatus.submitted,
    'APPROVED' => BookingQuoteStatus.approved,
    'DECLINED' => BookingQuoteStatus.declined,
    'SUPERSEDED' => BookingQuoteStatus.superseded,
    _ => BookingQuoteStatus.unknown,
  };
}
```

#### `domain/entities/booking_item.dart`

```dart
@freezed
class BookingItem with _$BookingItem {
  const factory BookingItem({
    required int id,
    required int subServiceId,
    required String subServiceName,
    required int quantity,
    required int priceCharged,
    required int lineTotal,
    int? sourcedQuoteId,
  }) = _BookingItem;
}
```

#### `domain/entities/booking_ui_block.dart`

```dart
@freezed
class BookingUiBlock with _$BookingUiBlock {
  const factory BookingUiBlock({
    required String statusLabel,
    required String bodyText,
    BookingUiAction? primaryAction,
    @Default([]) List<BookingUiAction> secondaryActions,
    required bool showTracking,
    required bool showQuoteCard,
    required bool showDisputeButton,
    required BookingUiTone tone,
  }) = _BookingUiBlock;
}

@freezed
class BookingUiAction with _$BookingUiAction {
  const factory BookingUiAction({
    required String label,
    required String endpoint,           // server-emitted; frontend constructs Uri.parse(...)
    required String method,             // 'POST' | 'GET' | etc.
    BookingUiActionStyle? style,
  }) = _BookingUiAction;
}

enum BookingUiActionStyle {
  primary, destructive, neutral, unknown;

  static BookingUiActionStyle fromWire(String? wire) => switch (wire) {
    'primary' => BookingUiActionStyle.primary,
    'destructive' => BookingUiActionStyle.destructive,
    'neutral' => BookingUiActionStyle.neutral,
    _ => BookingUiActionStyle.unknown,
  };
}

enum BookingUiTone {
  positive, warning, negative, neutral, info, unknown;

  static BookingUiTone fromWire(String wire) => switch (wire) {
    'positive' => BookingUiTone.positive,
    'warning' => BookingUiTone.warning,
    'negative' => BookingUiTone.negative,
    'neutral' => BookingUiTone.neutral,
    'info' => BookingUiTone.info,
    _ => BookingUiTone.unknown,
  };
}
```

#### `domain/entities/booking_phase_timestamps.dart`

```dart
@freezed
class BookingPhaseTimestamps with _$BookingPhaseTimestamps {
  const factory BookingPhaseTimestamps({
    DateTime? acceptedAt,
    DateTime? enRouteStartedAt,
    DateTime? arrivedAt,
    DateTime? inspectionStartedAt,
    DateTime? quoteFirstSubmittedAt,
    DateTime? workStartedAt,
    DateTime? completedAt,
  }) = _BookingPhaseTimestamps;
}
```

#### `domain/entities/booking_pricing.dart`

```dart
@freezed
class BookingPricing with _$BookingPricing {
  const factory BookingPricing({
    int? inspectionFee,
    int? baseServicesTotal,
    int? discountApplied,
    int? finalCashToCollect,
    String? promoCodeSnapshot,
    int? promoDiscountSnapshot,
  }) = _BookingPricing;
}
```

#### `domain/entities/booking_cash_collection.dart`

```dart
@freezed
class BookingCashCollection with _$BookingCashCollection {
  const factory BookingCashCollection({
    int? amount,
    DateTime? at,
    @Default('cash') String method,
  }) = _BookingCashCollection;
}
```

#### `domain/entities/booking_orchestrator_role.dart`

```dart
enum BookingOrchestratorRole {
  customer, technician;
}
```

#### Extension to `customer/bookings/domain/entities/booking_status.dart` (modified)

Existing enum has `awaiting`, `confirmed`, `completed`, `cancelled`, `rejected`, `pending`, `unknown`. Add:

```dart
enum BookingStatus {
  awaiting, confirmed,
  enRoute, arrived, inspecting, quoted, inProgress,        // NEW
  completed, completedInspectionOnly,                       // NEW: completedInspectionOnly
  cancelled, rejected, noShow, disputed,                    // NEW: noShow, disputed
  pending, unknown;

  // Audit CSC-03: keep existing nullable signature `fromWire(String? raw)`.
  // Extension is purely additive — new wire strings appear in the lookup;
  // `null` and unknown strings fall to BookingStatus.unknown as before.
  static const Map<String, BookingStatus> _wireLookup = {
    'AWAITING': BookingStatus.awaiting,
    'CONFIRMED': BookingStatus.confirmed,
    'EN_ROUTE': BookingStatus.enRoute,
    'ARRIVED': BookingStatus.arrived,
    'INSPECTING': BookingStatus.inspecting,
    'QUOTED': BookingStatus.quoted,
    'IN_PROGRESS': BookingStatus.inProgress,
    'COMPLETED': BookingStatus.completed,
    'COMPLETED_INSPECTION_ONLY': BookingStatus.completedInspectionOnly,
    'CANCELLED': BookingStatus.cancelled,
    'REJECTED': BookingStatus.rejected,
    'NO_SHOW': BookingStatus.noShow,
    'DISPUTED': BookingStatus.disputed,
    'PENDING': BookingStatus.pending,
  };

  static BookingStatus fromWire(String? raw) {
    if (raw == null) return BookingStatus.unknown;
    return _wireLookup[raw.toUpperCase()] ?? BookingStatus.unknown;
  }

  String get wireValue => switch (this) {
    BookingStatus.awaiting => 'AWAITING',
    BookingStatus.confirmed => 'CONFIRMED',
    BookingStatus.enRoute => 'EN_ROUTE',
    BookingStatus.arrived => 'ARRIVED',
    BookingStatus.inspecting => 'INSPECTING',
    BookingStatus.quoted => 'QUOTED',
    BookingStatus.inProgress => 'IN_PROGRESS',
    BookingStatus.completed => 'COMPLETED',
    BookingStatus.completedInspectionOnly => 'COMPLETED_INSPECTION_ONLY',
    BookingStatus.cancelled => 'CANCELLED',
    BookingStatus.rejected => 'REJECTED',
    BookingStatus.noShow => 'NO_SHOW',
    BookingStatus.disputed => 'DISPUTED',
    BookingStatus.pending => 'PENDING',
    BookingStatus.unknown => 'UNKNOWN',
  };
}
```

The bookings list code that imports this enum continues to work — new values are additive.

### §4.2 Domain failures + repository contract + use case

#### `domain/failures/booking_detail_failure.dart`

```dart
sealed class BookingDetailFailure implements Exception {
  const BookingDetailFailure();
}

class BookingDetailNotFound extends BookingDetailFailure {
  final int bookingId;
  const BookingDetailNotFound(this.bookingId);
}

class BookingDetailNotParticipant extends BookingDetailFailure {
  const BookingDetailNotParticipant();
}

class BookingDetailNetworkFailure extends BookingDetailFailure {
  const BookingDetailNetworkFailure();
}

class BookingDetailServerFailure extends BookingDetailFailure {
  const BookingDetailServerFailure();
}

class BookingDetailOfflineNoCache extends BookingDetailFailure {
  const BookingDetailOfflineNoCache();
}

class UnknownBookingDetailFailure extends BookingDetailFailure {
  final String message;
  const UnknownBookingDetailFailure(this.message);
}
```

#### `domain/repositories/booking_detail_repository.dart`

```dart
abstract class IBookingDetailRepository {
  /// Fetch the booking detail for orchestrator screen.
  /// 
  /// Throws [BookingDetailNotFound] for 404,
  /// [BookingDetailNotParticipant] for 403 ('not_a_participant'),
  /// [BookingDetailNetworkFailure] on SocketException,
  /// [BookingDetailServerFailure] on 5xx,
  /// [BookingDetailOfflineNoCache] when offline + no local cache,
  /// [UnknownBookingDetailFailure] on any other.
  Future<BookingDetail> getBookingDetail(int bookingId);
}
```

#### `domain/use_cases/get_booking_detail_use_case.dart`

```dart
class GetBookingDetailUseCase {
  final IBookingDetailRepository _repository;
  GetBookingDetailUseCase(this._repository);

  Future<BookingDetail> call(int bookingId) =>
      _repository.getBookingDetail(bookingId);
}
```

### §4.3 Data models + mappers

#### `data/models/booking_detail_model.dart` (Freezed + json_serializable)

```dart
@freezed
class BookingDetailModel with _$BookingDetailModel {
  const factory BookingDetailModel({
    required int id,
    required String status,
    required Map<String, dynamic> service,
    Map<String, dynamic>? subService,
    required Map<String, dynamic> technician,
    required Map<String, dynamic> customer,
    Map<String, dynamic>? address,
    @JsonKey(name: 'address_snapshot') required String addressSnapshot,
    @JsonKey(name: 'scheduled_start') required String scheduledStart,
    @JsonKey(name: 'scheduled_end') required String scheduledEnd,
    @JsonKey(name: 'phase_timestamps') required Map<String, dynamic> phaseTimestamps,
    required Map<String, dynamic> pricing,
    @JsonKey(name: 'cash_collection') required Map<String, dynamic> cashCollection,
    @JsonKey(name: 'parent_booking_id') int? parentBookingId,
    @JsonKey(name: 'cancel_reason') String? cancelReason,
    @JsonKey(name: 'no_show_actor') String? noShowActor,
    @JsonKey(name: 'active_quote') Map<String, dynamic>? activeQuote,
    @JsonKey(name: 'booking_items') @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> bookingItems,
    @JsonKey(name: 'open_tickets_count') @Default(0) int openTicketsCount,
    required Map<String, dynamic> ui,
    @JsonKey(name: 'available_transitions') @Default(<String>[]) List<String> availableTransitions,
  }) = _BookingDetailModel;

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailModelFromJson(json);
}
```

The nested objects (`service`, `technician`, etc.) are kept as `Map<String, dynamic>` in the DTO and parsed in the mapper — keeps the DTO file readable. Alternative is to define nested DTOs; either is fine, but stay consistent with the existing `customer/bookings/data/models/` pattern (which uses nested DTOs). **Match the existing pattern.**

#### `data/mappers/booking_detail_mapper.dart`

```dart
class BookingDetailMapper {
  /// DTO → domain. Resolves [viewerRole] from the auth state vs booking participants.
  static BookingDetail toDomain(
    BookingDetailModel model, {
    required int currentUserId,
  }) {
    final customerId = model.customer['id'] as int;
    final technicianUserId = model.technician['user_id'] as int?;
    final viewerRole = customerId == currentUserId
        ? BookingOrchestratorRole.customer
        : BookingOrchestratorRole.technician;

    return BookingDetail(
      id: model.id,
      status: BookingStatus.fromWire(model.status),
      service: BookingService(
        id: model.service['id'] as int,
        name: model.service['name'] as String,
        iconName: model.service['icon_name'] as String,
      ),
      subService: model.subService == null ? null : BookingSubService(
        id: model.subService!['id'] as int,
        name: model.subService!['name'] as String,
        isFixedPrice: model.subService!['is_fixed_price'] as bool,
        basePrice: int.parse(model.subService!['base_price'].toString()),
        maxPrice: model.subService!['max_price'] == null
            ? null
            : int.parse(model.subService!['max_price'].toString()),
      ),
      technician: BookingTechnician(
        id: model.technician['id'] as int,
        displayName: model.technician['display_name'] as String,
        profilePictureUrl: model.technician['profile_picture_url'] as String?,
      ),
      customer: BookingCustomer(
        id: customerId,
        fullName: model.customer['full_name'] as String,
        phoneNo: model.customer['phone_no'] as String,
      ),
      address: model.address == null ? null : BookingAddress(
        label: model.address!['label'] as String,
        latitude: (model.address!['latitude'] as num).toDouble(),
        longitude: (model.address!['longitude'] as num).toDouble(),
        addressText: model.address!['address_text'] as String,
      ),
      addressSnapshot: model.addressSnapshot,
      scheduledStart: DateTime.parse(model.scheduledStart),
      scheduledEnd: DateTime.parse(model.scheduledEnd),
      phaseTimestamps: _phaseTimestamps(model.phaseTimestamps),
      pricing: _pricing(model.pricing),
      cashCollection: _cashCollection(model.cashCollection),
      parentBookingId: model.parentBookingId,
      cancelReason: model.cancelReason,
      noShowActor: model.noShowActor,
      activeQuote: model.activeQuote == null ? null : _quote(model.activeQuote!),
      bookingItems: model.bookingItems.map(_bookingItem).toList(),
      openTicketsCount: model.openTicketsCount,
      ui: _uiBlock(model.ui),
      availableTransitions: model.availableTransitions,
      viewerRole: viewerRole,
    );
  }

  // ... helper methods (_phaseTimestamps, _pricing, _cashCollection, _quote, _bookingItem, _uiBlock)
  // each does straightforward map → entity conversion with type coercion
  // (string-decimals → int rupees, ISO-8601 → DateTime, etc.)
}
```

The helper methods keep the main mapper readable. Each is ~10 lines.

### §4.4 Data sources

#### `data/datasources/booking_detail_remote_data_source.dart`

**Audit P0-03**: uses `package:http` per sprint meta §24 canonical pattern (NOT Dio — Dio isn't in pubspec). Reuses the singleton `eventHttpClient` from existing realtime DI.

```dart
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/common/errors/http_failure.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/booking_detail_model.dart';

abstract class IBookingDetailRemoteDataSource {
  Future<BookingDetailModel> fetch(int bookingId);
}

class BookingDetailRemoteDataSource implements IBookingDetailRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  BookingDetailRemoteDataSource(this._client, this._secureStorage);

  @override
  Future<BookingDetailModel> fetch(int bookingId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    // Audit C2-P0-01: AppConstants.baseUrl already includes '/api'; do NOT
    // re-add it. URL resolves to http://127.0.0.1:8000/api/bookings/<id>/.
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Accept': 'application/json',
      },
    );
    _ensureOk(response);
    return BookingDetailModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Throws [HttpFailure] on non-2xx. SocketException bubbles untouched and is
  /// caught at the repository layer (mapped to BookingDetailNetworkFailure).
  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    Map<String, dynamic>? envelope;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) envelope = decoded;
    } catch (_) { /* non-JSON body — fall through to generic message */ }
    throw HttpFailure(
      statusCode: response.statusCode,
      code: envelope?['code'] as String? ?? 'unknown',
      message: envelope?['message'] as String? ?? 'Request failed (${response.statusCode}).',
      errors: (envelope?['errors'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
```

DI wiring (in `presentation/providers/dependency_injection.dart`):

```dart
// Audit C2-P1-06: per-feature secure-storage provider (codebase convention).
// Don't reach into the auth feature for `flutterSecureStorageProvider` —
// breaks per-feature DI isolation. `FlutterSecureStorage` is a stateless
// wrapper, so multiple "instances" cost nothing.
@Riverpod(keepAlive: true)
FlutterSecureStorage orchestratorSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

@Riverpod(keepAlive: true)
BookingDetailRemoteDataSource bookingDetailRemoteDataSource(Ref ref) =>
    BookingDetailRemoteDataSource(
      ref.read(eventHttpClientProvider),         // existing realtime singleton
      ref.read(orchestratorSecureStorageProvider),    // audit C2-P1-06: per-feature provider
    );
```

#### `data/datasources/booking_detail_local_data_source.dart`

```dart
class BookingDetailLocalDataSource implements IBookingDetailLocalDataSource {
  final SharedPreferences _prefs;
  static const _kKeyPrefix = 'orchestrator_booking_detail_v1_';

  BookingDetailLocalDataSource(this._prefs);

  @override
  Future<void> cache(int bookingId, BookingDetailModel model) async {
    await _prefs.setString(
      '$_kKeyPrefix$bookingId',
      jsonEncode(model.toJson()),
    );
  }

  @override
  Future<BookingDetailModel?> read(int bookingId) async {
    final raw = _prefs.getString('$_kKeyPrefix$bookingId');
    if (raw == null) return null;
    try {
      return BookingDetailModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;  // corrupted entry; treat as absent
    }
  }

  @override
  Future<void> clear(int bookingId) async {
    await _prefs.remove('$_kKeyPrefix$bookingId');
  }
}

abstract class IBookingDetailLocalDataSource {
  Future<void> cache(int bookingId, BookingDetailModel model);
  Future<BookingDetailModel?> read(int bookingId);
  Future<void> clear(int bookingId);
}
```

### §4.5 Repository implementation (offline-first)

#### `data/repositories/booking_detail_repository_impl.dart`

```dart
class BookingDetailRepositoryImpl implements IBookingDetailRepository {
  final IBookingDetailRemoteDataSource _remote;
  final IBookingDetailLocalDataSource _local;
  final int _currentUserId;

  BookingDetailRepositoryImpl(this._remote, this._local, this._currentUserId);

  @override
  Future<BookingDetail> getBookingDetail(int bookingId) async {
    try {
      final model = await _remote.fetch(bookingId);
      // Best-effort cache; don't fail the request if cache write fails.
      _local.cache(bookingId, model).ignore();
      return BookingDetailMapper.toDomain(model, currentUserId: _currentUserId);
    } on SocketException {
      // Offline path — try local cache.
      final cached = await _local.read(bookingId);
      if (cached == null) throw const BookingDetailOfflineNoCache();
      return BookingDetailMapper.toDomain(cached, currentUserId: _currentUserId);
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e, bookingId);
    } catch (e) {
      throw UnknownBookingDetailFailure(e.toString());
    }
  }

  BookingDetailFailure _mapHttpFailure(HttpFailure e, int bookingId) {
    return switch (e.code) {
      'not_found' => BookingDetailNotFound(bookingId),
      'not_a_participant' => const BookingDetailNotParticipant(),
      _ => e.statusCode >= 500
          ? const BookingDetailServerFailure()
          : UnknownBookingDetailFailure(e.message),
    };
  }
}
```

### §4.6 Per-event payload models + mappers

#### `data/models/booking_event_payloads.dart`

13 small Freezed models in one file. Sample shape (full file in the implementation):

```dart
@freezed
class JobIdPayload with _$JobIdPayload {
  const factory JobIdPayload({
    @JsonKey(name: 'job_id') required int jobId,
  }) = _JobIdPayload;
  factory JobIdPayload.fromJson(Map<String, dynamic> json) =>
      _$JobIdPayloadFromJson(json);
}

@freezed
class TechEnRoutePayload with _$TechEnRoutePayload {
  const factory TechEnRoutePayload({
    @JsonKey(name: 'job_id') required int jobId,
    @JsonKey(name: 'eta_minutes') int? etaMinutes,
  }) = _TechEnRoutePayload;
  factory TechEnRoutePayload.fromJson(Map<String, dynamic> json) =>
      _$TechEnRoutePayloadFromJson(json);
}

@freezed
class QuoteGeneratedPayload with _$QuoteGeneratedPayload {
  const factory QuoteGeneratedPayload({
    @JsonKey(name: 'job_id') required int jobId,
    @JsonKey(name: 'quote_id') required int quoteId,
    @JsonKey(name: 'revision_number') required int revisionNumber,
    @JsonKey(name: 'total_amount') required String totalAmount,  // string-decimal from wire
  }) = _QuoteGeneratedPayload;
  factory QuoteGeneratedPayload.fromJson(Map<String, dynamic> json) =>
      _$QuoteGeneratedPayloadFromJson(json);
}

// ... and 10 more for: tech_arrived, quote_revision_requested, quote_approved,
// quote_declined, payment_received, job_completed, booking_cancelled,
// booking_no_show, booking_rescheduled, dispute_opened, dispute_resolved.
```

Most events only need `job_id` for routing — they reuse `JobIdPayload`. Only events with extra fields used by feature code (`booking_rescheduled` needs `child_booking_id`, `quote_generated` needs `quote_id`) get bespoke shapes.

#### `data/mappers/booking_event_payload_mapper.dart`

```dart
class BookingEventPayloadMapper {
  static int? extractJobId(SystemEventEntity event) {
    final jobId = event.payload['job_id'];
    return jobId is int ? jobId : null;
  }

  static int? extractChildBookingId(SystemEventEntity event) {
    if (event.eventType != SystemEventType.bookingRescheduled) return null;
    final childId = event.payload['child_booking_id'];
    return childId is int ? childId : null;
  }

  // No-frills for refresh-only events. Per CLAUDE.md, payload models live
  // here so feature owns the contract. The "just job_id" shape is shared.
}
```

### §4.7 Realtime: enum extensions + urgency + criticality + router updates

#### `core/realtime/domain/entities/system_event_type.dart` (modified)

```dart
enum SystemEventType {
  // ... existing 13 cases ...
  
  // Booking orchestrator v1
  quoteRevisionRequested,
  quoteDeclined,
  bookingCancelled,
  bookingNoShow,
  bookingRescheduled,
  
  unknown;

  static const Map<String, SystemEventType> _lookup = {
    // ... existing 13 entries ...
    'quote_revision_requested': SystemEventType.quoteRevisionRequested,
    'quote_declined': SystemEventType.quoteDeclined,
    'booking_cancelled': SystemEventType.bookingCancelled,
    'booking_no_show': SystemEventType.bookingNoShow,
    'booking_rescheduled': SystemEventType.bookingRescheduled,
  };
  // ... fromRawType implementation ...
}
```

#### `core/realtime/domain/entities/event_urgency.dart` (modified)

```dart
static const Map<SystemEventType, EventUrgency> _urgencyMap = {
  // ... existing ...
  SystemEventType.quoteRevisionRequested: EventUrgency.lowUrgency,
  SystemEventType.quoteDeclined: EventUrgency.lowUrgency,
  SystemEventType.bookingCancelled: EventUrgency.lowUrgency,
  SystemEventType.bookingNoShow: EventUrgency.lowUrgency,
  SystemEventType.bookingRescheduled: EventUrgency.lowUrgency,
};
```

#### `core/realtime/domain/entities/event_criticality.dart` (modified)

None of the 5 new events are critical (per backend §15). No changes to `criticalTypes` set.

#### `core/realtime/presentation/router/event_urgency_router.dart` (modified)

Add to `_lowUrgencyTapRoutes`:

```dart
SystemEventType.quoteRevisionRequested: '/booking/:job_id',
SystemEventType.quoteDeclined: '/booking/:job_id',
SystemEventType.bookingCancelled: '/booking/:job_id',
SystemEventType.bookingNoShow: '/booking/:job_id',
SystemEventType.bookingRescheduled: '/booking/:job_id',  // tech tap → goes to ORIGINAL booking; rescheduledNotifier
                                                          //  rewrites to child booking via separate handling
```

Add to `_lowUrgencyTapPayloadKeys`:

```dart
SystemEventType.quoteRevisionRequested: 'job_id',
SystemEventType.quoteDeclined: 'job_id',
SystemEventType.bookingCancelled: 'job_id',
SystemEventType.bookingNoShow: 'job_id',
SystemEventType.bookingRescheduled: 'job_id',
```

Add to `_navGuardPayloadKeys` so the router skips push when already on the orchestrator screen for the matching jobId:

```dart
SystemEventType.quoteRevisionRequested: 'job_id',
SystemEventType.quoteDeclined: 'job_id',
// (already-existing types like job_accepted, booking_rejected stay listed)
SystemEventType.bookingCancelled: 'job_id',
SystemEventType.bookingNoShow: 'job_id',
// bookingRescheduled NOT in navGuard — even if user is on the original booking,
// we want to redirect them to the child. The bookingRescheduledNotifier handles this.
```

Extend `_bannerIcons`, `_bannerTitles`, and `_bannerBody` with copy for the new events.

The orchestrator screen is **not** in `_listRouteEvents` — it's a detail route, one entity per route via `:job_id`.

Also extend `_highUrgencyRoutes` to include `quote_generated` and `quote_approved` and `payment_received` and `job_completed` if not already (they were declared in the enum but never wired). Per backend §15:
- `quote_generated` is critical — high urgency, route `/booking/:job_id`.
- `quote_approved` is critical — high urgency, route `/booking/:job_id`.
- `job_completed` is critical — high urgency, route `/booking/:job_id`.

If those are already in `_highUrgencyRoutes` from a prior session, no change needed. Verify and update accordingly.

### §4.8 Presentation: `bookingDetailProvider`

#### `presentation/providers/booking_detail_provider.dart`

```dart
@riverpod
class BookingDetailNotifier extends _$BookingDetailNotifier {
  @override
  Future<BookingDetail> build(int jobId) async {
    final repo = ref.read(bookingDetailRepositoryProvider);
    return repo.getBookingDetail(jobId);
  }

  /// Refresh the detail (called by event notifiers on relevant event arrival).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(bookingDetailRepositoryProvider);
      return repo.getBookingDetail(jobId);
    });
  }
}
```

(Note: the `family<int>` parameter `jobId` is generated by `@riverpod`. The `state` field provides the current async value.)

### §4.9 Presentation: per-event notifiers

#### `presentation/providers/booking_orchestrator_events_notifier.dart`

```dart
@Riverpod(keepAlive: false)
class BookingOrchestratorEventsNotifier extends _$BookingOrchestratorEventsNotifier {
  static const _refreshTriggerEvents = <SystemEventType>{
    SystemEventType.techEnRoute,
    SystemEventType.techArrived,
    SystemEventType.quoteGenerated,
    SystemEventType.quoteRevisionRequested,
    SystemEventType.quoteApproved,
    SystemEventType.quoteDeclined,
    SystemEventType.paymentReceived,
    SystemEventType.jobCompleted,
    SystemEventType.bookingCancelled,
    SystemEventType.bookingNoShow,
    SystemEventType.disputeOpened,
    SystemEventType.disputeResolved,
    // bookingRescheduled handled by separate notifier (has nav side effect)
    // jobAccepted / bookingRejected NOT here — those affect bookings list,
    //   not orchestrator screen (orchestrator screen is post-CONFIRMED).
  };

  @override
  void build(int jobId) {
    ref.listen(systemEventProvider, (prev, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (!_refreshTriggerEvents.contains(event.eventType)) return;

      final eventJobId = BookingEventPayloadMapper.extractJobId(event);
      if (eventJobId != jobId) return;

      // Audit CSC-02: use ref.invalidate for event-driven refetches.
      // notifier.refresh() is reserved for user-initiated reloads (Retry button).
      ref.invalidate(bookingDetailNotifierProvider(jobId));
    });
  }
}
```

#### `presentation/providers/booking_rescheduled_notifier.dart`

```dart
@Riverpod(keepAlive: false)
class BookingRescheduledNotifier extends _$BookingRescheduledNotifier {
  @override
  void build(int jobId) {
    ref.listen(systemEventProvider, (prev, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (event.eventType != SystemEventType.bookingRescheduled) return;

      final eventJobId = BookingEventPayloadMapper.extractJobId(event);
      if (eventJobId != jobId) return;

      final childId = BookingEventPayloadMapper.extractChildBookingId(event);
      if (childId == null) return;

      // Replace current route with the child booking's orchestrator screen.
      // Use the navigator key from app_lifecycle_orchestrator (existing pattern).
      final navigator = ref.read(navigatorKeyProvider);
      navigator.currentState?.pushReplacementNamed('/booking/$childId');
    });
  }
}
```

### §4.10 Presentation: `BookingOrchestratorScreen` + slots

#### `presentation/screens/booking_orchestrator_screen.dart`

```dart
class BookingOrchestratorScreen extends ConsumerStatefulWidget {
  final int jobId;
  const BookingOrchestratorScreen({super.key, required this.jobId});

  @override
  ConsumerState<BookingOrchestratorScreen> createState() =>
      _BookingOrchestratorScreenState();
}

class _BookingOrchestratorScreenState
    extends ConsumerState<BookingOrchestratorScreen> {
  @override
  void initState() {
    super.initState();
    // Wake up event notifiers for this booking; they'll auto-refresh on relevant events.
    ref.read(bookingOrchestratorEventsNotifierProvider(widget.jobId));
    ref.read(bookingRescheduledNotifierProvider(widget.jobId));
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(bookingDetailNotifierProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(failure: e, onRetry: () =>
            ref.read(bookingDetailNotifierProvider(widget.jobId).notifier).refresh()),
        data: (booking) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeaderSlot(booking: booking),
              TimelineSlot(booking: booking),
              Expanded(child: BodySlot(booking: booking)),
              SecondaryActionsSlot(booking: booking),
              PrimaryActionSlot(booking: booking),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final Object failure;
  final VoidCallback onRetry;
  const _ErrorBody({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (failure) {
      BookingDetailNotFound() => ('Not found', 'This booking does not exist.'),
      BookingDetailNotParticipant() => ('Not allowed', 'You are not a participant on this booking.'),
      BookingDetailOfflineNoCache() => ('Offline', 'No connection. Try again when online.'),
      BookingDetailNetworkFailure() => ('Network error', 'Could not reach server.'),
      BookingDetailServerFailure() => ('Server error', 'Try again in a moment.'),
      _ => ('Error', 'Something went wrong.'),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
```

#### `presentation/widgets/slots/header_slot.dart`

```dart
class HeaderSlot extends ConsumerWidget {
  final BookingDetail booking;
  const HeaderSlot({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = booking.ui;
    final tone = ui.tone;
    final counterpartyName = booking.viewerRole == BookingOrchestratorRole.customer
        ? booking.technician.displayName
        : booking.customer.fullName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _toneColor(context, tone).withOpacity(0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ui.statusLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(counterpartyName, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Color _toneColor(BuildContext c, BookingUiTone tone) => switch (tone) {
    BookingUiTone.positive => Colors.green,
    BookingUiTone.warning => Colors.orange,
    BookingUiTone.negative => Colors.red,
    BookingUiTone.info => Colors.blue,
    _ => Colors.grey,
  };
}
```

#### `presentation/widgets/slots/timeline_slot.dart`

Compact horizontal row of dots/dashes representing phase progression. Each dot is filled if its corresponding timestamp is non-null; current phase pulses. Visual sketch:

```
●——●——●——○——○
Acc  ER   Arr  Insp Quote
```

Implementation: `Row` of small `Container`s with horizontal `_PhaseDot` widgets. ~80 lines.

#### `presentation/widgets/slots/body_slot.dart`

```dart
class BodySlot extends ConsumerWidget {
  final BookingDetail booking;
  const BodySlot({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (booking.status) {
      BookingStatus.awaiting => AwaitingBodyStub(booking: booking),
      BookingStatus.confirmed => ConfirmedBodyStub(booking: booking),
      BookingStatus.enRoute => EnRouteBodyStub(booking: booking),
      BookingStatus.arrived => ArrivedBodyStub(booking: booking),
      BookingStatus.inspecting => InspectingBodyStub(booking: booking),
      BookingStatus.quoted => QuotedBodyStub(booking: booking),
      BookingStatus.inProgress => InProgressBodyStub(booking: booking),
      BookingStatus.completed => CompletedBodyStub(booking: booking),
      BookingStatus.completedInspectionOnly => CompletedInspectionOnlyBodyStub(booking: booking),
      BookingStatus.cancelled => CancelledBodyStub(booking: booking),
      BookingStatus.rejected => RejectedBodyStub(booking: booking),
      BookingStatus.noShow => NoShowBodyStub(booking: booking),
      BookingStatus.disputed => DisputedBodyStub(booking: booking),
      BookingStatus.pending || BookingStatus.unknown => UnknownBodyStub(booking: booking),
    };
  }
}
```

This is the single status switch in the entire frontend. 14 cases, exhaustive. Sealed-style switch via Dart 3 patterns; compiler enforces exhaustiveness.

#### `presentation/widgets/slots/primary_action_slot.dart`

```dart
class PrimaryActionSlot extends ConsumerWidget {
  final BookingDetail booking;
  const PrimaryActionSlot({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = booking.ui.primaryAction;
    if (action == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: BookingOrchestratorActionButton(
        action: action,
        bookingId: booking.id,
        isPrimary: true,
      ),
    );
  }
}
```

#### `presentation/widgets/slots/secondary_actions_slot.dart`

Same shape, iterates `ui.secondaryActions` and renders text-buttons.

#### `presentation/widgets/booking_orchestrator_action_button.dart`

```dart
class BookingOrchestratorActionButton extends ConsumerStatefulWidget {
  final BookingUiAction action;
  final int bookingId;
  final bool isPrimary;

  const BookingOrchestratorActionButton({
    super.key,
    required this.action,
    required this.bookingId,
    this.isPrimary = false,
  });

  @override
  ConsumerState<BookingOrchestratorActionButton> createState() =>
      _BookingOrchestratorActionButtonState();
}

class _BookingOrchestratorActionButtonState
    extends ConsumerState<BookingOrchestratorActionButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    if (widget.isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _busy ? null : _execute,
          child: _busy ? const _Spinner() : Text(action.label),
        ),
      );
    }
    return TextButton(
      onPressed: _busy ? null : _execute,
      style: action.style == BookingUiActionStyle.destructive
          ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)
          : null,
      child: Text(action.label),
    );
  }

  Future<void> _execute() async {
    setState(() => _busy = true);
    try {
      await ref.read(bookingActionExecutorProvider).execute(widget.action);
      // Refresh booking detail after a successful action.
      await ref.read(bookingDetailNotifierProvider(widget.bookingId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorText(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(Object e) {
    if (e is HttpFailure) {
      return e.message;
    }
    return 'Could not complete action.';
  }
}
```

#### `presentation/providers/booking_action_executor.dart`

**Audit P0-03**: uses `http` per §24. **Audit coupling/cohesion note**: this class does ONE thing — HTTP-dispatch a server-emitted `BookingUiAction`. NAVIGATE and MODAL methods are dispatched in the **action button widget** (`BookingOrchestratorActionButton`), not here. Sessions 5 + 6 extend the button's `_execute` switch to handle those methods; the executor stays pure-HTTP.

```dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/common/errors/http_failure.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/booking_ui_block.dart';

part 'booking_action_executor.g.dart';

class BookingActionExecutor {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  BookingActionExecutor(this._client, this._secureStorage);

  /// Sends an HTTP request to the server-emitted endpoint string.
  /// Method is the verbatim string from `action.method` (POST/GET/PATCH/DELETE).
  /// Throws [HttpFailure] on non-2xx; SocketException bubbles to the caller.
  Future<void> execute(BookingUiAction action) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final uri = Uri.parse('${AppConstants.baseUrl}${action.endpoint}');
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Token $token',
      'Accept': 'application/json',
    };
    final method = action.method.toUpperCase();
    final response = await switch (method) {
      'GET'    => _client.get(uri, headers: headers),
      'POST'   => _client.post(uri, headers: headers),
      'PATCH'  => _client.patch(uri, headers: headers),
      'DELETE' => _client.delete(uri, headers: headers),
      'PUT'    => _client.put(uri, headers: headers),
      _ => throw StateError('Unsupported HTTP method: ${action.method}'),
    };
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Map<String, dynamic>? envelope;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) envelope = decoded;
      } catch (_) {}
      throw HttpFailure(
        statusCode: response.statusCode,
        code: envelope?['code'] as String? ?? 'unknown',
        message: envelope?['message'] as String? ?? 'Action failed (${response.statusCode}).',
        errors: (envelope?['errors'] as Map<String, dynamic>?) ?? const {},
      );
    }
  }
}

@Riverpod(keepAlive: true)
BookingActionExecutor bookingActionExecutor(Ref ref) => BookingActionExecutor(
  ref.read(eventHttpClientProvider),       // existing singleton
  ref.read(orchestratorSecureStorageProvider),  // audit C2-P1-06: per-feature provider
);
```

Note: this executor handles the SIMPLE actions (no body — start_inspection, en_route, arrived, customer_cancel, etc.). Actions that need a body (submit_quote, confirm_cash_received, decline_quote with reason, etc.) get specialized handlers in sessions 5+. The `ui.primary_action` for those statuses links to a screen-push, not a direct POST. Stub bodies in this session show that distinction.

### §4.11 Presentation: stub body widgets per status

Single file `presentation/widgets/stub_bodies/all_status_stubs.dart`. Each is a small widget that:
1. Renders the `ui.body_text` from the server.
2. Renders a placeholder for the specialized content (map, quote builder, etc.) that sessions 4–6 will replace.
3. Is fully usable for happy-path demo from this session.

Sample stubs:

```dart
class AwaitingBodyStub extends StatelessWidget {
  final BookingDetail booking;
  const AwaitingBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.schedule, size: 64),
          const SizedBox(height: 16),
          Text(booking.ui.bodyText, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class EnRouteBodyStub extends StatelessWidget {
  final BookingDetail booking;
  const EnRouteBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    // Session 4 replaces this with the live-tracking map.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('[Map placeholder — session 4]'),
          ),
          const SizedBox(height: 16),
          Text(booking.ui.bodyText, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class QuotedBodyStub extends StatelessWidget {
  final BookingDetail booking;
  const QuotedBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final quote = booking.activeQuote;
    if (quote == null) {
      return _StubCard(text: booking.ui.bodyText);
    }
    // Session 5 replaces this with the rich approval sheet.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quote rev #${quote.revisionNumber}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...quote.lineItems.map((li) => _LineItemRow(item: li)),
                  const Divider(),
                  Text('Total: Rs. ${quote.totalAmount}',
                      style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(booking.ui.bodyText),
        ],
      ),
    );
  }
}

// ... 11 more stubs: ConfirmedBodyStub, ArrivedBodyStub, InspectingBodyStub,
// InProgressBodyStub, CompletedBodyStub, CompletedInspectionOnlyBodyStub,
// CancelledBodyStub, RejectedBodyStub, NoShowBodyStub, DisputedBodyStub, UnknownBodyStub.
// Each ~30 lines. All read from `booking.ui.bodyText` for the prose.

// Audit P1-11: UnknownBodyStub logs a warning when status == pending so legacy
// rows surface during QA (rather than silently rendering generic "unknown" UI).
class UnknownBodyStub extends StatelessWidget {
  final BookingDetail booking;
  const UnknownBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    if (booking.status == BookingStatus.pending) {
      // Legacy pre-orchestrator-era booking. Should not happen in v1 but logs
      // help us spot rollout-window regressions.
      developer.log(
        'UnknownBodyStub rendering legacy PENDING booking ${booking.id}',
        name: 'orchestrator',
        level: 900,  // WARNING
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline, size: 64),
          const SizedBox(height: 16),
          Text(booking.ui.bodyText.isEmpty
              ? 'Status not recognized.'
              : booking.ui.bodyText,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

Each stub is intentionally minimal — about half a page each. Total ~400 lines for the file.

### §4.12 Routing: `GoRoute` registration

#### `core/routing/app_router.dart` (modified)

Add to the existing routes list:

```dart
GoRoute(
  path: '/booking/:job_id',
  name: 'booking_orchestrator',
  builder: (context, state) {
    final jobId = int.parse(state.pathParameters['job_id']!);
    return BookingOrchestratorScreen(jobId: jobId);
  },
),
```

Also extend `EventUrgencyRouter` references in §4.7 — those routes resolve here.

### §4.13 Bookings list patch mapper extension

#### `frontend/lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart` (modified)

Existing mapper handles `job_accepted` and `booking_rejected`. Extend with branches for the 5 new event types. Each event flips the booking's `status` field on the list item to the corresponding `BookingStatus` enum value, and re-resolves the badge text + tone via the existing UI resolver mirror.

```dart
// New methods alongside existing applyJobAccepted / applyBookingRejected:

CustomerBooking applyBookingCancelled(CustomerBooking item, SystemEventEntity event) {
  return item.copyWith(
    status: BookingStatus.cancelled,
    ui: _resolveUiForCancelled(item, event.payload),
  );
}

CustomerBooking applyBookingNoShow(CustomerBooking item, SystemEventEntity event) {
  return item.copyWith(
    status: BookingStatus.noShow,
    ui: _resolveUiForNoShow(item, event.payload),
  );
}

CustomerBooking applyQuoteDeclined(CustomerBooking item, SystemEventEntity event) {
  return item.copyWith(
    status: BookingStatus.completedInspectionOnly,
    ui: _resolveUiForCompletedInspectionOnly(item, event.payload),
  );
}

CustomerBooking applyJobCompleted(CustomerBooking item, SystemEventEntity event) {
  return item.copyWith(
    status: BookingStatus.completed,
    ui: _resolveUiForCompleted(item, event.payload),
  );
}

CustomerBooking applyBookingRescheduled(CustomerBooking item, SystemEventEntity event) {
  // Original goes to cancelled; the child appears as a separate item via list refresh.
  return item.copyWith(
    status: BookingStatus.cancelled,
    ui: _resolveUiForCancelledRescheduled(item, event.payload),
  );
}
```

The `_resolveUiForXxx` helpers mirror the backend's UI resolver verbatim (per CLAUDE.md dumb-UI principle). Check the existing pattern for `_resolveUiForJobAccepted` and follow it.

In `customer_bookings_list_notifier.dart`, extend the event-type filter to recognize the 5 new types:

```dart
void _onSystemEvent(SystemEventEntity event) {
  final mapper = ref.read(bookingEventPatchMapperProvider);
  final patcher = switch (event.eventType) {
    SystemEventType.jobAccepted => mapper.applyJobAccepted,
    SystemEventType.bookingRejected => mapper.applyBookingRejected,
    SystemEventType.bookingCancelled => mapper.applyBookingCancelled,
    SystemEventType.bookingNoShow => mapper.applyBookingNoShow,
    SystemEventType.quoteDeclined => mapper.applyQuoteDeclined,
    SystemEventType.jobCompleted => mapper.applyJobCompleted,
    SystemEventType.bookingRescheduled => mapper.applyBookingRescheduled,
    _ => null,
  };
  if (patcher == null) return;
  // ... existing patch-and-emit logic ...
}
```

### §4.14 `ORCHESTRATOR_FEATURE.md`

Per CLAUDE.md frontend documentation rule — every feature gets a `<FEATURE>_FEATURE.md`. Cover:

- Domain entities + fields
- Sealed failure hierarchy
- Repository interface contract
- Use cases
- Data models + mappers
- Data sources
- Repository impl flow (offline-first)
- Error propagation pipeline
- DI wiring
- Presentation layer (provider tree, screen + slots, stub widgets)
- Realtime integration (event notifier + payload mapper)
- Routing (`GoRoute` registration)

Mark sessions 4–6 work as `⏳ pending` — the body slots for tracking, quote, edges.

### §4.15 Tests — coverage matrix

Each test file mirrors a source file. Coverage by layer:

**Data layer**:
- `booking_detail_repository_impl_test.dart`: 200 → entity returned + cache write; 404 → BookingDetailNotFound; 403 not_a_participant → BookingDetailNotParticipant; 5xx → ServerFailure; SocketException + cache present → cached entity returned; SocketException + no cache → OfflineNoCache.
- `booking_detail_mapper_test.dart`: full payload from session 2 §4.6 example mapped correctly; viewerRole derives correctly for customer vs technician.
- `booking_event_payload_mapper_test.dart`: `extractJobId` works for every event type with payload; null for malformed payload; `extractChildBookingId` only for bookingRescheduled.

**Presentation layer (use ProviderContainer per CLAUDE.md, NOT widget mounting)**:
- `booking_detail_provider_test.dart`: mock repository, override provider, fetch in container, assert AsyncData with correct entity; refresh transitions state through loading → data correctly.
- `booking_orchestrator_events_notifier_test.dart`: emit each of the 12 trigger events with matching jobId → assert refresh called; emit with mismatched jobId → assert no refresh; emit irrelevant event → no refresh.
- `booking_rescheduled_notifier_test.dart`: emit bookingRescheduled with matching jobId + child_booking_id → assert navigator.pushReplacementNamed called with correct path.

**Widget layer (mocktail + injected hardcoded BookingDetail)**:
- `booking_orchestrator_screen_test.dart`: render with hardcoded BookingDetail in each of 13 statuses; assert correct stub body widget renders, action button labels match `ui.primary_action.label`, secondary actions render correctly.
- `body_slot_test.dart`: each of 14 status enum values produces correct stub widget.
- `booking_orchestrator_action_button_test.dart`: tap → executor called with action's endpoint+method; HttpFailure → snackbar with correct message; success → bookingDetailProvider refresh called.

**Existing test extension**:
- `booking_event_patch_mapper_test.dart`: add coverage for the 5 new event types (matching existing test patterns for jobAccepted/bookingRejected).

---

## §5 Gotchas

1. **Realtime events for orchestrator-relevant events that arrive while NOT on the orchestrator screen** are routed by `EventUrgencyRouter` per its existing rules. High-urgency events (`quote_generated`, `quote_approved`, `job_completed`) push the orchestrator screen full-screen; low-urgency events surface a tap-banner. The orchestrator-events notifier only fires when the screen is mounted (because of `keepAlive: false` and the screen reading the provider).
2. **The orchestrator screen's notifiers don't need `realtimeBootHooksProvider` registration** — they're scoped to the screen lifetime, not boot-time. Boot-time registration is only for queue notifiers that must wake before WS frames arrive (per CLAUDE.md "Wake-up at app boot is load-bearing"). Detail-route screens like this one don't have queues — they have a single hydration provider.
3. **`_navGuardPayloadKeys` matters.** When a `quote_generated` event arrives while the user is already on `/booking/123` and the event's `job_id == 123`, the router must NOT push another route. Add the entries per §4.7. Test by walking the lifecycle and asserting no double-push.
4. **`bookingRescheduledNotifier` does pushReplacementNamed, not push.** The user is currently on the original (now CANCELLED) booking; we replace with the child booking's screen so they don't see a stale CANCELLED state. The router does NOT add `bookingRescheduled` to `_navGuardPayloadKeys` for this reason — we WANT the nav.
5. **`BookingDetail.viewerRole` is derived in the mapper, not the server**. The server's response shape doesn't include `viewer_role` — it returns the full payload regardless. Mapper compares `current_user_id` (from auth state) against `customer.id` and `technician.user_id` (the latter is in the technician sub-object).
6. **Server's `technician` payload must include `user_id`** (the User.id, not TechnicianProfile.id) for the mapper to work. Check session 2 §4.6's serializer — if it doesn't already, this session needs to amend the serializer to include `user_id`. (Verify before implementing.)
7. **Action button `_execute` may race against an event-driven refresh.** If the user taps "En route" while `tech_en_route` arrives from another path (e.g., auto-transition fired), both will try to refresh `bookingDetailProvider`. AsyncValue.guard handles this — last write wins, no error. But UI may flicker briefly. Acceptable for v1.
8. **`HttpFailure.fromResponse(...)`** assumes the standard error envelope from CLAUDE.md. If a server response deviates (e.g., a 500 with HTML body), the mapper falls through to a generic message. Tests should cover this.
9. **`SharedPreferences` cache key collision** — sprint v1 uses `orchestrator_booking_detail_v1_<id>`. If the response shape changes in v2, bump the prefix to `_v2_` to avoid stale-cache parsing crashes.
10. **`build_runner` must run** after adding Freezed + json_serializable + Riverpod annotations. Forgetting produces missing `_$BookingDetail` errors at compile time. Pre-flight runs `dart run build_runner build --delete-conflicting-outputs`. Re-run after every model edit.
11. **`Quote.totalAmount` and `BookingItem.priceCharged` come from server as string-decimals** (e.g., `"1500.00"`). Mapper converts to `int` (rupees) for typed display. If server precision changes (e.g., paisa precision), the mapper is the single point to update.
12. **Stub body widgets read from `booking.ui.bodyText`** — they don't compose their own copy. This is the dumb-UI rule applied at every level; sessions 4–6 widgets must keep this discipline.
13. **`BodySlot`'s switch is exhaustive** thanks to Dart 3 patterns. Compiler enforces — adding a new BookingStatus value will fail compilation here, signaling that a stub widget is missing. Lean on the compiler.
14. **`BookingDetailNotifier.refresh()` sets state to AsyncValue.loading first**, which triggers a brief loading state in the UI. For optimistic refresh (avoid flash), use `state = await AsyncValue.guard(...)` directly without the loading set. Decision for v1: loading flash is OK; optimistic-refresh polish in session 6.
15. **Existing `BookingStatus` enum extension** affects the bookings list rendering. Verify the list still renders correctly for the new status values — the existing UI resolver in `customer_bookings_selector.py` (server-side) handles rendering; client just reads `ui.badge_text` and `ui.badge_tone`. So as long as server emits valid `ui.*` for the new statuses, the list works.
16. **Boot-time concerns for the orchestrator events notifier**: a user could navigate directly to `/booking/123` from a deep link (e.g., FCM tap). `app_lifecycle_orchestrator.dart::bootAfterAuth` runs first; the screen mounts after; the events notifier wakes when the screen reads the provider. There's no race because realtime events that arrived during boot are already in `EventLog` and re-played via `eventSyncProvider` on connect. Verified in session 2 of prior sprint.
17. **`pushReplacementNamed` in `bookingRescheduledNotifier`** uses GoRouter — confirm the navigator key is the GoRouter's, not the older NavigatorKey. Check `app_lifecycle_orchestrator.dart` for the existing pattern.
18. **Test isolation for `Riverpod`**: each provider test creates a fresh `ProviderContainer` per test. Don't share containers across tests; state leaks otherwise.

---

## §6 Verification

### Static checks

```bash
cd frontend
flutter analyze                                     # no errors, no warnings
dart run build_runner build --delete-conflicting-outputs   # no codegen failures
```

### Unit + widget tests

```bash
flutter test test/features/orchestrator/data/                                # all data-layer tests
flutter test test/features/orchestrator/presentation/                        # all presentation tests
flutter test test/features/customer/bookings/data/mappers/                  # extended patch mapper test
flutter test                                                                  # full suite
```

### Manual smoke (full happy path)

1. Start backend: `cd backend && python manage.py runserver`.
2. Start frontend: `cd frontend && flutter run`.
3. Log in as customer (OTP `123456` per CLAUDE.md DEBUG mode).
4. Create a booking via existing flow.
5. From a separate device or emulator, log in as the assigned technician.
6. Tech accepts via existing incoming-job sheet → on customer device, expect navigation to `/booking/<id>` orchestrator screen showing **Confirmed** status.
7. Tech taps a manual override "Start journey" (or invokes the `/en-route/` endpoint via curl) → customer's screen auto-refreshes to `EnRouteBodyStub`. Verify the map placeholder appears.
8. Tech moves through arrived → INSPECTING → submits a quote.
9. Customer sees `QuotedBodyStub` with the line items and three action buttons (Approve / Decline / Bargain in person).
10. Customer taps Approve → status flips to IN_PROGRESS, body changes to `InProgressBodyStub`.
11. Tech taps "Cash Collected" (the combined endpoint) → both screens flip to `CompletedBodyStub`.

Variations to manually verify:
- Customer cancellations at each phase.
- Tech-cancel.
- No-show buttons (visible only after appropriate time guards).
- Dispute open from the disputed-eligible statuses (sessions 6 will polish, but the form is callable now).
- Reschedule from AWAITING — customer's screen replaces to the child booking's orchestrator.

### Constraint checks

```bash
# Confirm the screen has only ONE switch on status (in BodySlot)
grep -rn "switch (booking.status)" frontend/lib/features/orchestrator/
# Expected: 1 hit (body_slot.dart)

# Confirm no business logic in widgets — they only render
grep -rn "Dio\|http\." frontend/lib/features/orchestrator/presentation/widgets/
# Expected: empty (network calls live in providers / data layer)

# Confirm no BookingDetail mutation in widgets
grep -rn "copyWith" frontend/lib/features/orchestrator/presentation/widgets/
# Expected: empty

# Confirm action buttons read endpoints from server, never construct
grep -rn "/api/bookings/" frontend/lib/features/orchestrator/
# Expected: empty (endpoints come from ui.primary_action.endpoint)
```

### Lifecycle smoke (with realtime)

```bash
# In one terminal, watch backend events being broadcast
cd backend
python manage.py shell
>>> from realtime.models.events import EventLog
>>> EventLog.objects.filter(event_type__startswith='quote_').order_by('-created_at')[:5]
```

While running, walk through the lifecycle on the app and verify each event appears in EventLog and the orchestrator screen refreshes correspondingly.

---

## §7 What this session does NOT fix

- Live tracking widget (real maps) — session 4 replaces `EnRouteBodyStub` and `ArrivedBodyStub`.
- Tech-side foreground GPS broadcast service — session 4.
- Polyline + ETA — session 4.
- Stream-staleness "tech offline" banner — session 4.
- Quote builder UI (chip stack) — session 5 replaces `InspectingBodyStub`.
- Customer quote approval sheet (3-action with bargain) — session 5 replaces `QuotedBodyStub`'s decision UI.
- Cash collection completion screen (single combined button per §14 rule 2) — session 5 replaces `InProgressBodyStub`'s primary action with the rich cash-collection sheet.
- Customer/tech cancel flows with timing-aware copy — session 6 enriches the secondary action button.
- Reschedule modal — session 6.
- No-show buttons (single tap with confirmation modal) — session 6.
- Dispute open form (with photo upload) — session 6.
- SLA countdown polish for AWAITING — session 6.
- Real `JobBooking` integration tests against a live server — sprint meta §16 (deferred).
- Orchestrator screen design system polish (Stitch tokens applied) — planned UI cleanup pass per memory.
- iOS push handling — flag #10 deferred.
- AI chatbot intake — future sprint (form-intake stub via session 6).

---

## §8 Definition of done

Tick every item before pushing.

### Code

- [ ] All files under `frontend/lib/features/orchestrator/` created at the listed paths.
- [ ] `BookingStatus` enum extended with 8 new values; `fromWire` and `wireValue` updated.
- [ ] Domain entities + failures + repository contract + use case shipped.
- [ ] Data models + mappers + datasources + repository impl shipped.
- [ ] All 13 per-event payload models in `booking_event_payloads.dart`.
- [ ] `bookingDetailProvider` + `bookingOrchestratorEventsNotifier` + `bookingRescheduledNotifier` shipped.
- [ ] `BookingOrchestratorScreen` + 5 slot widgets + 13 stub body widgets shipped.
- [ ] `app_router.dart` updated with `/booking/:job_id` route.
- [ ] `core/realtime/` enums extended (system_event_type, event_urgency); router updated with new routes + payload keys + nav guard.
- [ ] `customer_bookings_list_notifier.dart` + `booking_event_patch_mapper.dart` extended for the 5 new event types.
- [ ] `ORCHESTRATOR_FEATURE.md` written.

### Tests

- [ ] `flutter test` green on the full suite.
- [ ] Repository tests cover all failure branches.
- [ ] Mapper tests cover full payload + edge cases (null subService, null address, viewerRole derivation).
- [ ] Per-event payload mapper tests cover all 13 events.
- [ ] `bookingDetailProvider` tests (use ProviderContainer, never mount widgets) cover hydration + refresh.
- [ ] `bookingOrchestratorEventsNotifier` tests cover all 12 trigger events + non-matching jobId.
- [ ] `bookingRescheduledNotifier` tests cover nav side effect.
- [ ] Screen widget tests render every status (13 cases) with hardcoded BookingDetail and assert correct stub body + action buttons.
- [ ] Action button widget tests cover success + error cases.
- [ ] Extended patch mapper tests cover 5 new event types.

### Constraints (per CLAUDE.md)

- [ ] `state = await AsyncValue.guard(...)` everywhere a notifier mutates state asynchronously (no manual try/catch with AsyncLoading/AsyncError).
- [ ] `state.requireValue` used; never `state.value!`.
- [ ] All providers in `presentation/providers/dependency_injection.dart` per feature.
- [ ] Widgets are dumb — no `copyWith` mutations, no http imports, no `/api/bookings/` URL strings constructed in widgets.
- [ ] **No `package:dio` imports anywhere** (audit P0-03; pubspec doesn't declare dio). All data sources use `package:http` per sprint meta §24.
- [ ] Single switch on `BookingStatus` in `BodySlot` (grep-confirmed); compiler enforces exhaustiveness via Dart 3 patterns.
- [ ] Per-event feature wiring follows CLAUDE.md template (payload model in feature, mapper in feature, notifier with `ref.listen(systemEventProvider, ...)`, etc.).
- [ ] No `mockito` in tests — `mocktail` only.
- [ ] `flutter analyze` clean — confirms the http migration compiles end-to-end.

### Documentation

- [ ] `ORCHESTRATOR_FEATURE.md` includes: domain entities, sealed failures, repository interface, use cases, data models, data sources, repository impl flow (offline-first), error pipeline, DI wiring, presentation layer, realtime integration, routing. Sessions 4–6 work marked `⏳ pending`.

### flag.md

- [ ] No new flags from this session (per sprint meta §20 — session 3 row is "—" / "—").
- [ ] Existing open flags untouched.

### Git

- [ ] Single commit (or small chain): `feat(orchestrator): frontend skeleton + per-event notifiers + stub bodies (sprint v1, session 3)`.
- [ ] `flutter analyze` clean.
- [ ] `dart format` applied.
- [ ] No `--no-verify`; pre-commit hooks pass.
- [ ] `git status` clean after commit.

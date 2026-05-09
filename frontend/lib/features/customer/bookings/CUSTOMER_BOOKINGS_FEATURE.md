# Customer Bookings Feature

The customer-side **My Bookings** tab. Powers the scrollable list of upcoming + past bookings with realtime status patches.

**Backend contract**: `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` — list (`GET /api/bookings/`) and counts (`GET /api/bookings/counts/`).

**Detail screen** lives in `lib/features/orchestrator/` (audience-shared customer + technician). Card taps navigate to `/booking/:job_id` and mount `BookingOrchestratorScreen`. The pre-orchestrator placeholder route `/customer/booking/:job_id` is gone (flag #26 closed 2026-05-09).

---

## Sprint Status

| Layer | Status |
|---|---|
| Domain (entities, failures, repository interface, use cases) | ✅ Shipped |
| Data (models, mappers, data sources, repository impl) | ✅ Shipped |
| Presentation / providers (DI, list notifier, counts notifier, segment notifier, state) | ✅ Shipped |
| Presentation / screens (list screen widget, segmented control, card widget, empty/error/skeleton states) | ✅ Shipped |
| Bottom-nav tab onTap wiring (`HomeScreen` converted to `IndexedStack` shell) | ✅ Shipped |
| GoRoute `/customer/bookings` registration | ✅ Shipped |
| Tests | ⏳ pending — proposed after impl approval per CLAUDE.md |

---

## Domain Layer

### Entities

| File | Purpose |
|---|---|
| `domain/entities/customer_booking.dart` | Card-shaped booking summary. Includes nested `BookingService`, `BookingTechnician`, `BookingPrice`, `BookingUi` freezed types. |
| `domain/entities/booking_status.dart` | Enum: `awaiting`, `confirmed`, `completed`, `cancelled`, `rejected`, `pending` (legacy), `unknown` (forward-compat). Wire mapping via `fromWire` / `wireValue`. |
| `domain/entities/booking_segment.dart` | Enum: `upcoming`, `past`. Wire shortcut sent on `?segment=`. |
| `domain/entities/booking_ui_tone.dart` | Enum: `positive`, `warning`, `negative`, `neutral`, `info`, `unknown`. The card switches on this for design tokens — never on raw status. |
| `domain/entities/bookings_page.dart` | One page envelope: `items`, `nextCursor`, `hasMore`, `serverTime`, `isStaleCache`, `cachedAt`. |
| `domain/entities/bookings_counts.dart` | Aggregate counts for the segmented control: `upcoming`, `past`, `serverTime`. |

### Sealed Failure Hierarchy

`domain/failures/customer_bookings_failure.dart`

```
CustomerBookingsFailure
  ├── CustomerBookingsNetworkFailure          (offline + cache hit; rare — repo serves stale silently)
  ├── CustomerBookingsOfflineNoCache          (offline + no cache; centered offline empty state)
  ├── CustomerBookingsServerFailure           (HTTP 5xx; centered retry state)
  ├── CustomerBookingsValidationFailure       (HTTP 400; carries wire `code` + `errors`)
  └── UnknownCustomerBookingsFailure          (catch-all)
```

### Repository Interface

`domain/repositories/customer_bookings_repository.dart`

```dart
abstract class ICustomerBookingsRepository {
  Future<BookingsPage> getBookings({
    required BookingSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  });

  Future<BookingsCounts> getCounts();
}
```

Throws documented per method — see file.

### Use Cases

| File | Wraps |
|---|---|
| `domain/use_cases/get_customer_bookings_use_case.dart` | `getBookings(...)` |
| `domain/use_cases/get_bookings_counts_use_case.dart` | `getCounts()` |

Single-method passthroughs for layering symmetry. The list/counts notifiers consume the use cases (not the repository directly), matching CLAUDE.md's Clean Architecture rule.

---

## Data Layer

### Models (Wire shape — freezed + json_serializable)

| File | Purpose |
|---|---|
| `data/models/customer_booking_model.dart` | List-item wire shape. Includes nested `BookingServiceModel`, `BookingTechnicianModel`, `BookingPriceModel`, `BookingUiModel`. |
| `data/models/bookings_list_response_model.dart` | Page envelope: `items`, `next_cursor`, `has_more`, `server_time`. |
| `data/models/bookings_counts_model.dart` | Counts envelope: `upcoming`, `past`, `server_time`. |

### Mappers

| File | Purpose |
|---|---|
| `data/mappers/customer_booking_mapper.dart` | Wire model → domain entity. Translates wire strings to typed enums + ISO strings to `DateTime`. Forgiving on unknown enum strings (forward-compat). |
| `data/mappers/booking_event_patch_mapper.dart` | **Realtime list-patch mapper** — Option (ii). Mirrors the server's status → ui table for `job_accepted` / `booking_rejected` transitions. Drift authority: `CUSTOMER_BOOKINGS_API.md` §1.7. |

### Data Sources

| File | Purpose |
|---|---|
| `data/data_sources/customer_bookings_remote_data_source.dart` | `GET /api/bookings/` + `GET /api/bookings/counts/`. Auth-token header, `HttpFailure` on non-2xx. |
| `data/data_sources/customer_bookings_local_data_source.dart` | SharedPreferences-backed cache for the **first page only**, **per segment**. Versioned key (`_v1`). Stores raw JSON envelope + `cached_at` timestamp. Pagination is not cached. |

### Repository Implementation

`data/repositories/customer_bookings_repository_impl.dart`

**Network-first with cache fallback** (per CLAUDE.md):

```
getBookings(segment, cursor, ...):
  try:
    response = remote.getBookings(...)
    if first page:
      best-effort: local.cacheFirstPage(segment, response)
    return mapper.pageFromResponse(response)
  on HttpFailure:
    throw _mapHttpFailure(failure)
  on SocketException:
    if not first page:
      throw OfflineNoCache              (pagination cache is not maintained)
    cached = local.getCachedFirstPage(segment)
    if cached == null:
      throw OfflineNoCache
    return mapper.pageFromResponse(cached.response,
                                    isStaleCache: true,
                                    cachedAt: cached.cachedAt)
```

`getCounts()` is **never** cached — `SocketException` throws `OfflineNoCache` directly. Stale counts on the segmented control would mislead the user.

### Error Propagation Pipeline (4-step, per CLAUDE.md)

```
1. Data Source       — non-2xx → throws HttpFailure
2. Repository        — _mapHttpFailure: code switch → typed sealed CustomerBookingsFailure
                      — SocketException → OfflineNoCache (or stale-cache rescue)
3. Domain            — sealed CustomerBookingsFailure subtypes
4. Presentation      — switch on sealed type → UI affordance (snackbar/banner/empty state)
```

---

## Presentation / Providers

### DI Wiring

`presentation/providers/dependency_injection.dart` — every provider is `@Riverpod(keepAlive: true)`. Chain:

```
HttpClient + SecureStorage
  ↓
RemoteDataSource + LocalDataSource (LocalDS reads sharedPreferencesProvider)
  ↓
RepositoryImpl
  ↓
GetCustomerBookingsUseCase + GetBookingsCountsUseCase
```

`sharedPreferencesProvider` is the existing app-wide override declared in `features/technician/onboarding/presentation/providers/dependency_injection.dart`. The cache scopes to the device, not the user — on logout, `LocalDataSource.clear()` should be called as part of the auth teardown (deferred; current `performTeardown` does not yet do this — minor flag candidate).

### Notifiers

| Notifier | Provider | Purpose |
|---|---|---|
| `SelectedSegment` (`@riverpod`, not keepAlive) | `selectedSegmentProvider` | Holds the active segment. Default `upcoming`. List notifier `ref.watch`es this for tab-switch rebuilds. |
| `CustomerBookingsList` (`@Riverpod(keepAlive: true)`) | `customerBookingsListProvider` | The list. `build()` reads `selectedSegmentProvider`, fetches first page, registers `ref.listen(systemEventProvider, ...)` for `jobAccepted`/`bookingRejected` patches. Methods: `refresh()`, `loadMore()`. State wrapped in `AsyncValue<CustomerBookingsListState>`. |
| `CustomerBookingsCounts` (`@Riverpod(keepAlive: true)`) | `customerBookingsCountsProvider` | Counts notifier. Same `ref.listen` pattern; refetches counts on status-flip events. Methods: `refresh()`. |

### State

`presentation/providers/customer_bookings_list_state.dart` (freezed):

```dart
class CustomerBookingsListState {
  BookingSegment segment;
  List<CustomerBooking> items;
  String? nextCursor;
  bool hasMore;
  bool isLoadingMore;
  bool isStaleCache;
  DateTime? cachedAt;
  DateTime serverTime;
}
```

Per CLAUDE.md: all async mutations use `AsyncValue.guard(...)`; safe access via `state.requireValue` / `state.valueOrNull`, never `state.value!`.

### Screens + Widgets

`presentation/screens/customer_bookings_list_screen.dart` — `ConsumerStatefulWidget`. Reads all three providers, owns a `ScrollController` for `loadMore()` pre-fetch (within 320pt of list end; notifier guards re-entry), runs `Future.wait([listRefresh, countsRefresh])` on pull-to-refresh, and auto-refreshes once on `CustomerBookingsValidationFailure` via `ref.listen`. Implements every §7 state→render branch — no `SizedBox.shrink()` defaults. AppBar shows a back arrow only when `showBackButton: true` (deep-link route entry); the tab-mounted instance has no back arrow.

| File | Purpose |
|---|---|
| `presentation/screens/customer_bookings_list_screen.dart` | Tab destination + deep-link target. |
| `presentation/widgets/booking_card.dart` | Dumb card. Switches on `ui.badgeTone` for tokens, never on raw status. Stateful for realtime pulse + segment-fade-out + Cancelled visual decay. Hero-tags the service icon as `'booking-icon-${id}'`. Tap fires `HapticFeedback.lightImpact()` then `context.push('/booking/${id}')` (orchestrator screen, audience-shared). |
| `presentation/widgets/booking_card_skeleton.dart` | Shimmer placeholder. Outer chrome + region heights + gaps match the real card exactly so there's no relayout flash on data arrival. |
| `presentation/widgets/booking_status_pill.dart` | Tone-tinted capsule. Caller wraps in `AnimatedSwitcher` keyed on text+tone for 250ms morph on realtime patches. |
| `presentation/widgets/booking_tech_avatar.dart` | 48px `CachedNetworkImage` with initials fallback. Handles single-name + all-whitespace gracefully (never a broken-image icon). |
| `presentation/widgets/bookings_segmented_control.dart` | Custom-styled two-segment switcher. Reads `selectedSegmentProvider` + `customerBookingsCountsProvider`. Renders `Upcoming · 1` / `Past · 12` when counts are available; clean omission on loading/error (no `· —` placeholder). |
| `presentation/widgets/bookings_empty_upcoming.dart` | Empty state with "Browse services" CTA → `context.go('/home')`. |
| `presentation/widgets/bookings_empty_past.dart` | Empty state, no CTA. |
| `presentation/widgets/bookings_offline_banner.dart` | Warning-tone strip with `cachedAt` minute-delta + refresh button. Animated in/out by parent via `AnimatedSize`. |
| `presentation/widgets/bookings_error_state.dart` | Three named ctors: `.offline()` / `.server()` / `.unknown()` per §7.6/7.7/7.8. Each has distinct copy. |
| `presentation/utils/booking_tone_palette.dart` | `BookingUiTone` → `(bg, fg, border)` resolver. Reads `AppColors` directly (not the live `ColorScheme`) so the brief's exact §3.1 tokens are used regardless of `MaterialApp.theme`'s seed-based scheme. |
| `presentation/utils/booking_date_formatter.dart` | Smart "Today / Tomorrow / In 30 min" formatter. **Anchored on `state.serverTime`, never `DateTime.now()`** so device-clock skew can't misrepresent imminence. Appends `" · responding within ~15 min"` for AWAITING (static; live countdown deferred per session_4 §15). |

### Theme additions

`core/theme/app_colors.dart` was extended with four tokens the brief's tone palette requires: `tertiaryFixedDim` (`#FFB77D`), `onTertiaryFixed` (`#2F1500`), `onSecondaryContainer` (`#00714C`), `onErrorContainer` (`#93000A`). Adding them locally avoids reshaping the global `ThemeData` mid-sprint (the project's `MaterialApp.theme` still uses `ColorScheme.fromSeed`); the planned end-of-UI design-system cleanup pass can migrate the global theme to explicit M3 tokens at that time.

### Bottom-nav shell

`features/customer/home/presentation/screens/home_screen.dart` was converted to an `IndexedStack` shell driven by `currentCustomerTabProvider` (declared in `features/customer/home/presentation/providers/current_tab_notifier.dart`). Tabs: Home / Bookings / Messages-placeholder / Profile-placeholder. `IndexedStack` keeps every tab mounted, so scroll position and Riverpod state survive switches.

### Realtime Patch Behavior

`build()` of the list notifier subscribes to `systemEventProvider` via `ref.listen`. On every event:

1. Skip housekeeping rebuilds (`latestEvent == null`) and same-id repeats.
2. Switch on `event.eventType`:
   * `jobAccepted` → `BookingEventPatchMapper.applyJobAccepted(item, event)`
   * `bookingRejected` → `BookingEventPatchMapper.applyBookingRejected(item, event)`
3. Match the affected item by `payload.job_id`. Found → patch in place. Not found → silent (booking is in the other segment; will surface on tab switch).

**Boot wakeup** — `customerBookingsListProvider` and `customerBookingsCountsProvider` are appended to `realtimeBootHooksProvider` in `app_lifecycle_orchestrator.dart`. The orchestrator's `bootAfterAuth()` reads each entry before the WS connect cascade, so the listeners are subscribed when the first event arrives.

---

## Backwards-Compat Defaults

Per the codebase's "mapper owns backwards-compat" rule:

| Field | Default behavior |
|---|---|
| `status` unknown wire string | Maps to `BookingStatus.unknown`. Card renders with the "Pending" headline + neutral tone (per server's `_resolve_ui_block` fallback). |
| `badge_tone` unknown wire string | Maps to `BookingUiTone.unknown`. Card renders with a neutral fallback tone. |
| Unparseable ISO timestamp | Logs and falls back to `DateTime.now().toUtc()` — never throws into the queue notifier and discards the entire page. |
| `address_label` null | Card hides the address row (no placeholder). |
| `profile_picture_url` null | Card renders an avatar placeholder (next sprint UI concern). |
| `payload.job_id` missing on event | Patch silently drops; logged. |
| `payload.reason` missing on `bookingRejected` | Defaults to `technician_declined` copy (server policy mirrored). |

---

## Open Items / Tech Debt Candidates

* **Cache eviction on logout** — `LocalDataSource.clear()` is implemented but not yet called from `performTeardown` in the orchestrator. Acceptable for v1 (cache is per-segment + per-device, not per-user identity), but a multi-account device could see the previous user's cached list briefly on the next login. Flag candidate when multi-account becomes a real flow.
* **Pagination cache** — first page only. Pages 2+ throw `OfflineNoCache`. Acceptable trade-off; document this in flag.md if the offline-pagination UX becomes a complaint.
* **Detail endpoint** — `GET /api/bookings/<id>/` is not implemented. The list notifier's "patch by event" path is fully self-sufficient for the two events we own; future events that carry insufficient data on the wire will need either a richer payload or this endpoint.

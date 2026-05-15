# Technician Schedule Feature

Audience-flipped mirror of `features/customer/bookings/`. Same underlying
`JobBooking` rows, same state machine — different audience UI.

**Backend contract:** `backend/technicians/api/SCHEDULED_JOBS_API.md`
**Endpoints:**
- `GET /api/technicians/me/scheduled-jobs/` (paginated list)
- `GET /api/technicians/me/scheduled-jobs/counts/` (badge counts)

---

## 1. Domain layer (`domain/`)

### Entities

- `ScheduledJob` (`entities/scheduled_job.dart`) — the card-shaped row.
  Composed of:
  - `id: int`, `status: BookingStatus`, `addressLabel: String?`,
    `scheduledStart/End/createdAt: DateTime` (UTC)
  - `ScheduledJobService { name, iconName }` — drives the SVG icon at
    `assets/icons/{iconName}.svg`
  - `ScheduledJobCustomer { id, displayName, profilePictureUrl }` —
    counterparty. `profilePictureUrl` is always null in v1
    (CustomerProfile has no avatar yet); the card renders initials.
  - `PayoutBlock { amount, context, uiLabel }` — tech-framed `price`
    equivalent. See §1.6 of the API doc for the two-tier resolution
    (`JobCommission` ledger row → projected `price_amount * 0.80`).
  - `ScheduledJobUi { badgeText, badgeTone, headline }` — server-driven
    dumb-UI block. Widgets switch on `badgeTone` for design tokens; never
    on raw `status` for copy.

- `ScheduledJobsPage` (`entities/scheduled_jobs_page.dart`) — list-response
  envelope. `nextCursor` is opaque (FE never decodes), `serverTime` is
  the assembly anchor for date-label calculations, `isStaleCache` +
  `cachedAt` are local flags set by the repo on cache fallback.

- `ScheduledJobsCounts` (`entities/scheduled_jobs_counts.dart`) — `{upcoming,
  past, serverTime}`. Earnings deliberately not surfaced — Metrics tab
  owns "how much have I earned", Schedule owns "what jobs exist".

- `ScheduledJobSegment` (`entities/scheduled_job_segment.dart`) — enum
  `upcoming | past`. Same wire vocabulary as the customer side.

### Shared with customer feature

- `BookingStatus` (imported from `customer/bookings/domain/entities/`)
  — same `JobBooking.STATUS_*` wire enum on both sides.
- `BookingUiTone` (same path) — `positive | warning | negative | neutral
  | info | unknown`.

A future `flag.md` cleanup post-viva will extract these to
`core/booking/` once a third consumer materializes; for now the
cross-feature import is the right call to avoid duplicate parse tables.

### Failures (`failures/scheduled_jobs_failure.dart`)

Sealed hierarchy — five outcomes, distinct UI mappings:

| Subclass                          | When                          | UI affordance                  |
| --------------------------------- | ----------------------------- | ------------------------------ |
| `ScheduledJobsNetworkFailure`     | SocketException w/ cache hit  | Offline banner + cached page   |
| `ScheduledJobsOfflineNoCache`     | SocketException w/o cache     | Centered offline empty + retry |
| `ScheduledJobsServerFailure`      | HTTP 5xx                      | Centered server error + retry  |
| `ScheduledJobsValidationFailure`  | HTTP 400 (envelope `code`)    | Auto-retry once, then surface  |
| `UnknownScheduledJobsFailure`     | Anything unclassified         | Generic retry                  |

### Repository (`repositories/scheduled_jobs_repository.dart`)

`IScheduledJobsRepository` interface with two methods. Errors documented
in dartdoc per CLAUDE.md error-contract rule.

### Use cases (`use_cases/`)

- `GetScheduledJobsUseCase` — wraps `getScheduledJobs(...)`
- `GetScheduledJobsCountsUseCase` — wraps `getCounts()`

Single-method delegation. Exists for layering symmetry with the rest of
the codebase.

---

## 2. Data layer (`data/`)

### Models

`@freezed` + JSON serialization. Faithful to the wire — no domain types
applied at this layer, so the local cache round-trips through the same
JSON shape the network returns. Files:
- `models/scheduled_job_model.dart`
- `models/scheduled_jobs_list_response_model.dart`
- `models/scheduled_jobs_counts_model.dart`

### Mapper (`mappers/scheduled_job_mapper.dart`)

Wire → domain. The boundary where strings become typed values:
- `status` ("CONFIRMED") → `BookingStatus`
- `badge_tone` ("positive") → `BookingUiTone`
- ISO-8601 → `DateTime`

Forgiving: unknown enums fall to `unknown`, unparseable timestamps log
and fall back to `DateTime.now().toUtc()` (better than throwing the
whole page on a single bad row).

### Data sources

- `data_sources/scheduled_jobs_remote_data_source.dart` — `http` client,
  bearer token from `FlutterSecureStorage` (key `auth_token`, same key
  every other authenticated DS uses). Throws `HttpFailure` parsed from
  the standard `{status, code, message, errors}` envelope.
- `data_sources/scheduled_jobs_local_data_source.dart` —
  `SharedPreferences`-backed cache. Caches **only the first page** per
  segment (cache key suffix `_v1` enables future migration). Wraps the
  raw envelope with a `cached_at` ISO timestamp.

### Repository impl (`repositories/scheduled_jobs_repository_impl.dart`)

Step 2 of the 4-step error pipeline:

```
[remote DS] → throws HttpFailure / propagates SocketException
[repo]      → _mapHttpFailure() / cache fallback / SocketException → typed failure
[notifier]  → AsyncError surfaces in state
[screen]    → switch on sealed subtype → user-friendly UX
```

Network-first with cache fallback on `SocketException` **for the first
page only**. Paginated pages throw `ScheduledJobsOfflineNoCache` on
`SocketException` (pagination cache adds complexity for marginal value).

`getCounts()` is never cached — counts are cheap, always live, stale
numbers on the segmented control would mislead.

---

## 3. Presentation layer (`presentation/`)

### DI (`providers/dependency_injection.dart`)

All `@Riverpod(keepAlive: true)` per the keepAlive list/counts notifier
constraint. Wires: http.Client, FlutterSecureStorage, remote DS, local
DS, repo, two use cases. `sharedPreferencesProvider` is imported from
the technician onboarding feature (shared boot-time provider).

### State + segment notifier

- `providers/scheduled_jobs_list_state.dart` — `@freezed` state class
  inside the `AsyncValue<...>` wrapper. Carries `segment`, `items`,
  `nextCursor`, `hasMore`, `isLoadingMore`, `isStaleCache`, `cachedAt`,
  `serverTime`.
- `providers/selected_schedule_segment_notifier.dart` — simple
  `@riverpod class` holding the active `ScheduledJobSegment`. Not
  keepAlive — resets to `upcoming` on every screen mount.

### List notifier (`providers/scheduled_jobs_list_notifier.dart`)

`@Riverpod(keepAlive: true)`. Lifecycle:
1. `build()` watches `selectedScheduleSegmentProvider` → segment change
   triggers re-build → fresh first-page fetch.
2. `ref.listen(systemEventProvider, ...)` filters state-machine events
   and triggers `refresh()`. Dedup via `previous?.latestEvent?.id ==
   event.id`.
3. `loadMore()` appends. Idempotent on `hasMore`, `isLoadingMore`,
   `nextCursor`, `isStaleCache`.
4. `refresh()` drops cursor, fetches first page, uses
   `AsyncLoading().copyWithPrevious(state)` so previous items stay
   rendered during refetch.

**Realtime invalidation policy.** Unlike the customer-side list (which
inlines an event-patch mapper), Schedule refetches the page on every
relevant event. Rationale:
- BE status→UI table is the source of truth. Mirroring it client-side
  would invite drift.
- Page is small (≤20 rows). BE selector hits 1 SQL query per page
  (verified by `django_assert_num_queries` tests).
- `copyWithPrevious` keeps previous items rendered during refetch — no
  skeleton flash.

**Events listened to** (state machine causing list-visible mutations):

| Event                       | Why                                    |
| --------------------------- | -------------------------------------- |
| `jobAccepted`               | New row enters Upcoming                |
| `jobCompleted`              | Upcoming → Past                        |
| `bookingRejected`           | Row removed                            |
| `bookingCancelled`          | Upcoming → Past                        |
| `bookingNoShow`             | Upcoming → Past                        |
| `quoteDeclined`             | Inspection-only finalization → Past    |
| `disputeOpened`             | Upcoming → Past                        |
| `paymentReceived`           | Terminates → Past                      |
| `bookingRescheduled`        | Time / status change                   |
| `techEnRoute`               | Mid-job badge update (stays Upcoming)  |
| `techArrived`               | Mid-job badge update                   |
| `inspectionStarted`         | Mid-job badge update                   |
| `quoteGenerated`            | Mid-job badge update                   |
| `quoteApproved`             | Mid-job badge update                   |
| `quoteRevisionRequested`    | Mid-job badge update                   |

Set is broader than the dashboard's because Schedule shows mid-job rows
whose badge updates on intermediate transitions; the dashboard only
cares about row entry/exit.

### Counts notifier (`providers/scheduled_jobs_counts_notifier.dart`)

`@Riverpod(keepAlive: true)`. Same listener pattern with a **smaller
event set** — only events that move a row between Upcoming and Past
counts. Mid-job transitions are absent (the row stays in Upcoming, so
the count doesn't move).

### Boot-hook registration

Both `scheduledJobsListProvider` and `scheduledJobsCountsProvider` are
registered in `realtimeBootHooksProvider`
(`core/realtime/presentation/app_lifecycle_orchestrator.dart`). Without
this, the listeners wouldn't register until the tech opens the Schedule
tab — any event that fired while the tech was on Jobs / Wallet / Profile
tabs would silently drop, and Schedule would diverge from the dashboard's
denormalised "next job" view until pull-to-refresh.

### Screen (`screens/schedule_screen.dart`)

`ScheduleScreen` is the audience-flipped counterpart of
`CustomerBookingsListScreen`:

- Reads `selectedScheduleSegmentProvider`, `scheduledJobsListProvider`,
  `scheduledJobsCountsProvider`.
- Validation auto-retry once before falling through to the server-error
  UI (matches customer-side pattern).
- Hero header (`ScheduledJobsHeroHeader`) with title `Schedule` and
  subtitle `{n} upcoming · {n} past`.
- Segmented control (`ScheduledJobsSegmentedControl`) with badge counts.
- `RefreshIndicator` wraps the list; pull-to-refresh refreshes both list
  + counts in parallel.
- Empty state branches per segment:
  - Upcoming → "No upcoming jobs · Go online from your dashboard to
    start receiving requests."
  - Past → "No past jobs · Your completed and cancelled jobs will show
    up here."

### Widgets (`widgets/`)

- `scheduled_job_card.dart` — `ScheduledJobCard`. Stateful for the
  server-time ticker (re-renders date labels every 30s to keep "In 30
  min" → "In 5 min" current without device-clock skew). Layout: 4px
  tone-accent strip + header row (service icon + uppercase service name
  + status pill ± live pulse dot) + headline row (customer avatar +
  server-driven headline) + meta row (date + address) + payout row
  (icon + payout.context + payout.uiLabel). Terminal rows wrapped in
  `Opacity(0.70) + ColorFilter.matrix(greyscale)`.
- `scheduled_job_card_skeleton.dart` — Shimmer placeholder. Dimensions
  match the real card so no layout flash on data arrival.
- `scheduled_jobs_segmented_control.dart` — Reads counts; appends `· N`
  to each label when counts are loaded.
- `scheduled_jobs_hero_header.dart` — 24px concave curve + brand-blue
  gradient. Same geometry as `BookingsHeroHeader`.
- `scheduled_jobs_offline_banner.dart` — Warning-tone strip ("Offline ·
  last updated 8 min ago") with refresh IconButton.
- `scheduled_jobs_error_state.dart` — `.offline()` / `.server()` /
  `.unknown()` named constructors map to the sealed-failure UI variants.
- `scheduled_jobs_empty_upcoming.dart` / `scheduled_jobs_empty_past.dart`
  — Centered illustration + tech-framed copy.

### Reused from customer/bookings (no local copy)

- `BookingsPalette` (presentation/utils) — brand-blue tokens.
- `BookingStatusPill` (presentation/widgets) — pill with tone palette.
- `BookingTechAvatar` (presentation/widgets) — audience-agnostic avatar
  with initials fallback.
- `formatBookingDate` (presentation/utils) — server-anchored "In 30 min"
  / "Tomorrow, 3:00 PM" formatter.

These will move to `core/booking/` post-viva (tracked in `flag.md`).

---

## 4. Navigation

- Bottom-nav Schedule tab → pushes `/technician/schedule` via
  `technician_dashboard_screen.dart` `_DashboardNavBar.onTap`.
- GoRoute `/technician/schedule` → `ScheduleScreen(showBackButton: true)`
  (the route is reached via push, so back arrow is shown).

---

## 5. Out of scope / future work

- **Per-job detail screen.** Tapping a card is currently a no-op. The
  in-progress orchestrator screen already exists for active jobs;
  surfacing past-job detail is a separate feature.
- **Filter chips.** BE accepts `?status=…` csv override; FE v1 doesn't
  expose this. Add when a product UX need surfaces.
- **Day grouping in Upcoming.** Reserved for design polish — current
  list is a flat chronological feed.
- **Bookings UI primitive extraction.** `flag.md` entry: after viva,
  move `BookingStatusPill`, `BookingsPalette`, `BookingTechAvatar`,
  `formatBookingDate` to `core/booking/` (currently cross-imported from
  `customer/bookings`).

# flag.md — Tech Debt Log

Living list of accepted shortcuts. Each entry has: **what's wrong**, **why we shipped it anyway**, **the proper fix**, and **where to look**. New flags go at the bottom; resolved flags get struck through with the commit/PR that closed them.

---

## ~~1. `JobBooking.accepted_at` — booking state encoded in a side field~~ ✅ Resolved (2026-05-01)

Resolved by introducing an explicit `STATUS_AWAITING_TECH_ACCEPT = 'AWAITING'` value and dropping the `accepted_at` column. The "still waiting on tech accept" signal is now the status itself — one source of truth, no coupled-field reasoning at consumer sites.

**What changed**
- `JobBooking.STATUS_CHOICES` gains `AWAITING`. `accepted_at` field removed. Migration `bookings/0007_drop_accepted_at_add_awaiting_status.py` is `RemoveField(accepted_at)` + `AlterField(status)` to keep choices in sync. Pre-launch project, no production data → no backfill.
- `bookings.services.instant_book_service.create_instant_booking` now creates bookings in `AWAITING` (was `CONFIRMED`). The slot-overlap filter widens to `[PENDING, AWAITING, CONFIRMED]` here and in `technicians.selectors.availability_selector` so an unaccepted booking still reserves its window.
- `bookings.tasks.expire_pending_job_booking` is now a single-status check: flips `AWAITING → REJECTED` and treats every other status as a no-op. The `accepted_at` short-circuit is gone.
- `bookings.services.ports.JobDispatchScheduler.schedule_sla_timeout` docstring updated to reference the AWAITING status.
- `BOOKINGS_API.md`: endpoint description, slot-blocking row, and SLA timeout table refreshed. The timeout table collapses from four rows to three.
- Tests updated across `test_tasks.py`, `test_instant_book_service.py`, `test_instant_book_api.py`, `test_availability_selector.py`, `test_dashboard_selector.py`. New coverage: AWAITING blocks slots in both the service and the availability selector; AWAITING bookings are explicitly excluded from the technician dashboard's Up Next / Later Today widgets.
- Dashboard filter (`technicians.selectors.dashboard_selector`) deliberately stays `CONFIRMED`-only — AWAITING bookings live in the dispatch/accept event surface, not the daily-plan widget.

**Out of scope, deferred** — the technician-acceptance endpoint (`AWAITING → CONFIRMED`) is still pending. Until it lands, simulating acceptance via Django Admin or a shell mutation remains the local-testing path (same as before this flag closed). When it ships, it must run under `transaction.atomic()` + `select_for_update()` and short-circuit on any non-AWAITING status. No new flag is warranted today — the endpoint is a normal forthcoming feature, not a shortcut.

---

## ~~2. `service_name = price_context` — wrong field, wrong reason~~ ✅ Resolved (2026-04-28)

Resolved by introducing real catalog FKs on `JobBooking` and a server-side resolver that classifies every booking into one of three `booking_type` values (`INSPECTION` / `FIXED_GIG` / `LABOR_GIG`).

**What changed**
- `JobBooking` now carries `service` (NOT NULL), `sub_service`, and `promotion` FKs — captures the customer's discovery intent at booking time.
- `POST /api/bookings/instant-book/` accepts `service_id` (required), `sub_service_id` / `promotion_id` (optional). Threaded from the same query params already on `/profile/{id}/` and `/availability/{id}/`. `price_context` dropped from ingress; server-derived now.
- New shared resolver `bookings.selectors.pricing_selector.resolve_booking_intent` — single source of truth for catalog-based pricing across reads and writes. Read paths (technician profile, home feed) refactored to consume it.
- Write-path validations: catalog consistency, promo firewall, price equality (or labor range), with field-level error envelopes.
- `job_new_request` event payload now carries `booking_type` + `payout_context` so the technician's job card can route to the correct on-site flow (Complete vs. Build Quote) and frame the headline payout correctly. Closes the reject-from-confusion failure mode on inspection bookings.
- `price_context` column kept on `JobBooking` as the customer-receipt label; it's now server-authoritative (one of `"Inspection Fee"` / `"Fixed Price"` / `"Labor Fee"`).

**Out of scope, deferred** — see flags 3, 4, 5 below. The originally proposed `JobBookingSubService` M2M was deferred to the quote-builder sprint where it earns its weight; at booking time the FK trio captures intent without it.

---

## ~~3. `TechnicianSkill.base_rate` / `max_rate` — labor pricing as a range~~ ✅ Resolved (2026-04-28)

Resolved by collapsing `TechnicianSkill` to a single `labor_rate` field. The booking write path now requires exact equality across all booking types (fixed, labor, inspection); the resolver's Scenario B branch shrinks to two cases (skill present vs. fallback).

**What changed**
- `TechnicianSkill.max_rate` removed; `base_rate` renamed to `labor_rate` (still nullable — null falls back to `sub_service.base_price`). Migration `technicians/0007_collapse_skill_rate_to_labor_rate.py` is `RemoveField(max_rate)` + `RenameField(base_rate → labor_rate)` — zero production data, no backfill.
- `bookings.selectors.pricing_selector.ResolvedIntent.primary_amount_max` removed; range formatting (`"Rs. 1,000 - 1,400"`) deleted.
- `bookings.services.instant_book_service._assert_price_in_bounds` is now a one-liner equality check across all booking types.
- `PriceMismatchError` simplified — single `expected` field, single error message form (`"Expected X, got Y"`).
- Onboarding ingress: `SkillInputSerializer` exposes `labor_rate` only (no `max_rate`); same on the Flutter `SkillInputModel` / `SkillSelectionEntity`.
- Frontend Step 5 onboarding screen now has a single labor-rate input. Notifier method `updateSkillRates` renamed to `updateSkillRate`.
- API docs updated: `BOOKINGS_API.md` price-validation row, `ONBOARDING_API.md` skill object detail.

**Unblocks** — flag #4 (server-derived `price_amount`). Now that labor pricing is deterministic from `service_id` / `sub_service_id` / `promotion_id` + the technician's skill row, the server can stop accepting `price_amount` on the wire.

---

## ~~4. Client-supplied `price_amount` — server should derive it~~ ✅ Resolved (2026-04-29)

Resolved by removing `price_amount` from the wire entirely. With flag #3's single-`labor_rate` collapse in place, the resolver's `intent.primary_amount` is a deterministic single value across all booking types, so the server can stamp it onto `JobBooking.price_amount` directly with no client input or re-validation step.

**What changed**
- `price_amount` dropped from `InstantBookSerializer` and from the `create_instant_booking` service signature.
- Booking creation now uses `price_amount=intent.primary_amount` — single source of truth lives in the pricing resolver.
- `_assert_price_in_bounds` and `PriceMismatchError` deleted; the view's `except PriceMismatchError` handler and the corresponding `400 — Price Mismatch` envelope are gone.
- `BOOKINGS_API.md` request-body table no longer lists `price_amount`; sample bodies for Scenarios A/C/D are slimmed down; the Defensive Check Pipeline shrinks from seven steps to six (Geofence → 5, Slot Race Lock → 6).
- §2.1 / §2.2 frontend contract sections updated — the field-keyed validation-error dictionary shrinks to two entries (`sub_service_id`, `promotion_id`).
- Flutter side: `priceAmount` removed from `InstantBookingRequestModel`, `IBookingRepository.createInstantBooking`, `CreateInstantBookingUseCase`, `InstantBookingNotifier.book`, and the `ReviewBookingSheet` call site. The `_resolveErrorPresentation` `price_amount` toast branch is deleted (the server can no longer return that error key).
- `TechnicianProfileEntity.primaryPrice` / `primaryPriceRaw` stay — they drive the review-sheet display, which the customer confirms before the server stamps the same figure.

---

## 5. Quote-phase `JobBookingSubService` M2M — deferred from flag #2

**Where (planned)**
- New model: `backend/bookings/models.py` (`JobBookingSubService` join table)
- Write path: a quote-builder service module (does not exist yet) populated from the technician's on-site Build Quote screen.

**What's wrong (today)**
A booking row knows the *initial* catalog reference (via the FK trio resolved in flag #2), but it has no record of the line items the technician actually performed during the visit. For inspection bookings the technician arrives, diagnoses, and quotes some set of sub-services; for fixed/labor gigs the technician may add line items if the customer agrees on-site. None of that is currently expressible in the schema.

**Why we shipped it that way**
Flag #2's scope was "stop using `price_context` as a service identifier." The M2M earns its weight only in the quote-building flow, and the quote builder is a sprint of its own (technician on-site UI, customer approval flow, commission accounting against per-line-item `priced_at`). Bundling that work into flag #2 would have multiplied the scope.

**The proper fix**
1. Add `JobBookingSubService` join table with fields `booking` (FK), `sub_service` (FK), `priced_at` (Decimal), `created_via` (enum: `INITIAL` | `QUOTE` | `ON_SITE_ADD`), `created_at`. The `created_via` discriminator preserves "what was pre-agreed" vs. "what the technician built on-site."
2. New service `bookings.services.quote_builder.build_quote(booking, line_items)` — populates the M2M for `INSPECTION` bookings.
3. New service `bookings.services.line_items.add_line_item(booking, sub_service, priced_at)` — `FIXED_GIG` / `LABOR_GIG` extension flow with customer approval gate.
4. Audit downstream events (`quote_generated`, `quote_approved`, `job_completed`) — surface sub-services on the wire.
5. Commission accounting moves from `JobBooking.price_amount × 0.80` to a per-line-item sum.

When picking this up, the technician's on-site UX is the design-heavy part — the data model is straightforward.

---

## 6. `IncomingJobQueueNotifier` — append-only queue, no expiry sweep

**Where**
- `frontend/lib/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart`

**What's wrong**
The queue notifier is append-only this sprint. Entries are never auto-evicted when `expiresAt` passes, and there is no periodic sweep timer. ASAP-tier requests linger in memory for 60 seconds past their server SLA; scheduled-tier for 15 minutes past. With no UI consuming or dismissing entries (the real card widget hasn't shipped yet), a long-running technician session can accumulate stale entries until app restart. The bound is loose — the dispatch volume is low and `keepAlive: true` survives navigation but not process death — so memory pressure is not realistic, but the in-memory state misrepresents truth: the queue can hold "pending" requests that the server already flipped to `REJECTED` via the SLA timeout Celery task.

**Why we shipped it that way**
The widget that would naturally drive eviction (accept / decline / dismiss → `removeRequest(jobId)`, already wired) is intentionally deferred to the UI sprint. Adding a sweep timer now without the UI consuming it is premature; the bound is loose enough to be safe in normal use; and the on-disk state of truth is the backend (server-side `JobBooking.status`), so a stale entry in memory is a UX nuisance, not a data-integrity bug.

**The proper fix**
1. Inside `IncomingJobQueueNotifier.build()`, add a `Timer.periodic(const Duration(seconds: 10), _sweepExpired)` and register `ref.onDispose(timer.cancel)` so the sweep dies with the notifier.
2. `_sweepExpired` filters `state.queue` by `entry.expiresAt.isAfter(DateTime.now())` and reassigns state only if the resulting list shrank (avoids spurious rebuilds).
3. Make sure the widget cancels its per-entry countdown UI atomically with the sweep so the technician never sees a card flicker between "5s left" and gone.
4. Search hint: grep for `removeRequest` to find the existing manual-eviction surface; the sweep helper should sit alongside it.

When picking this up, also evaluate whether the eviction policy should be aggressive (drop the moment `expiresAt` passes) or grace-period (keep showing for ~3s with a visual fade) — either is fine, but the choice should be conscious and documented in `INCOMING_JOB_REQUESTS_FEATURE.md`'s "Known limitations" section.

---

## ~~7. Realtime stack defined but never mounted in app boot~~ ✅ Resolved for Android (2026-05-01)

**What changed (Session 3 — Android close-out)**

- `frontend/android/app/src/main/AndroidManifest.xml` declares
  `POST_NOTIFICATIONS` (Android 13+ runtime permission) plus three FCM
  meta-data entries that pin the default channel id, status-bar icon, and
  notification color: `default_notification_channel_id`,
  `default_notification_icon`, `default_notification_color`. Without these,
  the system tray would render against an OS-managed unnamed channel
  (silently muted on some OEMs) with a gray-square icon.
- `res/drawable/ic_notification.xml` (alpha-only vector, status-bar safe),
  `res/values/colors.xml` (`@color/notification_color` = brand seed
  `#1976D2`), `res/values/strings.xml` (`default_notification_channel_id`
  = `job_dispatch`, plus user-visible channel name and description).
- `pubspec.yaml` adds `flutter_local_notifications: ^21.0.0` for the
  channel-creation API (Android `NotificationChannel` is not exposed by
  `firebase_messaging` directly).
- New file `core/realtime/presentation/services/notification_channels.dart`
  is the single source of truth for the `job_dispatch` channel
  definition (`Importance.high` for heads-up rendering) plus an
  idempotent `ensureJobDispatchChannel()` registrar. Used by both
  isolates so the two registrations cannot drift.
- `FCMHandler.initialize()` calls `ensureJobDispatchChannel()` before
  `requestPermission()` — the channel must exist before any notification
  can display.
- `firebaseMessagingBackgroundHandler` calls the same helper at the top
  (defensive: covers the fresh-install-killed-state-push edge case where
  the BG isolate is the only Dart VM that has ever run).
- `main.dart` refactored: `Future<Widget> bootApp({injectable Firebase /
  BG handler / SharedPrefs initializers})` extracted from `main()`. Plus
  `@visibleForTesting Widget buildAppRootWidget()` that returns the
  internal `_Bootstrap` so the widget test can wrap it in its own
  `ProviderScope`. Behaviour identical in production.
- 23 new tests (all green; suite total 491 → 514):
  - `test/features/auth/presentation/providers/auth_notifier_realtime_bridge_test.dart`
    — A1–A10 pin the AuthNotifier-side bridge contract: cold-start
    boot fires with the cached token (A1), no-boot on logged-out (A2)
    or null/empty token (A3/A4), `verifyOtp` boots with the FRESH
    token not the stale cached one (A5), `logout()` runs the FULL
    teardown sequence — `ws.disconnect → fcm.unregister → sysEvent.reset
    → local.clearLastSyncTimestamp → clearCachedEvents → clearPendingAcks
    → onUnauthorized=null` — BEFORE `repository.logout()` (A6),
    `getCachedUser` throwing surfaces AsyncError without ghost-booting
    (A7), `requestOtp` and `completeSignup` don't re-boot (A8/A9),
    double-tap logout short-circuits via `state.isLoading` (A10).
  - `test/core/realtime/presentation/services/notification_channels_test.dart`
    — C1–C5 pin channel id, `Importance.high`, name+description,
    Dart-side non-memoization (Android dedups by id), and
    PlatformException-resilience.
  - `test/main_app_boot_widget_test.dart` — W1–W8 close the
    architectural-review gap that allowed flag #7 to ship: W1–W3 assert
    `bootApp` invokes `firebaseInit`, `bgHandlerRegistrar`, and
    `sharedPrefsLoader` exactly once (recording fakes); W4–W6 pump the
    real composition tree and assert `AppLifecycleOrchestrator` is
    mounted with the SAME `navigatorKey` / `scaffoldMessengerKey`
    instances that `navigatorKeyProvider` /
    `scaffoldMessengerKeyProvider` return (catches the "fresh GlobalKey"
    regression that breaks route pushes and banners); W7–W8 verify the
    composition mounts cleanly for both unauthenticated and cached-user
    states, including the cached-user bridge firing through the full
    composition path.

**Severity (after Session 3)** — Resolved for Android. Only iOS native
push capability remains; tracked as flag #10. Android tray notifications
arrive end-to-end (foreground / background / killed-state cold-launch),
including tap routing via `getInitialMessage()`.

**Out of scope, deferred** — iOS native capabilities (`Info.plist`
`UIBackgroundModes`, Push Notifications entitlement, APNs `.p8` upload).
The project is Android-only for now; no Mac in the development
environment. Tracked as flag #10.

---

**Historical context** (kept per CLAUDE.md "never delete" — original
problem statement and Session 1/2 progress):

**Where**
- `frontend/lib/main.dart` (composition root that needs the wiring)
- `frontend/lib/features/auth/presentation/providers/auth_notifier.dart` (build / verifyOtp / logout — three integration points)
- `frontend/lib/core/realtime/presentation/app_lifecycle_orchestrator.dart` (the consumer waiting to be mounted)
- `frontend/lib/core/routing/app_router.dart` (GoRouter constructor, currently no `navigatorKey`)
- `frontend/ios/Runner/Info.plist`
- `frontend/android/app/src/main/AndroidManifest.xml`

**What's wrong**
The realtime subsystem (`SystemEventNotifier`, `WsConnectionNotifier`, `EventSyncNotifier`, `FCMHandler`, `firebaseMessagingBackgroundHandler`, `EventUrgencyRouter`, and feature-side queue notifiers like `IncomingJobQueueNotifier`) is fully implemented and unit-tested in isolation, but **none of it runs in the production app boot path**. Specifically:

1. **`main.dart` does not call `Firebase.initializeApp()`**. The only place Firebase initializes is the BG isolate inside `firebaseMessagingBackgroundHandler` (`fcm_background_handler.dart:35`). The main isolate never does, so foreground listeners (`FirebaseMessaging.onMessage`, `onMessageOpenedApp`, `getInitialMessage`) and `getToken()` would all crash on first use.

2. **`main.dart` does not register the BG handler**. `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` is never called, so the OS has no Dart-side callback to invoke for FCM messages while the app is terminated. The `event_sync_pending_bg_events` queue stays empty forever; the entire terminated-state delivery path is dead despite the BG handler file existing and being correct.

3. **`AppLifecycleOrchestrator` is never mounted in the widget tree**. `runApp(...)` jumps from `ProviderScope` straight to `MyApp` (`MaterialApp.router`). The orchestrator's `WidgetsBindingObserver` never registers, so `didChangeAppLifecycleState(AppLifecycleState.resumed)` never fires, so `_onResumed` (WS reconcile + sync + BG-queue drain) never runs. The `ref.listenManual(systemEventProvider, ...)` that drives `EventUrgencyRouter` (`app_lifecycle_orchestrator.dart:183-191`) is also never set up — meaning even if events arrived, no one would route them.

4. **`AuthNotifier` does not bridge to `bootAfterAuth` or `teardownOnLogout`**:
   - `build()` (cold-start session restoration, `auth_notifier.dart:13`) returns the cached user without touching the realtime stack.
   - `verifyOtp(...)` (fresh login, `auth_notifier.dart:40`) returns `AuthState(user: user)` and stops.
   - `logout()` (`auth_notifier.dart:97`) calls the repository and clears state; never tears down WS, FCM, pending events, or the unauthorized callback.
   The orchestrator's docstring (`app_lifecycle_orchestrator.dart:67-76`) explicitly directs the auth feature to call these helpers; that contract is unmet.

5. **`navigatorKey` and `scaffoldMessengerKey` are not constructed or threaded**. `EventUrgencyRouter` requires the same `GlobalKey<NavigatorState>` GoRouter uses (so push routes against the live navigator) and the same `GlobalKey<ScaffoldMessengerState>` `MaterialApp` uses (so banners surface on the visible screen). Currently:
   - `app_router.dart:18-22` constructs `GoRouter(...)` with no `navigatorKey:` argument.
   - `main.dart:38-47` constructs `MaterialApp.router(...)` with no `scaffoldMessengerKey:`.
   Without shared keys, even a wired-up `EventUrgencyRouter` can't push or banner.

6. **iOS push capability is not declared**. `ios/Runner/Info.plist` has no `UIBackgroundModes` array containing `remote-notification`, and there's no evidence the Push Notifications capability is enabled in `Runner.xcodeproj` (Info.plist alone doesn't switch it on — Xcode also needs an entitlement). Without these, iOS will not wake the app for background data messages even if everything else is fixed. APNs auth key upload to Firebase is also out-of-band and presumably not done.

7. **Android `POST_NOTIFICATIONS` permission is missing**. `AndroidManifest.xml:1-7` declares only `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`. Android 13+ (API 33+) requires `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` plus a runtime prompt for the system tray notification to appear at all. `FCMHandler.requestPermission()` calls `FirebaseMessaging.instance.requestPermission()`, which on Android 13+ delegates to the OS permission dialog — but the OS will not surface the dialog without the manifest entry. (Native Firebase Android otherwise looks fine: `google-services` Gradle plugin is wired in `android/build.gradle.kts` + `android/app/build.gradle.kts`, `google-services.json` is real for project `karigar-8e3d3`.)

**Why we shipped it that way**
The realtime subsystem was developed as a self-contained module landing in a single reviewable patch, with the integration into `main.dart` and `auth_notifier` deliberately deferred to a follow-up. Tests pass cleanly because every realtime test exercises the stack via direct `ProviderContainer` calls — no test calls `runApp`, so no test catches the missing wiring. Subsequent feature work (incoming job requests, addresses, discovery) builds on top of providers that are reachable from a `ProviderContainer` even without the orchestrator, so no incremental sprint has been forced to confront this.

The result is a subsystem that is logically correct end-to-end and a production app that delivers zero realtime events.

**The proper fix**

In order:

1. **`main.dart`** — initialize Firebase, register the BG handler, construct the shared keys, and mount the orchestrator above `MaterialApp.router`:

   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'package:firebase_messaging/firebase_messaging.dart';
   import 'core/realtime/presentation/app_lifecycle_orchestrator.dart';
   import 'core/realtime/presentation/services/fcm_background_handler.dart';

   final _navigatorKey = GlobalKey<NavigatorState>();
   final _messengerKey = GlobalKey<ScaffoldMessengerState>();

   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
     final sharedPreferences = await SharedPreferences.getInstance();
     runApp(
       ProviderScope(
         overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
         child: AppLifecycleOrchestrator(
           navigatorKey: _navigatorKey,
           scaffoldMessengerKey: _messengerKey,
           child: MyApp(navigatorKey: _navigatorKey, messengerKey: _messengerKey),
         ),
       ),
     );
   }
   ```

2. **`MyApp`** — accept the messenger key and thread it into `MaterialApp.router`:

   ```dart
   MaterialApp.router(
     scaffoldMessengerKey: messengerKey,
     routerConfig: router,
     ...
   );
   ```

3. **`app_router.dart`** — accept the same `navigatorKey` and pass it to `GoRouter`. Easiest path is to expose the key via a top-level provider (`final navigatorKeyProvider = Provider((_) => GlobalKey<NavigatorState>());`) and `ref.watch` it inside `routerProvider`, or accept it as a parameter to a `routerProviderFor(navigatorKey)` family. Either way: `GoRouter(navigatorKey: navigatorKey, ...)`.

4. **`auth_notifier.dart`** — call boot/teardown at three transition points:
   - `build()` (`auth_notifier.dart:13`) — after restoring the cached user, if `user.token != null`, await `AppLifecycleOrchestrator.bootAfterAuth(ref, user.token!)`. This is the cold-start-with-valid-session path.
   - `verifyOtp(...)` (`auth_notifier.dart:40`) — after `useCase.execute(...)` returns the fresh user, await `bootAfterAuth(ref, user.token!)` before emitting `AsyncData(AuthState(user: user))`.
   - `logout()` (`auth_notifier.dart:97`) — await `AppLifecycleOrchestrator.teardownOnLogout(ref)` BEFORE `repository.logout()`, because `performTeardown` requires the WS to disconnect with the auth token still valid (server-side device unregister needs the token).

   `Notifier.build()` does not receive a `WidgetRef`, so the `bootAfterAuth` helpers will need a `Ref`-only variant (the current signature takes `WidgetRef`; refactor to accept `Ref` since the helpers only call `ref.read`, never `ref.watch`). Alternative: defer the boot call to the first widget consumer via `ref.listenSelf`. The `Ref`-variant is cleaner.

5. **iOS — `ios/Runner/Info.plist`**:

   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>remote-notification</string>
   </array>
   ```

   Plus enable the Push Notifications capability in `Runner.xcodeproj` (creates `Runner.entitlements` with `aps-environment`). Plus upload the APNs auth key to Firebase Console → Project Settings → Cloud Messaging → Apple app config.

6. **Android — `AndroidManifest.xml`**: add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` at the manifest root level. The default `FirebaseMessagingService` declaration is auto-merged by the FCM plugin and does not need to be added manually — verify after first build by inspecting `app/build/intermediates/merged_manifests/.../AndroidManifest.xml`.

**Search hints**
- `runApp(` — single call site to wrap.
- `FCMHandler.initialize` (`fcm_handler.dart:62`) — what runs after `Firebase.initializeApp` succeeds; nothing to change here, just the entry contract.
- `bootAfterAuth` / `teardownOnLogout` (`app_lifecycle_orchestrator.dart:111` / `:147`) — the static helpers to call from auth.
- `routerProvider` (`app_router.dart:18`) — the GoRouter construction site.
- `WidgetRef` in `bootAfterAuth` signature — replace with `Ref` to make it callable from `Notifier.build()`.

**Test coverage that should land with the fix**
- A widget test that pumps the full `runApp` tree (with mocked `Firebase`, `FirebaseMessaging`, and a fake WS data source): cold start with a cached user → `WsConnectionNotifier.connect` is called; `logout()` → `WsConnectionNotifier.disconnect` is called.
- A test asserting that `getInitialMessage()` returning a `job_new_request` payload at cold start results in the expected route push to `/technician/incoming-job-request`. Doable with `mocktail` + a fake `FirebaseMessaging`.
- An auth-notifier test asserting that `build()` with a cached token, `verifyOtp` success, and `logout` each invoke the expected orchestrator helper.

**Severity**
Blocking for any production use of the realtime stack. Not blocking for sprints that don't depend on real event delivery (most current frontend feature work runs against direct provider containers in tests and doesn't exercise the WS/FCM path in dev). Should be picked up before the technician dashboard ships, since the technician's incoming-job experience is meaningless without it.

**Progress (2026-05-01)**

Session 1 (commit 2fb512d) closed sub-items 1, 2, 3, 5: `Firebase.initializeApp()` runs on the main isolate, `firebaseMessagingBackgroundHandler` is registered before `runApp`, `AppLifecycleOrchestrator` wraps `MaterialApp.router` via `_Bootstrap`, and `navigatorKey` / `scaffoldMessengerKey` flow through shared providers (`navigatorKeyProvider`, `scaffoldMessengerKeyProvider`) into both the orchestrator and `GoRouter` / `MaterialApp.router`. Pinned by `main_isolate_wiring_test.dart` (W1a/W1b/W2/W3).

Session 2 (this session) closes sub-item 4 — the `AuthNotifier` ↔ orchestrator bridge:

- `bootAfterAuth(WidgetRef, String)` → `bootAfterAuth(Ref, String)`; `teardownOnLogout(WidgetRef)` → `teardownOnLogout(Ref)`. Callable from `Notifier.build()`.
- `AuthNotifier.build()` and `verifyOtp()` schedule boot via a private `_scheduleBoot(token)` helper. Helper is empty-string-safe (`token == null || token.isEmpty` short-circuits, matching the orchestrator's `_onResumed` symmetry) and wraps the `unawaited` future in `.catchError(log)` so failures surface in dev/ops instead of vanishing into the Dart zone.
- `AuthNotifier.logout()` now (a) gates on `state.isLoading` to no-op a fast double-tap and (b) awaits `teardownOnLogout(ref)` BEFORE `repository.logout()` — load-bearing because the FCM device-unregister POST inside teardown reads the token from secure storage that `repository.logout()` is about to clear.
- `AppLifecycleOrchestrator.bootAfterAuth` gained a "still booting" sentinel after FCM init: if `eventSync.onUnauthorized` is null (teardown ran during the FCM await), skip `wsConnection.connect(authToken)`. Closes the dominant case of the boot/teardown race; the residual race (teardown during the WS handshake itself) is tracked as flag #9 below.
- The inline `ref.read(incomingJobQueueProvider)` was extracted into a new `realtimeBootHooksProvider` registry. Adding a new list-route event feature is now an append to that list — no edits to `bootAfterAuth`, no risk of silently dropping the wake-up. Tests R1/R2 in `app_lifecycle_orchestrator_test.dart` pin the contract.
- New tests: AB1–AB8 in `auth_notifier_test.dart` cover boot fires on cached token / verify success, no-boot on null/empty token, teardown ordering via `verifyInOrder`, and the `isLoading` guard against double-tap logout. R1/R2/B1/B2 in `app_lifecycle_orchestrator_test.dart` cover the registry contract and the sentinel race.

**Remaining (post-Session-2)**: sub-item 6 (iOS native push capability) is out of scope for this Android-only project. Sub-item 7 (Android `POST_NOTIFICATIONS` permission) plus the widget-level `runApp`-tree integration test remain for Session 3.

**Session 3 outcome (2026-05-01)** — closed the remaining Android items: `POST_NOTIFICATIONS` permission + 3 FCM meta-data entries + `job_dispatch` notification channel (HIGH importance, dual-isolate registration), 23 new tests including the load-bearing widget tests that pump the real `bootApp` tree. iOS sub-item 6 spun out as flag #10. See "What changed (Session 3 — Android close-out)" block at the top of this entry.

---

## 8. Auth token rotation has no graceful path

**Where**
- `frontend/lib/features/auth/presentation/providers/auth_notifier.dart`
- `frontend/lib/core/realtime/presentation/app_lifecycle_orchestrator.dart`
- `frontend/lib/core/realtime/presentation/notifiers/event_sync_notifier.dart`
- `frontend/lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart`

**What's wrong**
The realtime stack captures the auth token at boot time. `bootAfterAuth(ref, authToken)` passes the token into `wsConnection.connect(authToken)`, which embeds it in the WS query string. There is no mechanism to update that connection's token mid-session: if the backend rotates the token (refresh endpoint, key rotation, forced re-auth), the next authenticated WS frame eventually 401s. `EventSyncNotifier.onUnauthorized` then fires `authProvider.notifier.logout()` — destructive recovery that drops the user back to `/login` even though their session is otherwise valid.

Cold-start works because `AuthNotifier.build()` reads the latest cached token before scheduling boot. But a long-lived foreground session that survives a server-side rotation has no path to update the WS auth without a full logout/login round-trip.

**Why we shipped it that way**
Session 2's scope was the boot/teardown bridge — wiring three call sites in `AuthNotifier`. Token rotation is a distinct concern: it requires a refresh endpoint contract (which the backend has not committed to), a secure-storage write path that the WS layer can observe, and `WsConnectionNotifier.connect` semantics for "reconnect with a different token." Bundling that work into Session 2 would have multiplied the scope and shipped half-built rotation logic.

**The proper fix**
Pick one of:
1. **WS watches secure storage.** `WsConnectionNotifier` listens for token changes on `eventSecureStorageProvider` (or a dedicated `authTokenProvider` backed by it) and re-handshakes when the value flips. Cleanest from a "single source of truth" angle (storage is already authoritative), heaviest in plumbing (storage doesn't naturally produce a stream).
2. **Auth notifier exposes `refreshToken(newToken)`** that calls a new `AppLifecycleOrchestrator.rebootAfterRotation(ref, newToken)` helper. Helper is `wsConnection.disconnect()` → `wsConnection.connect(newToken)`. Conceptually simpler; couples auth and realtime more tightly but keeps the rotation surface explicit.
3. **Short-lived JWTs + WS interceptor** that refreshes silently before each frame. Most correct long-term; biggest backend lift.

The decision depends on whether the backend ships rotation at all. If it does, option 2 is the smallest move that closes this. If JWT migration ever lands, option 3 supersedes everything.

**Search hints**
- `wsConnection.connect(` — every call site that hands a token to the WS.
- `EventSyncUnauthorized` (`event_failures.dart`) — the trigger that today only knows "log out."
- `_kTokenKey = 'auth_token'` (`event_remote_data_source.dart`, mirrored in `app_lifecycle_orchestrator.dart`'s `_tokenKey`) — the secure-storage key whose value changes on rotation.

**Severity**
Latent. Backend doesn't rotate today; the failure mode does not exist in production yet. Ship before any backend rotation feature lands; otherwise the first rotation event will look like a mass logout to users.

---

## 9. `WsConnectionNotifier.connect` ignores `_manualDisconnect` in its handshake catch path

**Where**
- `frontend/lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart` — `connect()` body, lines ~80-94 and `_scheduleReconnect` lines ~158-177.

**What's wrong**
`disconnect()` sets `_manualDisconnect = true` and cancels the reconnect timer. The stream listener's `onDone` callback honors this flag (returns early on manual disconnect, line 110). The catch block around `await _channel!.ready` does NOT — it calls `_scheduleReconnect(authToken)` unconditionally on any handshake failure (line 92).

This matters because of the boot/teardown race. Session 2 added a sentinel in `bootAfterAuth` that handles teardown-during-FCM-init (the dominant case). The residual race is teardown landing during the WS handshake itself: `connect()` is awaiting `_channel!.ready`, `disconnect()` runs (closing the channel, which fails the `ready` future), the catch block schedules a reconnect with the original (now-stale) `authToken`. Reconnect timer fires after `_currentBackoff`, calls `connect(staleToken)`, repeats until `_kMaxRetries` (10) and flips state to `failed`. Token is already cleared from secure storage by the time the reconnect attempts run, so each one is wasted work that ends in another `failed` flip.

**Why we shipped it that way**
The race window is the WS handshake duration (typically 100–500ms) intersected with the user manually tapping logout. Practically rare. The sentinel in `bootAfterAuth` already handles the much wider window (FCM init, often 2–5s). Fixing this required a one-line guard inside `WsConnectionNotifier`, which is outside Session 2's two-files scope (auth_notifier, app_lifecycle_orchestrator).

**The proper fix**
Two-line guard at the top of `_scheduleReconnect`:

```dart
void _scheduleReconnect(String authToken) {
  if (_manualDisconnect) return;
  _reconnectTimer?.cancel();
  ...
}
```

Plus a regression test in `ws_connection_notifier_test.dart`: kick off `connect()` with a fake channel whose `ready` future never completes; call `disconnect()`; advance fake time past the reconnect backoff; assert no second `connect` was attempted.

**Search hints**
- `_manualDisconnect` (`ws_connection_notifier.dart`) — currently only consulted in the `onDone` handler.
- `_scheduleReconnect` — all three call sites (handshake catch, stream onDone, stream onError) should respect manual disconnect.

**Severity**
Edge case. Logs noise + wasted backoff cycles after a logout-during-handshake, but no incorrect state — the WS eventually flips to `failed` and stays disconnected. Fix when next touching `WsConnectionNotifier`; do not bundle into auth or orchestrator work.

---

## 10. iOS native realtime push capability

**Where**
- `frontend/ios/Runner/Info.plist`
- `frontend/ios/Runner/Runner.xcodeproj/project.pbxproj` (Push Notifications capability toggle)
- `frontend/ios/Runner/Runner.entitlements` (created when the capability toggle runs in Xcode)
- Firebase Console → Project Settings → Cloud Messaging → Apple app configuration (APNs `.p8` key upload — out-of-band, not code-tracked)

**What's wrong**
Flag #7 closed the realtime stack composition for Android. iOS, however, cannot deliver background or terminated-state FCM messages because three things are missing:

1. `Info.plist` has no `UIBackgroundModes` array containing `remote-notification`. Without it, iOS will not wake the app for background data messages — `firebaseMessagingBackgroundHandler` never fires, the BG queue stays empty, and tap-to-route on cold-launch via `getInitialMessage()` never resolves a payload.
2. The Push Notifications capability is not enabled in `Runner.xcodeproj`. `Info.plist` alone doesn't switch this on; Xcode also needs an `aps-environment` entitlement, which is generated only when you toggle Capabilities → Push Notifications in the Xcode UI.
3. APNs auth key has not been uploaded to Firebase Console. Without it, FCM cannot translate Cloud Messages to APNs, so even a fully-configured iOS client receives nothing.

The realtime plumbing on the Dart side (orchestrator, FCM handler, BG handler) is platform-agnostic and would work the moment iOS's native side delivers a message. None of it does.

**Why we shipped it that way**
The development environment is Linux-only — no Mac, no Xcode. The Push Notifications capability toggle, the entitlements file generation, and the build-and-test cycle for iOS push delivery all require macOS. The product is also Android-only for the foreseeable future (Pakistan market, target user demographic), so iOS work is not on the critical path. Spun out of flag #7 (Session 3 close-out) so the Android resolution doesn't pretend to cover both platforms.

**The proper fix**

On a Mac with Xcode:

1. `open frontend/ios/Runner.xcworkspace`.
2. Select the `Runner` target → Signing & Capabilities → `+ Capability` → Push Notifications. This generates `Runner.entitlements` with `aps-environment`.
3. `+ Capability` → Background Modes → check `Remote notifications`. Xcode writes the `UIBackgroundModes` array into `Info.plist`.
4. In Firebase Console → Project Settings → Cloud Messaging → Apple app configuration, upload the APNs auth key (`.p8` file from Apple Developer Portal under Keys → Apple Push Notifications service). Note the Key ID and Team ID.
5. Build and install on a real iOS device — push delivery does not work in the simulator.
6. Verification: log in, foreground the app, grant notification permission. Background the app. Trigger a `job_new_request` via `EventDispatchService.broadcast_event(...)` from the Django shell. A system-tray notification should appear within ~2s. Tap it → app foregrounds and routes to `/technician/incoming-job-request`.
7. Force-kill the app, repeat the trigger. Notification appears, BG handler queues the event into SharedPreferences, tap cold-launches the app, `getInitialMessage()` returns the payload, route push to `/technician/incoming-job-request` fires.

**Search hints**
- `Runner.entitlements` — should appear at `frontend/ios/Runner/Runner.entitlements` after the capability toggle.
- `UIBackgroundModes` — search `Info.plist` to confirm the array landed.
- The `.p8` APNs key never goes in the repo — it lives only in Firebase Console and Apple Developer Portal.
- `flag #7`'s "What changed (Session 3)" block lists everything that already works platform-agnostically (channel registration, BG handler, manifest equivalents). iOS work is purely the native-capability gap.

**Severity**
Blocking for any iOS production rollout. Not blocking for the current Android-only target. Pick up when the project commits to iOS or when a Mac becomes available.

---

## ~~11. Foreground WebSocket events don't trigger in-app routing~~ ✅ Resolved (2026-05-01)

Root cause was a single line in `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart`: `_isAlreadyOnEntity` called `GoRouterState.of(navigatorKey.currentContext)`. `navigatorKey.currentContext` sits *above* every route-builder subtree, and `GoRouterState.of` only resolves *inside* one — it threw `GoError: There is no GoRouterState above the current context` before `_handleHigh` could invoke `GoRouter.push(...)`. Fixed by reading the current URI from `GoRouter.of(ctx).routerDelegate.currentConfiguration.uri`, which works at any context at-or-below the GoRouter widget. The throw affected both WS and FCM delivery paths; surfaced during testing because the WS path was incidentally broken (see flag #13). Verified end-to-end via FCM-delivered `job_new_request`: orchestrator's `ref.listenManual` fires, role gate passes, `_handleHigh` issues `GoRouter.push`, `IncomingJobRequestScreen` mounts and renders the queue entry with real data.

The original entry's "Likely culprits" list (missing `kind`, dedup race, list-route guard, navigator-key drift, queue-notifier wake order) was wrong on every count. None of those were the issue. Diagnostic instrumentation ([1/4]…[4/4] `print` statements at four pipeline seams in `ws_connection_notifier.dart`, `ws_frame_dispatcher.dart`, `system_event_notifier.dart`, `event_urgency_router.dart`) was added during debugging and removed after the fix landed. Spun off two adjacent issues that were masked or surfaced by this debugging: flag #12 (EventLog double-envelope) and flag #13 (Daphne missing from INSTALLED_APPS).

**Historical context** (kept per CLAUDE.md "never delete" — original problem statement and proposed fix path):

## 11. Foreground WebSocket events don't trigger in-app routing

**Where**
- `frontend/lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart` — WS frame entry point
- `frontend/lib/core/realtime/presentation/services/ws_frame_dispatcher.dart` — `kind` switch
- `frontend/lib/core/realtime/presentation/notifiers/system_event_notifier.dart` — single ingestion funnel
- `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart` — high-urgency route push / low-urgency banner
- `backend/realtime/events/services/event_dispatch_service.py` — `_push_to_channel_layer`

**What's wrong**
With the app foregrounded and the WebSocket connected (confirmed via Django runserver `WSCONNECT` log), firing a `job_new_request` event via `EventDispatchService.broadcast_event(...)` from the Django shell produces **no observable effect in the app**:

- No in-app banner
- No route push to `/technician/incoming-job-request`
- No visible UI change
- No exception in `flutter logs` (just Android `BLAST` rendering noise)

The killed-state path works correctly: FCM tray notification arrives, tap routes to the right screen, `getInitialMessage()` resolves the payload. The break is specifically on the foreground WebSocket → in-app routing pipeline.

**Why we shipped it that way**
Surfaced during Session 3 Tier 2 manual E2E (2026-05-01). The issue is pre-existing — the WS-to-router pipeline was wired in earlier sessions and every isolated unit test (R1/R2 boot-hooks registry, B1/B2 sentinel race, A1–A10 auth bridge, channel/widget tests) passes. But no test pumps the *full* path "WS frame arrives → router pushes the route" because that requires either an integration harness or a real device with logging instrumentation. Tier 2 was the first time anyone exercised it end-to-end against a real backend.

**The proper fix**

1. **Add diagnostic logging** at every link in the chain (use `dart:developer.log` with distinct `name:` per layer):
   - `WsConnectionNotifier._handleMessage` — log "frame received: <bytes>"
   - `WsFrameDispatcher.dispatch` — log "dispatching kind=<kind> rawType=<rawType>"
   - `SystemEventNotifier.processEvent` — log "accepting event id=<id> type=<type>" or "rejecting (dedup/order/null)"
   - `EventUrgencyRouter.handleEvent` — log "routing event type=<type> urgency=<urgency> action=<push|banner|silent>"
2. Run `python manage.py shell < dev_send_push.py` with the app foregrounded and trace where the chain breaks. Likely culprits:
   - WS frame missing the `kind: "event"` field (dispatcher silently drops via `default` branch)
   - `SystemEventNotifier` dedup-rejecting because the same event id arrived earlier via FCM background queue and is still in the dedup map
   - `EventUrgencyRouter._highUrgencyRoutes` missing the entry for `job_new_request` (regression check the router map)
   - Shared `navigatorKeyProvider` isn't actually shared (router push targets a different `GlobalKey<NavigatorState>` than `MaterialApp.router` uses) — Session 3's W5 widget test pins this for `bootApp`, but the production runtime path could still drift
   - `_listRouteEvents` membership for `job_new_request` causes the nav guard to skip the push when the screen is already mounted, AND the screen isn't mounted, AND the queue notifier isn't woken (even though `realtimeBootHooksProvider` should have woken it)
3. Once the failing layer is identified, fix at the smallest seam and add a regression test that exercises the full path (probably a widget test that mounts `bootApp` then injects a fake WS frame at the `WsConnectionNotifier` boundary).

**Search hints**
- `WsConnectionNotifier._handleMessage` — frame entry
- `WsFrameDispatcher.dispatch` — `kind` switch
- `SystemEventNotifier.processEvent` — dedup + ingest
- `EventUrgencyRouter._highUrgencyRoutes` — route map
- `_listRouteEvents` / `_navGuardPayloadKeys` (in `event_urgency_router.dart`) — nav-guard logic that may swallow pushes
- `realtimeBootHooksProvider` (in `app_lifecycle_orchestrator.dart`) — queue-notifier wake list

**Severity**
Medium. Killed/backgrounded delivery via FCM works (users get notifications when the app is closed — the highest-stakes case for missed jobs). Foreground routing is a no-op where it should interrupt with a route push. UX impact: a technician with the app open who receives a job offer sees nothing happen until they background and re-foreground (FCM drain on resume) OR manually navigate. For an Android-only marketplace where technicians plausibly keep the app open while waiting for jobs, this is non-trivial debt — but not a launch blocker because the killed-state path is the dominant real-world case.

---

## ~~12. `EventLog.payload` stored the entire envelope, doubly-nesting every sync-replayed event~~ ✅ Resolved (2026-05-01)

Resolved by storing the *inner* feature payload only. The serializer rebuilds the envelope shell from row columns plus a `SerializerMethodField`, so `/api/events/sync/` and `/api/events/unacknowledged/` output now matches the §1.2 single-envelope wire contract that the WS path was already producing.

**What changed**
- `backend/realtime/events/services/event_dispatch_service.py` — `EventLog.objects.create(..., payload=payload, ...)` (was `payload=envelope`). The narrow comment block above the call documents *why* the inner payload is the right thing to persist.
- `backend/tests/factories/core.py` — `EventLogFactory.payload` is now the inner dict (`{"job_id": "sample-job"}`), not a full envelope.
- `backend/tests/realtime/test_event_dispatch_service.py` — assertion on the persisted row now checks `row.payload == {"job_id": "abc"}` instead of `row.payload["kind"] == "event"`.
- `backend/tests/realtime/test_event_api.py` — `test_sync_returns_only_recent_events_for_current_user` gains three lines pinning the single-envelope contract on the wire: `entry["payload"]` contains no `"kind"` key, no nested `"payload"` key, and equals the original inner payload exactly. This is the regression net for any future change that reintroduces double nesting.
- All 51 tests under `tests/realtime/` and `tests/bookings/services/test_job_request_dispatch.py` pass. No frontend changes needed — every frontend fixture (WS dispatcher tests, FCM handler tests, payload model tests, mapper tests) already used the single-envelope shape because that has always been the documented wire contract; the backend was the side that diverged.

**How it surfaced**
Found while diagnosing flag #11. The user remembered seeing a doubly-nested `payload{payload{}}` shape in some log; the actual location was `EventLog.payload`, not the WS wire (which was always single-enveloped via `_push_to_channel_layer`). Live foreground events worked fine; only sync replay (cold start, reconnect, `_onResumed`) was broken — every replayed `job_new_request` failed `JobNewRequestPayloadModel.fromJson` because the inner payload's `job_id` was buried at `event.payload['payload']['job_id']` instead of `event.payload['job_id']`. The mapper's silent-drop policy masked the failure — flag #11's GoError was the visible symptom.

**Migration note**
Existing `EventLog` rows in the dev DB are still doubly enveloped. For development, the cleanest reset is `EventLog.objects.all().delete()` (no production users). For production parity (when it matters), a one-shot migration: `for row in EventLog.objects.iterator(): if isinstance(row.payload, dict) and row.payload.get('kind') == 'event' and 'payload' in row.payload: row.payload = row.payload['payload']; row.save(update_fields=['payload'])`. Idempotent — re-running on already-flat rows is a no-op because the `kind`-key check fails.

---

## ~~13. `daphne` missing from INSTALLED_APPS — `python manage.py runserver` silently 404s every WS handshake~~ ✅ Resolved (2026-05-01)

Resolved by adding `'daphne'` as the very first entry in `INSTALLED_APPS`. Channels 4.x dropped its own `runserver` patch and now requires Daphne to be registered before `django.contrib.staticfiles` for `runserver` to be replaced with the Daphne ASGI runserver. Without it, `runserver` falls back to plain WSGI: HTTP routes work, but every WebSocket upgrade request hits the URL router as an ordinary `GET /ws/events/...` and returns 404 with no obvious diagnostic. The `daphne -b 0.0.0.0 -p 8000 core.asgi:application` CLI invocation continues to work either way (it bypasses `runserver` entirely), which is how the project shipped without anyone noticing — but anyone defaulting to `runserver` (the Django muscle-memory invocation) lost all realtime functionality silently.

**What changed**
- `backend/core/settings.py` — `'daphne'` inserted at index 0 of `INSTALLED_APPS` with an inline comment explaining the requirement and pointing to the symptom.
- No test impact (Channels' channel layer is exercised via `InMemoryChannelLayer` in tests, independent of which ASGI runserver is in front).
- No doc impact — `EVENT_DISPATCH_API.md` describes the wire contract, not the dev-server invocation.

**How it surfaced**
During flag #11 debugging, the user switched from `daphne -b 0.0.0.0 -p 8000 core.asgi:application` to `python manage.py runserver`. The next test run produced `GET /ws/events/?token=... HTTP/1.1 404` (standard Django WSGI log format) instead of the `WSCONNECTING /ws/events/` line (Daphne's format) seen in the previous run. With WS dead, the orchestrator never received frames over the socket — but the test event still reached the device via FCM (Celery → Firebase → `FirebaseMessaging.onMessage`), which is what produced the `D/FLTFireMsgReceiver: broadcast received for message` log line. That FCM-delivered event is what eventually exposed flag #11's GoError.

---

## 14. `Accept` / `Decline` buttons render real UI but make no remote call

**Where**
- `frontend/lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart` — `_handleAccept` and `_handleDecline` both delegate only to `incomingJobQueueProvider.notifier.removeRequest(jobId)`.
- `frontend/lib/features/technician/incoming_job_requests/INCOMING_JOB_REQUESTS_FEATURE.md` — Repository / Use Cases / Data Sources still marked `⏳ pending`.
- Backend: no `POST /api/bookings/{id}/accept` or `/decline` endpoint exists (per `BOOKINGS_API.md` §1.1).

**What's wrong**
The technician sees a polished bottom-sheet UI with `Accept Request` and `Decline` buttons. Tapping either only removes the offer from the local Riverpod queue — there is no HTTP call, no server-side state transition, no SLA-task cancellation, and no customer-facing notification fires. From the server's perspective, the offer simply expires when its SLA timer fires regardless of which button the technician tapped (or whether they tapped at all). This is the technician's most-seen post-online surface shipping without its remote counterpart.

**Why we shipped it anyway**
- The backend acceptance endpoint is its own sprint — the customer-facing `job_accepted` event, payout-stamping at acceptance, and the dispatch-cancel side-effects all need to land together. Holding the visual UI hostage to that sprint blocks the design and UX testing that the sheet's snap behavior, countdown, and queue list need today.
- The visual design is independently load-bearing and is correct in isolation regardless of what the buttons do server-side.
- The local `removeRequest` matches the queue notifier's existing documented stub contract, keeping dev/QA's felt experience coherent.

**The proper fix (lockstep)**
1. **Backend**: add `POST /api/bookings/{id}/accept` and `/decline` endpoints under `bookings/api/`. Both run inside `transaction.atomic()` + `select_for_update()` and short-circuit on any non-`AWAITING` status. Accept transitions to `CONFIRMED`, cancels the dispatch SLA Celery task, and emits `job_accepted` to the customer via `EventDispatchService.broadcast_event(...)` in the same transaction. Decline transitions to `REJECTED` and either re-broadcasts to the next-best technician or expires.
2. **Frontend domain**: `AcceptJobRequestUseCase` / `DeclineJobRequestUseCase` + a `JobRequestRepository` interface in `domain/repositories/`. Extend `IncomingJobFailure` (already a sealed hierarchy) with network / server / conflict variants — the `409 already-actioned` path must be modeled because an SLA timeout can fire between the user's tap and the server's processing.
3. **Frontend data**: `JobRequestRemoteDataSource` (Dio) + `JobRequestRepositoryImpl` mapping HTTP failures through the four-step error pipeline in CLAUDE.md.
4. **Sheet host**: `_handleAccept` / `_handleDecline` invoke the use case via Riverpod, surface a SnackBar on failure, and only call `removeRequest` on success (or on a 409 — the offer is already not-actionable from the server's POV either way).
5. **Tests**: new widget tests covering the failure-path UI (Snackbar surfaces, the offer remains in the queue so the technician can retry).

**Search hints**
- `_handleAccept`, `_handleDecline` in `incoming_job_sheet_host.dart`
- `removeRequest` in `incoming_job_queue_notifier.dart`
- `BOOKINGS_API.md` §1.1
- `IncomingJobFailure` sealed class in `frontend/lib/features/technician/incoming_job_requests/domain/failures/`

---

## 15. `CustomerAddress` structured locality fields are client-supplied — backend trusts them verbatim

**Where**
- `backend/customers/api/addresses/serializers.py` — `CustomerAddressWriteSerializer.Meta.fields` whitelists `neighborhood`, `suburb`, `city`, `state`, `country`, `postal_code`, `locality_label` as optional client-writable fields.
- `backend/customers/services/address_service.py` — `create_customer_address` / `update_customer_address` pass `**validated_data` straight to `CustomerAddress.objects.create`/`setattr` with no verification.
- `backend/customers/api/ADDRESSES_API.md` — documents the client-supplied contract.
- `frontend/lib/features/customer/addresses/data/models/place_details.dart:localityLabel` — the only place the compose rule (`"{suburb}, {city}"`) lives; backend doesn't know it.

**What's wrong**
CLAUDE.md mandates *"All incoming data sanitized at Serializer level. Never trust Flutter app input."* This work deliberately departs from that rule for the 7 structured locality fields. The Flutter map-picker reverse-geocodes via Google (prod) or OSM Nominatim (dev), then POSTs the structured pieces to the backend, which stores them verbatim. A modified client could send `city = "Karachi"` while picking a Lahore coordinate — the backend would persist the lie.

**Why we shipped it anyway**
- These fields are **display-only**. `latitude`/`longitude` remain the trusted source of truth for distance, matchmaking, and dispatch decisions — none of which read the structured strings.
- The session decision was "client-side reverse-geocoding entirely; backend is dumb storage" (the alternative was an in-process server-side OSM/Google call on every POST/PATCH, which adds latency, cost, rate-limit complexity, and a second provider that can disagree with the client's answer).
- The threat model is "user lies about their own neighborhood string for vanity," not a security boundary. No payment, dispatch, or auth flow depends on these strings.
- Compose rule lives client-side (one source of truth with the geocoder). Future consumers (e.g. `job_new_request` payload) read the cached `locality_label` column rather than re-composing.

**The proper fix (only if abuse appears or a non-display consumer needs structured trust)**
1. Add a server-side `verify_locality_consistency(lat, lng, claimed_country, claimed_state)` selector in `customers/selectors/` that calls Google Geocode with admin credentials and rejects writes whose claimed country/state don't match the lat/lng. The granularity stops at country/state — neighborhood-level verification is too noisy for both providers.
2. Wire it into the service via `transaction.on_commit` async work (Celery task + Port-and-Adapter, mirroring `bookings/services/job_request_dispatch.py`) so the API response stays fast.
3. Move the `localityLabel` compose rule to the backend (a `_compose_locality_label` helper in `address_service.py`) and stop accepting it from the wire. Frontend stops sending it; mapper drops the field.

**Search hints**
- `_LOCALITY_FIELDS` in `customers/api/addresses/serializers.py`
- `class PlaceDetails` and `String? get localityLabel` in `frontend/lib/features/customer/addresses/data/models/place_details.dart`
- `TestStructuredLocalityFields` in `tests/customers/api/addresses/test_api.py`

---

## 16. `GOOGLE_MAPS_API_KEY` absent silently falls back to Nominatim — TOS-violation footgun in prod

**Where**
- `frontend/lib/features/customer/addresses/presentation/providers/dependency_injection.dart` — `geocodingDataSource(Ref ref)` factory.

**What's wrong**
The factory chooses the geocoding adapter at build time:
```dart
const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
return apiKey.isEmpty ? NominatimGeocodingDataSource(client) : GoogleMapsGeocodingDataSource(client, apiKey);
```
If a release build forgets `--dart-define=GOOGLE_MAPS_API_KEY=...`, the app silently uses OSM Nominatim. OSM's [public tile/Nominatim usage policy](https://operations.osmfoundation.org/policies/nominatim/) **forbids production-scale use** — 1 req/sec hard cap, mandatory descriptive User-Agent, free-tier IPs get banned for sustained traffic. The trap is asymmetric: dev works, the release ships, the IP eventually gets rate-limited or banned, customers can't save addresses, root cause is invisible from logs (no exception, just slow/empty geocode results).

**Why we shipped it anyway**
- The factory pattern was the cleanest swap mechanism for "dev uses OSM, prod uses Google" — the alternative (paid Google key in dev) would force every contributor to obtain billing credentials before they could run the app.
- We aren't shipping to prod yet, so the trap isn't sprung today.
- A `kDebugMode` warning is logged when the OSM fallback fires, so dev-time visibility exists.

**The proper fix (before first prod build)**
1. Replace the silent fallback with a hard release-mode assertion in `geocodingDataSource`:
   ```dart
   if (apiKey.isEmpty) {
     assert(!kReleaseMode, 'GOOGLE_MAPS_API_KEY required for release builds — Nominatim is dev-only.');
     return NominatimGeocodingDataSource(client);
   }
   ```
   `assert` is no-op in release, so we'd actually need `if (kReleaseMode && apiKey.isEmpty) throw StateError(...);` — pick one and stick to it.
2. Alternative: gate the choice on a separate `--dart-define=GEOCODING_PROVIDER=google|osm` so the selection is intentional rather than inferred from key-presence. Defaults to `google` in release, `osm` in debug.
3. Either way: add a CI check that release builds carry the dart-define (grep the build args).

**Search hints**
- `geocodingDataSource(Ref ref)` in `dependency_injection.dart`
- `NominatimGeocodingDataSource` and `GoogleMapsGeocodingDataSource` in `data/data_sources/`

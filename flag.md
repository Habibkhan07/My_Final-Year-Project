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

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

## ~~6. `IncomingJobQueueNotifier` — append-only queue, no expiry sweep~~ ✅ Resolved (2026-05-02)

Resolved by the serialized one-offer pivot. The pivot's swipe-to-accept widget owns the wall-clock countdown for the head offer; when its drain reaches zero it fires `onExpire`, the host calls `removeRequest(headId)`, and the head pops — exactly the eviction event the proposed sweep timer would have produced. For tail entries, `removeRequest` now filters out already-expired entries before promoting the next head, so an expired tail entry is dropped at the moment of head resolution rather than briefly promoting → firing onExpire → popping (a visible flicker).

**What changed**
- `frontend/lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_swipe_to_accept.dart` — new widget. Owns the head's drain via a 250ms wall-clock `Timer.periodic` (wall-clock, not frame count, so backgrounding mid-drain still produces correct remaining-time on resume). Calls the host's `onExpire` callback once when remaining reaches zero; freezes thereafter.
- `frontend/lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart` — adds `_handleExpire(jobId)`, semantically distinct from `_handleDecline` so the future accept-endpoint sprint can wire different remote behavior (decline POSTs `/decline`; expire is a no-op because the server's SLA-timeout Celery task fires authoritative).
- `frontend/lib/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart` — `removeRequest` now (a) filters expired tail entries out before promoting the next head, and (b) re-sorts surviving tail entries by current urgency (`remaining/slaWindow` ascending) before promotion. Pinned by new `incoming_job_queue_notifier_test.dart` cases under "head-sticky priority ordering".

**Out of scope, still deferred** — a periodic sweep that runs even when no UI consumer is mounted is not added. The new bound on stale memory is: head is evicted exactly when its drain hits zero (250ms granularity); tail entries that expired while waiting are dropped on the next head resolution. For an Android-only app where the sheet is mounted whenever the technician is online, this is tighter than the original "stale until app restart" bound by orders of magnitude. If a sweep that survives sheet-unmounted-but-app-foregrounded ever proves necessary, the place to add it is `IncomingJobQueueNotifier.build()` with `Timer.periodic` and `ref.onDispose(timer.cancel)` — but not pre-emptively.

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

## ~~14. `Accept` / `Decline` buttons render real UI but make no remote call~~ ✅ Resolved (2026-05-03)

**What changed**
- **Backend**: `POST /api/bookings/<id>/accept/` and `/decline/` shipped under `backend/bookings/api/job_actions/{views,serializers}.py` + service `backend/bookings/services/job_request_action.py`. Both run inside `transaction.atomic()` + `select_for_update()`, scope by `(pk, technician__user)` (IDOR-safe 404 collapse), and treat same-tech retries on the terminal status as idempotent success (no duplicate event emit). Accept → `CONFIRMED` + emits `job_accepted` to the customer on commit. Decline → `REJECTED` + emits `booking_rejected` (`reason: "technician_declined"`) on commit. Contract documented as §1.3 / §1.4 in `BOOKINGS_API.md`.
- **SLA cancellation**: no explicit revoke. The Celery SLA task's existing `status != AWAITING → no-op` guard makes it a harmless no-op once accept/decline commits (decision logged in service-layer docstring).
- **Frontend**: full 4-step error pipeline. `IIncomingJobRepository` + `Accept` / `Decline` use cases (`domain/`), `IncomingJobRemoteDataSource` + `IncomingJobRepositoryImpl` with `_mapFailure` switch (`data/`), `JobActionResult` sealed type + `inFlightJobIds` queue state + `accept` / `decline` notifier methods + sheet-host `_surfaceResult` switch (`presentation/`). `IncomingJobFailure` extended with `IncomingJobNetworkFailure` / `IncomingJobServerFailure`, `OfferNoLongerAvailable` carries `currentStatus` echoed from the 409 envelope. In-flight set gates double-tap and `_handleExpire`.
- **Tests**: 59 backend (service + API), 28 new frontend (datasource + repo + notifier actions + host wiring snackbar/Retry/in-flight).
- **Wire-name reconciliation with flag #22**: the technician-decline path emits `booking_rejected` (matching #22's prescribed event-type) with `payload.reason = "technician_declined"`. The SLA-expiry arm of #22 will reuse the same envelope with `reason: "sla_timeout"`.

**Carry-over (not closed by this commit)**
- The customer-side handler for `job_accepted` and `booking_rejected` is missing — see flag #22 (extended below) and the new `job_accepted`-handler entry that follows.

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

---

## ~~17. `expires_in_seconds` has no server-side floor — swipe-to-accept drain assumes ≥ 5 minutes~~ ✅ Resolved (2026-05-03)

Resolved by adding `MIN_DISPATCH_SLA = timedelta(minutes=5)` to `bookings/services/job_request_dispatch.py` and flooring `expires_in` at the dispatch site — `max(int(MIN_DISPATCH_SLA.total_seconds()), expires_in)` — after the existing two-tier computation. The same floored value feeds both `EventDispatchService.broadcast_event(expires_in_seconds=...)` and `JobDispatchScheduler.schedule_sla_timeout(delay_seconds=...)`, so the wire countdown the technician sees and the server-side Celery SLA timer stay locked together by construction. No second constant in `tasks.py` (which would re-create the drift risk the flag warned about); single source of truth at the dispatch site.

**What changed**
- `backend/bookings/services/job_request_dispatch.py` — added `MIN_DISPATCH_SLA = timedelta(minutes=5)` near the existing tier constants with a comment explaining why the floor lives at the dispatch site (it is a wire contract for the technician swipe-to-accept UI) rather than inside `compute_dispatch_timer_seconds` (the pure tier function still returns raw 60 / 900 for any future caller). One-line floor inside `dispatch_job_new_request_event`. In practice the ASAP tier (60s) is lifted to 300s on the wire; the Scheduled tier (900s) is unchanged.
- `backend/bookings/api/BOOKINGS_API.md` §1.2 — renamed the table column header to `expires_in_seconds (raw)` and added a **Hard wire floor** paragraph below pinning the 5-minute minimum as a documented contract any future per-booking-type policy or non-Flutter client must respect.
- `backend/tests/bookings/services/test_job_request_dispatch.py` — new `TestMinDispatchSlaFloor` class with four cases (ASAP floored to 300, Scheduled unchanged at 900, scheduler armed with the floored value, pure tier function deliberately still returns raw values). Updated `test_arms_scheduler_with_matching_expires_in_seconds` so its within-2h assertion expects the floored value; the matching-equality half (wire == scheduler `delay_seconds`) is preserved as the actual contract under test.

**Not in scope** — the per-booking-type SLA policy mentioned as a hypothetical in the flag prose. The floor is the deliverable; any future per-type policy now inherits the floor automatically.

---

## 18. New-offer audio cue is a placeholder system sound

**Where**
- `frontend/lib/features/technician/incoming_job_requests/presentation/services/incoming_job_sound_player.dart` — interface + placeholder implementation.
- `frontend/lib/features/technician/incoming_job_requests/presentation/providers/dependency_injection.dart` — provider binding.
- `frontend/lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart` — call site inside `_runHeadChangeCeremony`.

**What's wrong**
The vanish-reappear ceremony fires an audio cue when the new head's sheet slides in — one of three redundant signals (sound + heavy haptic + slide-in animation) that together make a new offer unmistakable to a technician who might be looking away, in a pocket, in a noisy environment, or with the device silenced. The cue today is `SystemSound.play(SystemSoundType.alert)`: Flutter's built-in stock alert tone. It works (zero dependency, respects silent / vibrate mode), but the audible output is the device's standard alert sound — not distinct from any other system notification the technician might already be receiving. A custom chime tuned for "incoming job offer" would read more clearly as an in-app event and reduce the chance of a tech tuning it out alongside background notifications.

**Why we shipped it that way**
The vanish-reappear ceremony was scoped to land in one frontend session — wiring the four cases of `_onQueueChanged`, the slide-out / pause / slide-in choreography, plus haptic + sound. Adding a real audio asset alongside that scope would have required an `audioplayers` (or similar) dependency, an asset added to `pubspec.yaml`, sound design / sourcing, and a license check on the chosen file. The placeholder gets the architecture right (interface + injectable provider) so the swap is trivial when the chime is ready; doing it inline would have stretched the session.

**The proper fix**
1. Pick a chime — short (≤1s), pleasant, distinct from common system notification sounds. Sources: `freesound.org` (CC0 / CC-BY), `mixkit.co` (royalty-free, no account), `pixabay.com/sound-effects` (royalty-free, no account). Candidate search terms: `notification`, `chime`, `bell`, `incoming`. Verify the license; for any non-CC0 source, record attribution in the project README or a `THIRD_PARTY.md`.
2. Add `audioplayers: ^X.Y.Z` to `frontend/pubspec.yaml`. Drop the file at `frontend/assets/sounds/incoming_job_chime.wav` (or `.mp3`); register the directory under `flutter.assets`.
3. Implement `AssetIncomingJobSoundPlayer` in the same file as the abstract `IncomingJobSoundPlayer`. Cache the `AudioPlayer` instance per app-level singleton (creating one per call leaks file handles); preload the asset on construction so the first cue doesn't lag.
4. In `dependency_injection.dart`, swap the `incomingJobSoundPlayerProvider` binding from `SystemSoundIncomingJobSoundPlayer()` to the new asset implementation. Verify the existing host code doesn't change at all — it reads through the provider.
5. Test: in the preview lab (`flutter run -t lib/preview/incoming_job_preview.dart`), seed two offers and accept the first; the chime should play during the slide-in. If `audioplayers` requires platform setup (Android `<uses-permission>` or iOS `Info.plist` keys for media playback), confirm those before merging.

**Search hints**
- `IncomingJobSoundPlayer` abstract class — the seam.
- `SystemSoundIncomingJobSoundPlayer` — the placeholder to delete (or keep behind a debug flag for testing).
- `_runHeadChangeCeremony` in `incoming_job_sheet_host.dart` — the call site, which doesn't change.
- `incomingJobSoundPlayerProvider` in `presentation/providers/dependency_injection.dart` — single line to swap.

**Severity**
Low. The placeholder is functional — the cue plays, respects silent mode, and combined with the heavy haptic + slide-in animation the new-offer signal is already redundant. The upgrade is a polish step, not a correctness fix. Pick up when the team commits to a sound design pass for the technician app.

---

## ~~19. Wire envelope lacks `expires_at` and `recipient_user_id` — frontend filters at the feature level instead of the pipeline~~ ✅ Resolved (2026-05-03)

Resolved by emitting both fields from `EventDispatchService.broadcast_event` and denormalizing `expires_at` onto `EventLog` so /sync/ replay surfaces the same UTC instant the original WS frame carried — no recomputation, no clock drift between dispatch and replay. The frontend pipeline filters (already shipped under the rollout-window contract) activate automatically; the multi-account recipient filter further requires the auth chain to expose a numeric user id, also wired in this change.

**What changed**

*Backend*
- `EventDispatchService.broadcast_event` accepts an explicit `expires_in_seconds: int | None = None` kwarg. Pins one UTC `now` for both `envelope["timestamp"]` and `envelope["expires_at"]` so the wire string and the persisted row reference the same instant. `recipient_user_id` is set unconditionally from `user.id`. `broadcast_to_multiple` forwards the kwarg.
- `bookings.services.job_request_dispatch` passes `expires_in_seconds=expires_in` to the new kwarg. The existing `expires_in_seconds` inside `payload` is preserved during the rollout window for backwards compat.
- `EventLog.expires_at` denormalized column added (`realtime/migrations/0002_eventlog_expires_at.py`, nullable, no backfill — pre-flag rows replay as null). Single source of truth: dispatcher writes it once; serializer reads it verbatim.
- `EventLogSerializer` exposes `recipient_user_id` (sourced from `user_id`) and `expires_at` (model field).
- `accounts.services.auth_service.process_otp_verification` now returns `user_id`. `VerifyOTPView.OutputSerializer` declares it. The frontend orchestrator consumes this to override `currentAuthUserIdProvider`.
- Tests: `test_event_dispatch_service.py` adds `test_envelope_includes_recipient_user_id`, `test_envelope_expires_at_is_null_without_sla`, `test_envelope_expires_at_is_anchored_at_dispatch` (asserts `exp - ts == timedelta(seconds=300)` and the row matches), `test_broadcast_to_multiple_propagates_expires_in_seconds`. `test_event_api.py` extends the sync-replay test to assert both fields and adds `test_sync_replay_preserves_expires_at_instant`. `test_auth_service.py` and `test_api.py` lock in the `user_id` field on the verify-otp response.

*Frontend*
- `UserEntity` and `UserModel` gain `int? id`. `UserModel.fromJson` reads the wire field `user_id`.
- `main.dart`'s `bootApp` ProviderScope overrides `currentAuthUserIdProvider` with `ref.watch(authProvider.select((async) => async.value?.user?.id))` — the sanctioned core ↔ features bridge described in `core/realtime/presentation/providers/dependency_injection.dart`. The override `select`s on the id specifically so unrelated AsyncValue transitions don't re-run it.
- `EVENT_DISPATCH_API.md` flipped from "Backend emission is pending" to live; the example envelope now shows non-null values.
- `_wrapAppRoot` in the boot widget test mirrors the production override so widget tests run against a faithful environment. New tests W9 (cached user with id=42 → `currentAuthUserIdProvider` returns 42) and W10 (no cached user → null) lock in the chain. New auth-repo tests pin `UserModel.fromJson` reading `user_id` and tolerating its absence (legacy cache compat).

**Defence-in-depth retained** — `JobNewRequestMapper`'s feature-level freshness check stays in place. Two staleness gates on different layers is intentional for a privacy-adjacent path.

**Migration story** — backwards-compat held throughout. Pre-flag `EventLog` rows have `expires_at = null` and replay unchanged. Older clients that ignore the new envelope fields still parse the wire payload (the optional Freezed fields tolerate null). Older `UserModel.fromJson` cached responses without `user_id` produce a null `id`, which keeps the recipient filter dormant — exactly the documented null-half no-op path.

---

## ~~20. No specific error code for "booking is no longer available" — accept-just-past-expiry surfaces as a generic validation error~~ ✅ Resolved (2026-05-03)

**What changed**
Closed alongside flag #14. The accept and decline views (`backend/bookings/api/job_actions/views.py`) return `409 booking_no_longer_available` when the booking is no longer in `AWAITING` and the request is not the same-tech idempotent repeat. Two intentional tweaks vs the original prescription:
- **Status code is 409, not 400.** The error is a state-conflict on the server, not a malformed-request issue — `409 Conflict` is the more REST-correct mapping. The frontend's `_mapFailure` keys on `code` not status, so the wire-code stays the agreed-upon `"booking_no_longer_available"`.
- **`errors.current_status` carries the live row state**, not `errors.booking`. Cleaner shape for client mapping (`["REJECTED"]` / `["CANCELLED"]` / `["CONFIRMED"]` etc.), still useful for telemetry/debugging. Documented in `BOOKINGS_API.md` §1.3.

Frontend side: `OfferNoLongerAvailable` carries the optional `currentStatus` field echoed from the envelope. `_mapFailure` in `incoming_job_repository_impl.dart` handles both the 409 path and the IDOR-collapsed 404. Pinned by `incoming_job_failure_test.dart` and `incoming_job_repository_impl_test.dart`.

---

## 21. No FCM data-field size validation — > 4 KB silently drops the push

**Where**
- `backend/realtime/events/services/event_dispatch_service.py` — `broadcast_event` queues the FCM task without checking the serialized envelope size.
- `backend/realtime/devices/tasks.py` — `send_fcm_notification` calls `_stringify` to flatten the envelope and ships it as the FCM data field.

**What's wrong**
FCM enforces a 4 KB limit on the data field. The backend has no assertion on serialized envelope size, so a sufficiently long `service_name` + `payout_context` + `ui_location_label` (or any future feature payload) can push the envelope over the limit. Firebase silently drops the message — no error, no log surfaces, the technician simply never sees the notification. Diagnosing this in production after the fact is hard because every relevant log line says "FCM dispatched successfully" (the Celery task succeeded; Firebase's SDK accepted the request and only later, server-side, rejected the data-too-large frame).

Today's payloads are well under the limit (~400–800 bytes) but there's no guard rail. A future feature — a chat message, a long invoice description, a multi-stop technician route — can trip it without any visible warning at code-review time.

**Why we shipped it anyway**
Practical envelope sizes today are far below the limit; the bug surface is theoretical. The cost of writing the assertion plus the truncation/fallback logic was higher than the immediate risk during the realtime pipeline build-out.

**The proper fix**
1. In `EventDispatchService.broadcast_event`, after constructing the envelope and BEFORE queuing the FCM task: `serialized = json.dumps(envelope); if len(serialized.encode('utf-8')) > 3800: ...`. Headroom of 296 bytes covers FCM's per-key encoding overhead.
2. On overflow, two reasonable strategies:
   - **Truncate.** Replace long display fields with a "…" suffix until the envelope fits. Risk: arbitrary-looking truncation in production; user might see "Plumbing Inspection at Gulber…" instead of the full address.
   - **Minimal-envelope fallback.** Replace the data field with `{kind, id, rawType, recipient_user_id}` only. The FCM tap-intent on the device fetches full details via `/api/realtime/events/sync/?since=...` immediately on app foreground. Tradeoff: tray notification's body text would be the registry's `display_name` instead of feature-specific text, but the technician still gets notified.
3. Either way: log a warning so ops sees the event size growing toward the limit.

**Search hints**
- `broadcast_event` in `event_dispatch_service.py`
- `_stringify` in `realtime/devices/tasks.py`
- `EVENT_REGISTRY` in `realtime/constants/event_types.py` — `display_name` for the minimal-envelope fallback body.

**Severity**
Low today, latent. Track it before adding any feature whose payload is realistically variable-length (chat content, multi-line addresses, free-form notes). The cost to fix later (with no telemetry showing it actually happened) is much higher than the cost to add the assertion now.

---

## ~~22. Customer is not notified when their booking is rejected (SLA arm pending; customer-side handler missing)~~ ✅ Resolved (2026-05-04)

**What changed.** Both arms now lit up end-to-end.
- Backend: `expire_pending_job_booking` (`bookings/tasks.py`) now emits `booking_rejected` on commit with `reason="sla_timeout"`, reusing the shared `_emit_booking_rejected(booking, reason=...)` helper that the technician-decline arm also calls. Helper signature refactored: `reason` is now a required kwarg, single source of truth across both pathways. SLA task gained `select_related("customer", "service", "sub_service")` so the FK accesses inside the helper don't fire extra queries.
- Backend registry: `EVENT_REGISTRY[BOOKING_REJECTED]` flipped to `is_critical=False`. The customer notification is informational — `EventLog` persistence + sync-replay cover offline cases without the per-event ACK contract that `is_critical=True` would have demanded. The `True` was a thoughtless mirror of the other booking events when flag #14 shipped; this corrects it.
- Frontend: `SystemEventType.bookingRejected` enum case + `_lookup` entry. `event_urgency.dart` maps it to `lowUrgency`. `event_criticality.dart` deliberately does NOT include it (matches backend flip).
- Frontend router: `EventUrgencyRouter` extended with `_lowUrgencyTapPayloadKeys: Map<SystemEventType, String>` mirroring the existing high-urgency `_navGuardPayloadKeys` shape. `_resolveLowUrgencyPath` substitutes `:<payload-key>` tokens in the route template. `bookingRejected` entry: `'job_id'` → `/customer/booking/:job_id`. Banner icon (`event_busy`), title (`Booking unavailable`), and reason-discriminated body copy added (`technician_declined`, `sla_timeout`, fallback for unknown future reasons).
- Frontend route: `/customer/booking/:job_id` registered in `app_router.dart`, pointing at `CustomerBookingDetailScreen` — a placeholder that displays the booking id with a "Detail screen coming soon" note. The rich detail UI is deferred to a new sprint (see new flag #26).
- Tests: backend SLA emit (5 new tests in `test_tasks.py::TestExpireEmitOnCommitSemantics` covering payload shape with `reason="sla_timeout"`, non-emit on non-AWAITING / missing booking, idempotency, on_commit rollback suppression). Frontend banner copy (3 reason variants), tap-target substitution (with + without payload key), regression for existing static-path low-urgency events (6 tests in new `event_urgency_router_test.dart`).
- Docs: `BOOKINGS_API.md` §1.4 now lists both `reason` values in a per-arm table; `is_critical=false` documented. `INCOMING_JOB_REQUESTS_FEATURE.md` "Known limitations" updated — `booking_rejected` removed from the unmounted-customer-handler line.

---

> **Original entry preserved below for context. The proper-fix section is partially superseded — flag.md is append-only after resolution.**

> **Updated 2026-05-03 (flag #14 close).** The technician-decline arm of `booking_rejected` is now shipped (see flag #14 resolution). The wire string, event-type registry entry, payload shape, and `display_name` listed in the proper-fix below are now live. **Two arms still pending:** (a) the SLA-expiry path (`expire_pending_job_booking`) does not emit, and (b) the customer-side Flutter handler doesn't subscribe — so even the now-emitted technician-decline event lands in the customer's `SystemEventNotifier` unobserved (FCM tray push will fire generically; in-app surface does nothing).

**Where**
- `backend/bookings/tasks.py` — `expire_pending_job_booking` flips `AWAITING → REJECTED` but does not call `EventDispatchService.broadcast_event(...)`. (The technician-decline twin in `backend/bookings/services/job_request_action.py::decline_job_booking` *does* emit, as of flag #14.)
- `frontend/lib/core/realtime/domain/entities/system_event_type.dart` — no `bookingRejected` enum case yet (only `jobAccepted` and the rest of the pre-flag-#14 set).
- `frontend/lib/features/customer/` — no `BookingRejectedNotifier` or equivalent customer-status feature consuming the event.
- Cross-references flag #1 (booking acceptance model) and flag #19 (wire envelope contract).

**What's wrong**
When the technician's accept SLA fires server-side and the booking flips `AWAITING → REJECTED`, no event is dispatched to the customer. The customer's UI sits on "Waiting for technician…" indefinitely until they navigate away or refresh the booking detail manually. In the worst case the customer waits 5 minutes (current SLA) for a confirmation that's never coming, then has to re-enter the discovery flow without any prompt that something went wrong.

When the technician explicitly declines (the case shipped by flag #14), `booking_rejected` IS emitted but the customer's frontend has no subscriber — so the FCM tray notification surfaces with the registry's generic `display_name="Booking unavailable"`, the in-app socket frame is dropped silently into `SystemEventNotifier`, and the customer's "Waiting for technician…" surface still sits there until they manually refresh.

**Why we shipped it anyway**
The customer-side surface that consumes `booking_rejected` ("Waiting for technician → Job rejected → re-pick") is its own design problem. Holding the technician-decline backend emit hostage to that sprint blocked flag #14, so we shipped the emit alone — durable in `EventLog`, FCM still fires, customer-side will catch up when its handler lands. The SLA-expiry emit was deferred to bundle with the customer-side handler so the lockstep happens once.

**The proper fix (remaining arms)**
1. **Backend (SLA arm).** In `expire_pending_job_booking`, after flipping status to `REJECTED`, call `EventDispatchService.broadcast_event(user=booking.customer, target_role='customer', event_type=EventType.BOOKING_REJECTED.value, payload={**_build_rejected_payload(booking), 'reason': 'sla_timeout'})`. Reuse the payload shape from `bookings/services/job_request_action.py::_build_booking_rejected_payload` (refactor it into a shared helper or duplicate the five fields — both are small). Use `transaction.on_commit` to mirror the technician-decline emit's ordering. ✅ The registry entry (`EventType.BOOKING_REJECTED`, `display_name='Booking unavailable'`, `is_critical=True`) is already live from flag #14 — no registry edit needed.
2. **Frontend.** Per-event feature wiring (CLAUDE.md → "Per-event feature wiring"):
   - Add `bookingRejected` to `SystemEventType` enum + `_lookup` map in `frontend/lib/core/realtime/domain/entities/system_event_type.dart`.
   - Build `features/customer/booking_status/` (or wherever the waiting UI lives) with payload model, mapper, `BookingRejectedNotifier` (`@Riverpod(keepAlive: true)`) listening via `ref.listen(systemEventProvider, ...)`, filtering by `SystemEventType.bookingRejected`. Surface a modal: "This technician is no longer available. Choose someone else." with a button back into discovery. The `payload.reason` discriminates copy (`technician_declined` vs `sla_timeout`).
   - Register the queue notifier in `realtimeBootHooksProvider` (bottom of `app_lifecycle_orchestrator.dart`) so it wakes before the WS connect cascade.
3. **Frontend (urgency tier — open question).** Add `booking_rejected` to the `EventUrgency` map in `event_urgency.dart`. The natural primary surface is the in-place update on the customer's "Waiting for technician…" screen via the per-event subscriber from step 2 — that handles the common case (customer is already on the relevant screen) regardless of urgency tier. The urgency tier only governs the fallback when the customer is **not** on that screen (backgrounded the app, navigated to another feature, tapped a stale FCM push later). Trade-off:
   - **`lowUrgency` (`MaterialBanner`, recommended default).** "Your booking is no longer available — tap to find someone else." Closest analog in the existing map is `paymentReceived` — informational status the user wants to know about but doesn't strictly need to be yanked into. Polite; respects whatever the customer was doing.
   - **`highUrgency` (`GoRouter.push`).** Force-pushes the customer to the booking detail / re-pick surface. Defensible — they DO need to act — but feels punitive when they didn't do anything wrong (the tech declined). Closer to `jobCompleted`'s "you must rate" semantics, which may be the wrong analog here.
   The implementing sprint should pick one and add to the corresponding map (`_lowUrgencyTapRoutes` + `_bannerIcons` + `_bannerTitles` + `_bannerBody`, OR `_highUrgencyRoutes` + `_navGuardPayloadKeys`). The `payload.reason` discriminator should drive copy regardless of tier.
4. **Tests.** Backend test on the timeout task's event emission; frontend test on the notifier's filter + UI surfaces. The `reason` discriminator branching needs coverage for both `technician_declined` and `sla_timeout`.

**Search hints**
- `expire_pending_job_booking` in `backend/bookings/tasks.py`
- `decline_job_booking` in `backend/bookings/services/job_request_action.py` — the canonical emit shape to mirror
- `EventType.BOOKING_REJECTED` in `realtime/constants/event_types.py` — registry entry is live
- `SystemEventType` enum in `frontend/lib/core/realtime/domain/entities/system_event_type.dart`
- `EventUrgencyRouter._highUrgencyRoutes` in `event_urgency_router.dart`
- `realtimeBootHooksProvider` at the bottom of `app_lifecycle_orchestrator.dart`

**Severity**
Medium. Until this lands, the customer's only recovery path on a tech timeout OR a tech decline is to navigate manually. For a marketplace where the SLA window is short (5 minutes) and the next dispatch needs to happen quickly to maintain a high acceptance rate, the silence is a real conversion drag.

---

## 23. SLA-expired tray notifications stay in the tray until the technician clears them manually

**Where**
- `backend/bookings/tasks.py` — `expire_pending_job_booking`. After flipping booking to `REJECTED`, no FCM cancel-message is sent.
- `backend/realtime/devices/tasks.py` — would need a second task `send_fcm_cancel_notification` (or a flag on the existing `send_fcm_notification`) that sends a data-only push with a collapse key matching the original notification's tag.

**What's wrong**
When a technician misses the SLA window, the booking flips to `REJECTED` server-side but the FCM banner that announced the original `job_new_request` stays in the OS tray. The technician can tap that banner an hour later. Today the frontend's mapper-level filter (flag #19 stopgap) and the planned pipeline filter (flag #19 proper) both drop the event silently — so the tap launches the app to its default surface (technician home) with no sheet — but the dead notification cluttering the tray is itself a UX nit. The technician has to swipe it away manually to clear it; the app gives them no signal that the offer is gone.

**Why we shipped it anyway**
FCM doesn't natively support "cancel a previously-sent notification on the receiving device" as a server-initiated action. The workaround is to send a follow-up data-only message that REPLACES the original via Android's `tag` field (or iOS's `apns-collapse-id`). That's a small but real piece of work that requires touching the FCM dispatch flow, which the SLA-timeout sprint left for later.

**The proper fix**
1. **Backend.** Add a `notification_id` (deterministic — e.g., `f"job_dispatch_{booking.id}"`) to every FCM notification's Android tag / iOS collapse-id. Use the same id when canceling.
2. **Backend.** When `expire_pending_job_booking` fires, queue a follow-up FCM task that ships an empty/replacement notification with the same tag/collapse-id. Android's notification manager replaces the original with the new (effectively empty) one; on iOS the collapse-id consolidates them.
3. **Alternative.** Use a data-only FCM message (no `notification` field) carrying a `cancel_notification: <id>` directive that the foreground handler interprets to call `FlutterLocalNotificationsPlugin.cancel(<id>)`. Risk: works only if the app is alive when the cancel arrives; for a killed app, the data-only message is queued but never processed. The tag/collapse-id approach works regardless of app state — it's purely OS-level.

**Search hints**
- `expire_pending_job_booking` in `bookings/tasks.py`
- `send_fcm_notification` in `realtime/devices/tasks.py`
- `notification_channels.dart` — the existing `job_dispatch` channel.

**Severity**
Low. Pure UX polish — the staleness filters (flag #19) already prevent dead notifications from doing harm; this is just hygiene. Pick up when there's bandwidth or alongside any other FCM-side work.

---

## 24. Producer-side event idempotency: retries mint new UUIDs

**Where**
- `backend/realtime/events/services/event_dispatch_service.py` line ~78 — `"id": str(uuid.uuid4())` is generated fresh on every `broadcast_event` call.
- Cross-references the frontend's dedup map in `system_event_notifier.dart::_kDedupWindow` which keys exclusively on envelope `id`.

**What's wrong**
`broadcast_event` has no idempotency key. Every invocation — including a logical retry of the same event — creates a new `EventLog` row with a new UUID. The frontend's 24-hour dedup map keys on envelope `id`, so it treats two retries of the same logical event as two distinct events: it processes both, the queue notifier may surface both, and any UI that reacts to the event (toast, sheet push, queue insert) can fire twice.

Today the surface area is narrow because the only production caller — `bookings/services/job_request_dispatch.py::dispatch_job_new_request_event` — is wrapped in `transaction.on_commit`, so a rolled-back transaction doesn't queue a phantom dispatch and there's no retry loop above it. The hole is latent: any future producer that retries on a transient failure (Channels group_send timeout, network blip mid-broadcast, Celery task with `autoretry_for=...`) will silently produce duplicates downstream.

The frontend cannot mitigate this — its dedup map is correct given the contract it's promised. The fix has to live on the producer side.

**Why we shipped it anyway**
No production caller retries today, so the bug is invisible. Adding an idempotency key requires either (a) the caller passing a deterministic key (e.g. `f"job_dispatch_{booking.id}_{attempt}"`) which leaks retry semantics into business code, or (b) a producer-side cache keyed on `(user_id, event_type, payload_hash)` with a short TTL, which is non-trivial to size correctly. Neither was justified by the current call graph during the realtime build-out.

**The proper fix**
1. **Add an optional `idempotency_key` parameter** to `EventDispatchService.broadcast_event`. When provided, the service `get_or_create`s the `EventLog` row using a unique constraint on `(user, idempotency_key)` and short-circuits if a row already exists (re-emitting the same envelope to the channel layer is fine — the frontend's dedup catches the WS-after-DB case).
2. **Schema.** Add `idempotency_key = models.CharField(max_length=128, null=True, blank=True)` to `EventLog` with a partial unique index on `(user, idempotency_key) WHERE idempotency_key IS NOT NULL`.
3. **Caller convention.** Producers that need idempotency derive a deterministic key from their domain primitive. For `dispatch_job_new_request_event`: `idempotency_key=f"job_new_request:{booking.id}"`. Producers that don't pass a key keep the current behavior (fresh UUID each call) — opt-in, not enforced.
4. **Tests.** A unit test on `broadcast_event` verifies that two calls with the same `idempotency_key` produce one `EventLog` row, and a regression test on the dispatch path asserts the key is set.

**Search hints**
- `EventDispatchService.broadcast_event` in `event_dispatch_service.py`
- `EventLog` model in `realtime/models/events.py`
- `dispatch_job_new_request_event` in `bookings/services/job_request_dispatch.py` (canonical caller to migrate first)

**Severity**
Low today, latent. The current call graph has no retry loops, so duplicates can't be produced in production. Track it before adding (a) any Celery `@shared_task` that produces events with `autoretry_for=...`, (b) any service-layer retry decorator, or (c) any producer that runs outside `transaction.on_commit`. The cost to retrofit after a duplicate-event incident in production (UI fired twice, customer charged twice, etc.) is much higher than adding the optional parameter now.

---

## ~~25. Customer-side `job_accepted` handler is missing~~ ✅ Resolved (2026-05-04)

**What changed.** Customer now gets a `MaterialBanner` ("Booking confirmed — `<technician>` is on the way") + FCM tray push the moment their tech accepts. Scope-minimal — no new feature directory, no per-event notifier, no new route — mirroring the flag #22 resolution shape exactly.
- **Backend registry:** `EVENT_REGISTRY[JOB_ACCEPTED]` flipped to `is_critical=False` and `display_name="Booking confirmed"` (was `"Job Accepted"`). Same rationale as flag #22's `BOOKING_REJECTED` flip — `is_critical=True` had been a thoughtless mirror of the technician-side `JOB_NEW_REQUEST` shape; the customer doesn't need to ACK an informational confirmation, and `EventLog` persistence + sync-replay cover offline. The `display_name` rename drops technician-centric language from the customer-facing FCM tray title.
- **Frontend urgency tier:** `event_urgency.dart` flipped `SystemEventType.jobAccepted` from `highUrgency` to `lowUrgency`. The `highUrgency` classification was a stale inheritance from the original event-types modeling that targeted a `/customer/job-accepted` route which never existed in `app_router.dart` — every `job_accepted` arriving today silently no-ops at the router layer. `lowUrgency` matches the doctrine the proper-fix below described as "recommended default": the customer is implicitly waiting; a banner respects whatever else they were doing while a high-urgency push would yank them into a screen they can self-navigate to.
- **Frontend criticality:** `event_criticality.dart` removed `jobAccepted` from `criticalTypes`. The set mirrors the backend `EVENT_REGISTRY` and would have stayed out of sync (the dispatch service auto-reads `is_critical` from the registry, but the frontend's own check is a separate hardcoded set used by `EventUrgencyRouter._handleEvent` to decide whether to ACK). Without this edit the router would have called `eventSyncProvider.notifier.acknowledge(event.id)` for an event the backend treats as non-critical — wasted ACK round-trips.
- **Frontend router:** `EventUrgencyRouter` extended end-to-end:
  - Removed `jobAccepted` from `_highUrgencyRoutes` and `_navGuardPayloadKeys` (its high-urgency wiring was vestigial — pointed at a non-existent route).
  - Added to `_lowUrgencyTapRoutes` (`/customer/booking/:job_id`, reusing the placeholder shipped at flag #22), `_lowUrgencyTapPayloadKeys` (`'job_id'`), `_bannerIcons` (`Icons.event_available`), `_bannerTitles` (`'Booking confirmed'`).
  - `_bannerBody` extended with a `case SystemEventType.jobAccepted:` that uses `payload['technician_display_name']` to render `"<tech> is on the way — tap to view."`, falling through to a generic `"Your technician is on the way — tap to view."` when the field is missing (defensive — the same shape `bookingRejected` uses for unknown reasons).
- **Frontend route:** no change — the `/customer/booking/:job_id` route shipped at flag #22 now serves both events. The placeholder `CustomerBookingDetailScreen` continues to be flag #26's deferred sprint.
- **Tests.** Backend: existing `test_event_log_is_written_before_any_dispatch` assertion flipped to `is_critical is False` (the dispatch service auto-reads from the registry, so the assertion still pins the read-path honesty); new `test_job_accepted_registry_entry_is_informational` directly pins the registry shape so a future toggle-back surfaces as a focused failure. Frontend: 3 new tests — banner copy with `technician_display_name`, banner copy fallback when missing, tap-target substitution into `/customer/booking/<id>`. All 82 backend + 9 router-suite frontend tests pass.
- **Decisions deferred.** The "Per-event feature wiring" doctrine (payload model + mapper + `JobAcceptedNotifier`) was NOT applied here — there is no in-app surface for a notifier to drive (the customer's post-booking flow currently `Navigator.pop`s the review sheet and shows a one-shot snackbar; `review_booking_sheet.dart:39-42`). When flag #26 lands the real `CustomerBookingDetailScreen`, the screen can `ref.watch(systemEventProvider)` and apply `payload` directly, OR a `JobAcceptedNotifier` can be added then to drive richer in-screen state. Either path is additive — the banner ships value today.

**Cross-flag note.** The proper-fix below was written before flag #22 resolved, and it overstates the scope: it called for a fresh `features/customer/active_booking/` feature stack with payload model, mapper, queue notifier, and `realtimeBootHooksProvider` registration. Flag #22's resolution showed that the router-banner surface alone delivers the user-visible win; we mirrored that shape here. The doctrine still applies for future events that need to update durable in-app state — it is not a blanket mandate.

---

> **Original entry preserved below for context. The proper-fix section is partially superseded — flag.md is append-only after resolution.**

**Where**
- `backend/bookings/services/job_request_action.py::accept_job_booking` — emits `job_accepted` to the customer on commit (flag #14 close).
- `backend/realtime/constants/event_types.py` — `EventType.JOB_ACCEPTED = "job_accepted"` registered as `is_critical=True`, `display_name="Job Accepted"`.
- `frontend/lib/core/realtime/domain/entities/system_event_type.dart` — has `jobAccepted` enum case + lookup entry, **but** no feature subscriber consumes it.
- `frontend/lib/features/customer/` — no `JobAcceptedNotifier` or post-acceptance customer surface.
- `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart` — no entry for `job_accepted`.
- `frontend/lib/core/realtime/presentation/app_lifecycle_orchestrator.dart::realtimeBootHooksProvider` — no boot-hook for the (missing) feature.

**What's wrong**
The technician's accept flow now fires `job_accepted` to the customer (durable in `EventLog`, FCM tray push fires, WS frame lands at `SystemEventNotifier`). The customer-side Flutter app has no handler, so:
- The WS frame is processed by `SystemEventNotifier`, dedupe-stored, and dropped — no notifier filters on `SystemEventType.jobAccepted`.
- The FCM tray notification fires with the registry's generic title `"Job Accepted"` and the default body. Tapping it launches the app to its default surface (customer home) with no state change — the customer's "Waiting for technician…" screen still says waiting.
- The customer's perception is still that the booking is unconfirmed until they manually navigate or refresh, exactly the conversion drag flag #22 is also about.

This is the post-confirmation half of flag #22's "the customer doesn't know what happened to their booking" gap. Twin entries because the events are distinct (`job_accepted` is informational/positive; `booking_rejected` is recovery/negative) and the customer-facing UX surfaces will differ — accepted leads into "your tech is on the way" with ETA / tech profile; rejected leads into "pick someone else" / re-dispatch.

**Why we shipped it anyway**
Holding the technician-side accept flow (flag #14) hostage to the customer-side post-acceptance UX would have blocked the technician's most-seen surface for an unrelated design problem. Emitting now means the wire contract is exercised by real test traffic during dev (every dev-environment accept fires the event into `EventLog` + FCM), so the customer-side handler can be built against real envelopes when it lands.

**The proper fix (lockstep with the customer post-acceptance UX)**
1. **Frontend.** Per-event feature wiring (CLAUDE.md → "Per-event feature wiring"):
   - Build `features/customer/active_booking/` (or wherever the post-acceptance surface lives) with:
     - `data/models/job_accepted_payload_model.dart` — Freezed + `fromJson` for the five payload fields documented in `BOOKINGS_API.md` §1.3.
     - `data/mappers/` — wire-string-to-typed-domain (e.g. `scheduled_start_iso` → `DateTime`).
     - `presentation/providers/job_accepted_notifier.dart` — `@Riverpod(keepAlive: true)`, listens via `ref.listen(systemEventProvider, ...)`, filters by `SystemEventType.jobAccepted`. Updates the customer's "Waiting for technician…" surface to "Confirmed — `<technician_display_name>` is on the way" with the resolved entity.
   - Register the queue/state notifier in `realtimeBootHooksProvider` (bottom of `app_lifecycle_orchestrator.dart`) so it wakes before the WS connect cascade — otherwise the first `job_accepted` after login is missed.
2. **Frontend (urgency tier — open question; existing classification is suspect).** `SystemEventType.jobAccepted` is **already** classified as `EventUrgency.highUrgency` in `event_urgency.dart` (line 10) — that decision predates this flag and was inherited from the original event-types modeling. Revisiting it is part of this sprint's scope.
   The primary in-app surface should be the in-place update on the customer's "Waiting for technician…" screen via the per-event subscriber from step 1 — the customer is most likely on that screen at the moment of acceptance, and the screen-level subscriber handles them regardless of tier. The urgency tier only governs the fallback when the customer is **not** on that screen. Trade-off:
   - **`lowUrgency` (`MaterialBanner`, recommended default).** "Your booking was confirmed — tap to view." Closest analog is `paymentReceived` — the customer is aware they booked and is implicitly waiting; an interrupt isn't needed if they're mid-WhatsApp or mid-anything-else. Polite; respects context.
   - **`highUrgency` (`GoRouter.push`, current classification).** Yanks the customer to the booking detail surface. Defensible because they were about to need that screen anyway, but jarring when the FCM push already drew their attention and they can self-navigate.
   If switching to `lowUrgency`, the change is one line in the urgency map plus adding entries to `_lowUrgencyTapRoutes` / `_bannerIcons` / `_bannerTitles` / `_bannerBody`. If keeping `highUrgency`, add entries to `_highUrgencyRoutes` and `_navGuardPayloadKeys` (route to the booking detail screen with `job_id` as the guard key).
3. **Tests.** Frontend mapper / notifier / widget tests on the new surface.

**Search hints**
- `EventType.JOB_ACCEPTED` in `realtime/constants/event_types.py` (registry entry already live)
- `accept_job_booking` in `bookings/services/job_request_action.py` (canonical emit)
- `BOOKINGS_API.md` §1.3 (payload contract)
- `SystemEventType.jobAccepted` in `frontend/lib/core/realtime/domain/entities/system_event_type.dart` (enum case already live)
- `realtimeBootHooksProvider` at the bottom of `app_lifecycle_orchestrator.dart`
- `EventUrgencyRouter._highUrgencyRoutes` in `event_urgency_router.dart`
- Reference impl: `frontend/lib/features/technician/incoming_job_requests/` is the canonical per-event feature pattern.

**Severity**
Medium. The "I confirmed but the customer doesn't know" silence is a real conversion drag — the customer is most anxious in the window between booking and confirmation, and the absence of a confirmation push that does anything useful in-app is exactly the kind of friction that drives manual refresh / abandonment. Pair with flag #22 in a single customer-status sprint.

---

## ~~26. Customer booking-detail screen is a placeholder (`/customer/booking/:job_id` stub)~~ ✅ Resolved (2026-05-09)

**What changed**
Booking-orchestrator sprint, session 3 shipped the real audience-shared detail UI as a new top-level feature `lib/features/orchestrator/`. The placeholder `CustomerBookingDetailScreen` is deleted; the route is renamed to `/booking/:job_id` (audience-neutral — both customer and technician land there). All realtime entry points (`EventUrgencyRouter._highUrgencyRoutes` + `_lowUrgencyTapRoutes`, the bookings-list card tap) point to the new path.

The orchestrator screen hydrates from `GET /api/bookings/<id>/` (the session 2 detail endpoint), renders a status-driven slot architecture (header / timeline / body / secondary actions / primary action), and reacts to 13 realtime events via per-screen notifiers. Body widgets are stubs for sessions 4–6 (live tracking map, quote builder, cash collection, edge-case modals) but render the server's `ui` block verbatim today, so happy-path is demo-walkable end-to-end.

**Where it landed**
- `frontend/lib/features/orchestrator/` — full feature stack (domain entities, sealed failures, repository interface + impl, freezed DTOs, mappers, http remote + SharedPreferences local datasource, Riverpod providers, screen + slot widgets + 14 stub bodies + shared pending sheet).
- `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart` — high-urgency routes for `quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved` repointed to `/booking/:job_id`; low-urgency tap routes for `jobAccepted`, `bookingRejected`, and the 5 new orchestrator events similarly converged. Nav-guard keys switched to `'job_id'` so the same screen isn't double-pushed for different entity ids.
- `frontend/lib/core/realtime/domain/entities/system_event_type.dart` + `event_urgency.dart` — extended with `quoteRevisionRequested`, `quoteDeclined`, `bookingCancelled`, `bookingNoShow`, `bookingRescheduled`.
- `frontend/lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart` — added 5 list-side patch methods so the bookings list updates in lockstep with the orchestrator screen.
- `backend/bookings/selectors/orchestrator_ui.py` — endpoint strings stripped of the `/api/` prefix and the literal `<id>` placeholder substituted with the actual `active_quote.id` (sprint §24 + invariant tests).

---

## ~~27. Customer bookings list feature stack landed without UI~~ ✅ Resolved (2026-05-05)

**What changed**
- `presentation/screens/customer_bookings_list_screen.dart` — landed. Sticky AppBar, segmented control + counts badges, RefreshIndicator + paginated `ListView.builder`, full §7 state→render coverage (skeleton / empty-per-segment / list / list+offline-banner / list+pagination-footer / offline-error / server-error / unknown-error), validation-failure auto-refresh.
- `presentation/widgets/` — booking_card (dumb, switches only on `ui.badgeTone`; 1s pulse animation on realtime status patches; pill morphs via 250ms `AnimatedSwitcher`; segment-fade-out on cross-segment status flips; Cancelled visual decay), booking_card_skeleton (shimmer; dims match card exactly), booking_status_pill, booking_tech_avatar (initials fallback), bookings_segmented_control, bookings_empty_upcoming, bookings_empty_past, bookings_offline_banner (warning-tone strip with `cachedAt` minute-delta), bookings_error_state (offline / server / unknown variants).
- `presentation/utils/` — booking_tone_palette (single source of truth for tone→token resolution; reads `AppColors` directly until the global theme is migrated to explicit M3 tokens), booking_date_formatter (smart "Today / Tomorrow / In 30 min" anchored on server-time, AWAITING SLA hint appended).
- `core/theme/app_colors.dart` — appended four missing tokens (`tertiaryFixedDim`, `onTertiaryFixed`, `onSecondaryContainer`, `onErrorContainer`) at the brief's exact §3.1 hexes. Global theme stays on `ColorScheme.fromSeed`; the bookings palette reads `AppColors` directly so the canonical tones land regardless of seed drift. Documented as part of the planned end-of-UI design-system cleanup pass.
- `features/customer/home/presentation/screens/home_screen.dart` — converted to `IndexedStack` shell. `BottomNavigationBar` now tracks `currentCustomerTabProvider` and tabs switch instantly with scroll/state preserved per tab. Messages and Profile are coming-soon placeholder widgets until those features ship. Debug FABs scoped to the Home tab only.
- `features/customer/home/presentation/providers/current_tab_notifier.dart` — new `@riverpod` int notifier (not `keepAlive`; resets to Home on next mount).
- `core/routing/app_router.dart` — registered `GoRoute('/customer/bookings')` for deep-link navigation (FCM "View your bookings" tap, in-app `context.push`). Direct route shows the back arrow; tab-mounted instance does not.

The data sprint's ~25 source files are unchanged. The dumb-UI contract held — the widget reads `ui.badgeText` / `ui.badgeTone` / `ui.headline` / `price.uiLabel` / `price.context` / `addressLabel` verbatim and never recomputes from raw `BookingStatus`.

---

## 28. AI chatbot dispute intake — schema seam present, module deferred

**Where**
- `backend/bookings/models.py::SupportTicket.dispute_intake_method` (CHOICES: `FORM` | `CHATBOT`)
- `backend/bookings/models.py::SupportTicket.chat_log` (`JSONField`, nullable)
- `backend/bookings/services/orchestrator.py::open_dispute` — only writes `dispute_intake_method=FORM`
- `backend/bookings/admin.py` — admin shows the field but no writer creates `CHATBOT`-intake tickets

**What's wrong**
The booking orchestrator landed with the seam in place — `SupportTicket` accepts a method enum and a `chat_log` payload — but no module actually emits chatbot-intake tickets. Every dispute opened today is `FORM` intake; `chat_log` is uniformly null. Customers in distress walk into a static form and miss the lower-friction conversational triage planned in the product spec.

**Why we shipped it that way**
The chatbot is a separate engineering effort (LLM-routing infra, prompt safety, transcript storage policy, GDPR-style consent on the chat log). Bundling it into the orchestrator sprint would have multiplied scope and pushed every other deliverable back. Locking the schema this sprint preserves the seam — when the chatbot module ships it can write tickets through the same `SupportTicket` row without a migration.

**The proper fix**
1. New app `chatbot/` with an LLM-router service and a transcript model. Settle the storage policy first (PII redaction at write time vs. read time).
2. Customer-facing entry point (mobile UI tap → `POST /api/dispute/chat/start/` returns a session token) that runs the conversation server-side, then on resolution writes a `SupportTicket(dispute_intake_method=CHATBOT, initial_reason=<router summary>, chat_log=<full transcript>)` and invokes `orchestrator.open_dispute` with the resulting reason.
3. Update `SupportTicketAdmin` to render `chat_log` readably (collapsible JSON viewer) once tickets start carrying it.
4. Audit `orchestrator.open_dispute` — it accepts `initial_reason` as a single string today; if the chatbot wants to attach multiple structured fields, extend the signature.

**Search hints**
- `dispute_intake_method` — every consumer
- `chat_log` — currently zero writers
- `INTAKE_CHATBOT` — the enum sentinel

**Severity**
Low. Form intake works; the seam doesn't degrade either lifecycle. Pick up alongside the customer-facing chatbot rollout.

---

## 29. Reviews / ratings — model + endpoints deferred

**Where**
- No `Review` model exists yet (`backend/` has no `reviews/` app)
- `TechnicianProfile.rating_average` and `review_count` columns exist but are never written by any service today
- `bookings/services/orchestrator.py::mark_complete_with_cash` — completion path never prompts the customer for a review

**What's wrong**
A booking moves to `COMPLETED` and the loop closes silently. The technician's `rating_average` / `review_count` columns stay at their factory defaults (4.5 / 10) forever; the matchmaker's Bayesian average is computed against a synthetic baseline because there is no real review data flowing in. Customers can't surface bad experiences short of opening a dispute, and tech reputation can't differentiate over time.

**Why we shipped it that way**
The review system needs decisions that are properly product-side: which dimensions to rate (overall vs. punctuality vs. cleanliness), edit windows, abuse-prevention (one review per booking, not per session), retroactive review for bookings that completed pre-launch. None of those decisions exist today and the orchestrator sprint was already ten files deep.

**The proper fix**
1. New app `reviews/` with a `Review` model: `booking` (OneToOne), `customer` (FK), `technician` (FK), `rating` (1..5 IntegerField), `comment` (TextField), `created_at`. Constraint: one review per booking. Edit window field if product wants editable reviews.
2. `bookings/services/orchestrator.py::mark_complete_with_cash` registers a deferred event (`booking_completed_review_prompt`) on commit so the customer's UI prompts after completion.
3. `POST /api/reviews/` writes the row + atomically updates `TechnicianProfile.rating_average` (running mean) and `review_count`. `select_for_update` on the technician row.
4. Surface in matchmaking selector — replace the synthetic Bayesian baseline with the real distribution.
5. Tech-side moderation flow (admin can hide a review with reason) — coordinate with the dispute model so a dispute that PENALIZE_TECHs auto-flags any review on the same booking for moderator review.

**Search hints**
- `rating_average` — column exists; no writers
- `review_count` — same
- Look for `Bayesian` / `m=10` in matchmaking selectors — the placeholder math

**Severity**
Medium. Ranking quality degrades over time without real data, but the platform technically functions. Pick up after the orchestrator stabilizes; it's a natural next sprint.

---

## ~~30. Bank accounts / wallet payouts — cash collection only this sprint~~ ✅ Resolved (2026-05-13)

Resolved by the finance sprint: real `WalletFinanceAdapter` writes commission rows on every IN_PROGRESS → COMPLETED transition, the `wallet/` app ships the full ledger + payout-account + withdrawal-lifecycle schema (8 models, 0001_initial), and the dashboard pill now pushes a real tech-only Wallet screen.

**What changed**
- New app `wallet/` with `WalletTransaction` (ledger + `balance_after` audit invariant), `WalletTopup` (relaxed 1:0..1 with WalletTransaction to allow in-flight gateway state), `JobCommission`, `RefundDeduction`, `TechnicianBankAccount`, `TechnicianJazzCashAccount`, `WithdrawalRequest`, `WithdrawalFulfilment`. All shipped in a single `0001_initial` migration so Thursday's top-up/withdraw plumbing adds zero schema risk.
- `wallet/services/ledger.py::record_transaction` — single ACID-guaranteed ledger-write site. `transaction.atomic` + `select_for_update` on TechnicianProfile + balance_after snapshot + `transaction.on_commit` broadcast of `WALLET_BALANCE_UPDATED`. Idempotency via `transaction_reference_number` partial-unique constraint.
- `wallet/adapters/wallet_finance_adapter.py::WalletFinanceAdapter` — implements `FinancePort`. `record_commission` debits 20% commission and creates a `JobCommission` row keyed `booking:{id}:commission` for idempotency. Other hooks intentionally no-op (customer↔tech is cash-only; the wallet tracks tech↔platform money flow only — see `feedback_wallet_vs_metrics_separation` memory).
- `wallet/services/gateway_ports.py::PaymentGatewayPort` — Protocol with `initiate_topup`/`verify_topup`/`initiate_payout`. `wallet/adapters/mock_jazzcash_gateway.py::MockJazzCashGateway` ships tonight so the Port surface is exercised; Thursday's real JazzCash adapter is a one-file drop-in.
- `bookings/adapters/__init__.py::get_default_finance_service` switches on `settings.FINANCE_BACKEND` (default `'wallet'`, tests can opt-in to `'null'`).
- `wallet/admin.py` — read-only admin pages for all 8 tables (supervisor-grade audit view).
- `GET /api/technicians/wallet/` — thin balance read endpoint, IDOR-safe.
- Frontend: `lib/features/technician/wallet/` — full domain/data/presentation feature; `WalletScreen` with balance card + Top up + Withdraw CTAs (latter two snackbar "Available Thursday"). Dashboard wallet pill pushes `/wallet`. `WALLET_BALANCE_UPDATED` event wired through `SystemEventType.walletBalanceUpdated` for in-place balance patches on both the dashboard pill and the wallet screen.
- Tests: backend +39 (`tests/wallet/`), frontend +18 (`test/features/technician/wallet/`). Zero regressions.

**Follow-ups** — see flags 34–37 below for top-up, withdraw form, lockout enforcement, and payout-account auto-capture (all locked-in for Thursday 05-14).

(Original entry preserved below for forensic context.)

---

**Where**
- `backend/bookings/services/finance_ports.py::FinancePort` — Protocol with 5 methods, all routed to `NullFinanceAdapter` no-ops
- `backend/bookings/adapters/null_finance.py::NullFinanceAdapter` — every method returns `None` / `(True, None)`
- `backend/bookings/adapters/__init__.py::get_default_finance_service` — returns the null adapter
- `backend/bookings/services/orchestrator.py::mark_complete_with_cash` — calls `record_cash_collected` and `record_commission` against the null adapter (no-ops)
- No `WalletTransaction` model, no `JobCommission` model, no JazzCash integration

**What's wrong**
The orchestrator publishes the right port-and-adapter shape, but no real money flow exists. `mark_complete_with_cash` stamps the booking row with the cash amount and broadcasts `payment_received`, but no commission is debited from the technician wallet, no platform balance changes, and the technician has no path to top-up via JazzCash. `apply_inspection_fee_decision`, `apply_cancellation_charge`, and `can_accept_job` all silently permit. Any production go-live requires the finance adapter; right now the platform technically lets technicians accept unlimited jobs with zero wallet balance.

**Why we shipped it that way**
Real money flow is a sprint of its own — JazzCash sandbox + production credentials, idempotency keys for top-up retries, reconciliation reports for the platform's own bank, daily payout batching, transaction history UI. The booking orchestrator's contract demanded a clean port boundary (`FinancePort`) so the wallet sprint can land without re-touching orchestrator code. Bundling them would have made review impossible.

**The proper fix**
1. New app `wallet/` with `WalletTransaction` (technician FK, kind=TOP_UP|COMMISSION|REFUND|PENALTY, amount Decimal, JazzCash ref, created_at), `JobCommission` (booking OneToOne, computed amount, technician FK).
2. New adapter `bookings/adapters/wallet_finance.py::WalletFinanceAdapter` implementing every `FinancePort` method against the wallet models.
3. `bookings/adapters/__init__.py::get_default_finance_service` swaps to return `WalletFinanceAdapter` — single point of swap; no orchestrator code touched.
4. JazzCash top-up integration — tech-facing endpoint + webhook handler for top-up confirmation (idempotent on JazzCash ref).
5. Wallet-lockout enforcement — `can_accept_job` returns `(False, 'wallet_below_threshold')` when balance < commission threshold; orchestrator's `accept_job_booking` (existing) needs to be retrofitted to call this port (today it doesn't).
6. Admin reconciliation views — daily commission rollup, refund audit.

**Search hints**
- `FinancePort` — the contract
- `NullFinanceAdapter` — what gets swapped out
- `current_wallet_balance` on `TechnicianProfile` — exists but currently static

**Severity**
High. Cannot ship to production without this. Hard-blocker on the platform's revenue model. Must precede any paid-pilot launch.

---

## 31. Admin realtime channel — `tech_reliability_penalty` event deferred (audit P0-08)

**Where**
- `backend/realtime/constants/event_types.py::EventType` — no `tech_reliability_penalty` member (deliberately omitted this sprint)
- `backend/realtime/events/services/...EventLog.target_role` — accepts only `'customer'` / `'technician'` strings; `'admin'` would fail at save
- `backend/bookings/services/orchestrator.py::cancel_by_tech`, `mark_no_show` — write `TechReliabilityIncident` rows but do NOT broadcast to admin
- `backend/bookings/admin.py::TechReliabilityIncidentAdmin` — append-only admin list view IS the admin's only window today

**What's wrong**
The v0.9 sprint plan called for a `tech_reliability_penalty` realtime event broadcast to admin every time a tech cancels post-arrival or is reported no-show. Audit P0-08 caught that `EventLog.target_role` only allows customer/technician roles — admin broadcasts would crash at save. The sprint replaced the broadcast with a `TechReliabilityIncident` DB row; admin reads via Django Admin's list view. That works for now (admin can pull a CSV any time) but admins lose realtime situational awareness — if a tech is mid-cascade canceling 3 jobs in a row the admin sees it on next page-refresh, not as it happens.

**Why we shipped it that way**
Adding `'admin'` as a third `target_role` requires extending the `EventLog` choice set, the FCM device registry to accept admin tokens, the per-user channel-layer group convention, and the frontend admin tooling to consume those frames. None of that infrastructure exists; admins today use the Django Admin web UI on a desktop browser. The DB row + admin list view delivers the same audit trail with a refresh-cycle lag.

**The proper fix**
1. Extend `EventLog.target_role` choices to include `'admin'`. Backfill nothing (no historical admin events exist).
2. Define an `admin_<id>_events` channel-layer group convention and a corresponding subscription in a future admin web-tooling app (or a new admin SPA).
3. Wire `bookings/services/orchestrator.py::cancel_by_tech` and `mark_no_show` to broadcast `tech_reliability_penalty` (target_role='admin', payload includes booking_id + technician_id + incident_type + phase) alongside the DB row write.
4. Consider whether to also broadcast on `open_dispute` (today the dispute event goes to the counterparty only — admins read disputes via the SupportTicket admin list).
5. Decide on FCM-vs-WS-only: admins are likely on a desktop/web client most of the time, so WS-only might suffice and dodge the admin-FCM-token problem.

**Search hints**
- `EventLog.target_role` — the constraint blocking admin broadcasts today
- `TechReliabilityIncident` — the DB row that fills the gap meanwhile
- `audit P0-08` — referenced in models.py and orchestrator.py
- `tech_reliability_penalty` — the event name reserved for this fix

**Severity**
Low for now (admin list view is functional), Medium when the platform scales past a single ops person who can't watch every booking. Pair with the reliability-score sprint that aggregates over `TechReliabilityIncident`.

---

## 32. Geofence strictness is env-only, with no per-tech / per-service overrides

**Where**
- `backend/core/settings.py` — `BOOKING_GEOFENCE_STRICT = env.bool('BOOKING_GEOFENCE_STRICT', default=False)`
- `backend/.env.example` — documents the flag
- `backend/bookings/api/transitions/views.py::ArrivedView._maybe_geofence_check` — reads the flag at request time
- `backend/bookings/services/auto_transition.py` — `EN_ROUTE_THRESHOLD_METERS = 200`, `ARRIVED_THRESHOLD_METERS = 100` (hardcoded constants)

**What's wrong**
The geofence's strictness is a single global env flag, and the distance thresholds are single hardcoded constants. Real fleets have variance — dense city centres need a wider threshold; rural / large-property bookings need a tighter one. A high-end gated community where the customer's address pin is at the gatehouse but the actual unit is 300 m inside cannot be served well by a single global value. Same for the strict/lenient toggle: a deployment that wants strict in dense zones but lenient in suburban zones has no path with a single env var.

**Why we shipped it**
Single-tenant pre-launch scope; no operational signal yet on which thresholds work in which Pakistani city. Per-entity config is premature without data on real-world false-positive rates from the auto-transition path. The env flag was the cheapest path to (a) close audit P1-04's spirit (no silent stale surfaces) and (b) keep an emergency lever to disable the geofence rejection if early-launch data shows the 100 m radius is wrong, without paying the model-churn cost of a per-tech / per-service / per-zone config table.

**The proper fix**
1. Add `geofence_radius_meters` to `TechnicianProfile` (per-tech; defaults to a Service-level fallback). Captures the field-experience signal the tech will give us once they are operating.
2. Add `geofence_strict` to `Service` (per-category). Big services like full-house cleaning legitimately need lenient; emergency plumbing needs strict.
3. Update `ArrivedView._maybe_geofence_check` to resolve from `booking.technician.geofence_radius_meters` (with Service fallback), and `auto_transition.evaluate_on_location` to read the same.
4. Deprecate `BOOKING_GEOFENCE_STRICT` once the per-Service column lands — per-zone is strictly more expressive.
5. Telemetry: log every lenient-mode mismatch warning with `distance_m`, `tech_id`, `booking_id` so the data team can pick sane defaults from observed behaviour.

**Search hints**
- `BOOKING_GEOFENCE_STRICT`, `ARRIVED_THRESHOLD_METERS`, `EN_ROUTE_THRESHOLD_METERS`
- `_maybe_geofence_check`, `auto_transition.evaluate_on_location`
- `STREAMS_TECH_GPS.md` — public docs reference this rule

**Severity**
P3. UX polish, no correctness or money-flow risk. The lenient default + warning log keeps the system functional even when the constant is wrong for a particular booking.

---

## 33. `tech_location` ingress throttle is per-process, not distributed

**Where**
- `backend/bookings/api/tech_location/views.py`
  - module-level `_LAST_PUBLISH_TS: dict[tuple[int, int], float]`
  - module-level `_THROTTLE_SECONDS = 4.0`
  - module-level `_THROTTLE_CACHE_MAX = 5_000`
- Audit reference: cycle-2 P1-07
- `backend/realtime/api/STREAMS_TECH_GPS.md` — documents the limitation

**What's wrong**
The 4-second throttle for GPS frame ingress is keyed on a process-local Python dict (`_LAST_PUBLISH_TS`). Each Daphne / gunicorn worker has its own copy; with N workers, the effective rate per `(tech_user_id, booking_id)` pair is `N × (1/4s)`. A foreground location service that round-robins across workers (or any sticky-session-disabled deployment) could publish the stream up to N times per 4 seconds. Auto-transition is idempotent so double-flips never happen, but the customer's WS connection still receives N× redundant stream frames and pays the bandwidth + battery cost.

The Python dict additionally has a 5,000-row hard cap with stale-eviction; under sustained load that eviction can fire before the throttle window elapses, weakening the limit further.

**Why we shipped it**
CLAUDE.md explicitly forbids a Redis dependency for v1 ratelimiting ("no Redis dependency for ratelimiting in v1"). Pre-launch we have no realistic load profile yet, and a single-worker deployment exhibits the contract perfectly. The 5-second client tick gives a 1-second guard band even under the worst N-worker case (8 workers × every-5s tech ticks = at most 8 publishes per 4-second window — bandwidth-impactful but not service-degrading).

**The proper fix**
1. Add a Redis-backed token bucket (`django-ratelimit` or a thin `redis.set(..., ex=4, nx=True)` wrapper) keyed `tech_location:{tech_user_id}:{booking_id}`.
2. Replace `_LAST_PUBLISH_TS` + `_throttle_hit` with a single atomic `set` — distributed across workers, no eviction footprint.
3. Update `STREAMS_TECH_GPS.md`'s "Throttling" section to drop the per-worker caveat once the fix lands.
4. Add a `tech_location.publish.count_per_minute` metric so we can observe actual publish rate post-fix and confirm the limit is binding.

**Search hints**
- `_LAST_PUBLISH_TS`, `_throttle_hit`, `_THROTTLE_SECONDS`, `_THROTTLE_CACHE_MAX`
- `tech-location-rate-limit-not-distributed` (referenced in `STREAMS_TECH_GPS.md`)
- `bookings/api/tech_location/views.py`

**Severity**
P2. Observability + bandwidth concern; no correctness risk because the auto-transition path is idempotent. Becomes P1 once we run > 1 worker AND have a paying-customer base whose data plans we care about.

---

## 34. `WsFrameDispatcher` is single-handler-per-stream-type

**Where**
- `frontend/lib/core/realtime/presentation/services/ws_frame_dispatcher.dart`
  - `_streamHandlers: Map<String, void Function(Map<String, dynamic> payload)>`
  - `register(streamType, handler)` — last-writer-wins
  - `unregister(streamType)` — single-arg, no handler param
- Audit reference: cycle-2 P0-07 (resolved by adoption; this flag tracks the structural follow-up)
- First consumer: `frontend/lib/features/orchestrator/presentation/providers/technician_location_stream_notifier.dart` (session 4)

**What's wrong**
The dispatcher's stream-handler registry stores ONE handler per `streamType`. Calling `register('tech_gps', A)` and then `register('tech_gps', B)` silently replaces A with B — the first consumer's frames now go to the second consumer's closure, and A's `unregister('tech_gps')` (no handler arg) tears down B's handler too.

The contract is acceptable in v1 because the UX shows exactly one orchestrator screen at a time, so only one `TechnicianLocationStreamNotifier(jobId)` is ever alive. Two parallel orchestrator screens for two different bookings (e.g. picture-in-picture, split-screen, app-resume race) would break — the second screen's `register` overwrites the first's handler, and the first screen's polyline + marker freeze until it re-watches the provider on next rebuild.

**Why we shipped it**
The single-handler API matches the existing v1 single-screen UX. A multi-handler refactor (`Map<String, List<Handler>>` + token-based unregister) needed:
- A new `HandlerToken` returned from `register` and required by `unregister`.
- All current call sites updated to track + pass the token.
- A test surface for "two consumers of the same streamType receive both frames."

That refactor was out of scope for session 4, whose goal was to ship live tracking end-to-end. Ratifying the single-handler constraint and flagging the limitation was the cheapest path forward.

**The proper fix**
1. Change `_streamHandlers` to `Map<String, List<_HandlerEntry>>` where each `_HandlerEntry` carries the handler + a unique `Object` token.
2. `register(streamType, handler)` returns the token; callers store it.
3. `unregister(streamType, token)` removes only that one entry.
4. `_routeStream` invokes every handler for the matched streamType.
5. Update `TechnicianLocationStreamNotifier` to capture + pass the token in its `ref.onDispose` cleanup.
6. Add a regression test: two notifiers register for `tech_gps`; both receive the same frame; one disposes; the other still receives subsequent frames.

**Search hints**
- `_streamHandlers`, `WsFrameDispatcher`, `register('tech_gps'`
- `unregister('tech_gps')` — every call site needs updating
- `flutter/lib/core/realtime/presentation/services/ws_frame_dispatcher.dart` v9.x (current)

**Severity**
P3. Becomes P2 if/when the product introduces split-screen or any UX that mounts two orchestrator screens concurrently.

---

## 35. iOS foreground location service deferred (Booking Orchestrator session 4)

**Where**
- `frontend/lib/features/technician/location_broadcaster/` — Android-only feature folder.
- `frontend/lib/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart` — invokes `FlutterForegroundTask.startService` which on iOS becomes a foreground notification only (not a true background-capable service).
- `frontend/android/app/src/main/AndroidManifest.xml` — `FOREGROUND_SERVICE_LOCATION` permission + service registration.
- iOS plist + Swift code — UNTOUCHED.

**What's wrong**
The tech-side GPS broadcaster runs only on Android. iOS testers will see the orchestrator screen render the customer-side map happily, but the technician device cannot publish GPS frames — meaning a customer with an iOS-tech assigned will see "Waiting for technician's location…" indefinitely on `EN_ROUTE`, then "Technician offline" after 60 seconds.

This is the iOS half of pre-existing flag #10 ("iOS native realtime push capability"). Session 4 added the tech-location broadcaster on Android; iOS is a strict no-op pending Mac-based development capacity to author the equivalent native foreground task host.

**Why we shipped it**
- No Mac in the dev pipeline; iOS code-signing + simulator + device testing not viable for v1.
- `flutter_foreground_task` provides an iOS placeholder (`IOSNotificationOptions`) but its iOS impl is a notification-only banner — the OS does not allow background location updates with the same generosity Android grants foreground services. A real iOS broadcaster needs CoreLocation `allowsBackgroundLocationUpdates = true` plus a properly configured `UIBackgroundModes` plist entry + battery-conservation tuning.
- The product's launch market is Pakistan with predominantly Android phones; iOS demand is thin enough that "Android-only v1" is acceptable to the founding team.

**The proper fix**
1. Pair with an iOS dev (or schedule a Mac sprint) to wire native CoreLocation in a Dart-callable plugin.
2. Configure `UIBackgroundModes: [location]` in `Info.plist` + `NSLocationAlwaysAndWhenInUseUsageDescription` copy.
3. Extend `ForegroundLocationServiceController` to platform-dispatch on `Theme.of(...).platform` or `Platform.isIOS` and call the iOS variant.
4. Adapt `STREAMS_TECH_GPS.md` to drop the "Android-only" caveat.
5. Test on a TestFlight build with at least one real iOS user — the simulator's CoreLocation behaviour diverges substantially from device.

**Search hints**
- `flutter_foreground_task` (Android-only path)
- `Geolocator.getPositionStream` (cross-platform; works on iOS but the foreground host is the missing piece)
- `lib/features/technician/location_broadcaster/`
- Pre-existing flag #10 — bundle the closure of both flags together once iOS lands.

**Severity**
P3 today (Android dominates the launch market). Becomes P1 the moment a paying iOS technician onboards.

---

## 36. Map widget dynamic-state coverage gated on platform-channel injection

**Where**
- `frontend/lib/core/widgets/map/google_app_map.dart` — `_maybeApplyCamera`, `_programmaticMoveInFlight` flag, `_resolveMarkers`'s `setState` + `mounted` guard.
- `frontend/lib/core/widgets/map/osm_app_map.dart` — same family of dynamic state (camera follow, gesture detection).
- ~~`frontend/lib/core/widgets/map/live_tracking_map.dart` — 13 enumerated uncovered branches (audit H14 / T-2).~~ ✅ Resolved 2026-05-10 (see partial-resolution note below).

**What's wrong**
The Google/OSM map widgets couple directly to `gmaps.GoogleMapController` (completed by `onMapCreated`, which only fires in a real Flutter binding with the `google_maps_flutter` host) and `flutter_map`'s `MapController` in the same way. Unit tests cannot drive the controller-dependent branches:

- `_programmaticMoveInFlight` flag never observable.
- `_maybeApplyCamera`'s target-vs-bounds priority never asserted.
- `_resolveMarkers`'s `setState` post-`mounted` check never asserted.

H12 covered the pure helpers (`markersEqual`, `listsAreSame`, `computeBounds`, `resolveAllMarkers`); H14 covered the `LiveTrackingMap` composition layer. The remaining gap is **inside** the two concrete adapters — `_GoogleAppMapState` and `_OsmAppMapState` — where `gmaps.GoogleMapController.future` and `MapController` instances are completed asynchronously from platform plugin callbacks.

**Why we shipped it**
Closing the adapter-side branches requires extracting an injectable seam for the underlying controllers across both adapters. The original audit suggested doing this together with `LiveTrackingMap`'s test coverage, but H14 found that the LiveTrackingMap layer was already declarative-camera (no async-controller seam needed there) and closed it without an IMapController port. The Google/OSM-side work is now smaller in scope but still genuinely controller-coupled, and would land in its own commit pair.

**The proper fix**
1. Define `IMapController` protocol in `core/widgets/map/` with the camera-animate API both adapters need (`animateToTarget`, `fitBounds`).
2. `_GoogleAppMapState` and `_OsmAppMapState` accept an `IMapController` (resolved via Riverpod or constructor injection) instead of completing internal completers from `onMapCreated`.
3. Test fakes implement `IMapController` and let tests drive the camera/marker flow synchronously, with explicit hooks for asserting `_programmaticMoveInFlight` transitions and re-entrancy.
4. Backfill the dynamic-state tests for both adapters.
5. Coordinate with flag #34 (multi-handler `WsFrameDispatcher`) — same port-and-adapter family, similar effort budget; sequencing them in one "platform-seam refactor" sprint avoids two separate disruptions to the realtime/orchestrator stack.

**Search hints**
- `gmaps.GoogleMapController`, `_controllerCompleter`, `_programmaticMoveInFlight`
- `MapController` (flutter_map's equivalent in `OsmAppMap`)

**Severity**
P3 (was P2 — narrowed by H14 closing the LiveTrackingMap portion). Adapter-side coverage gap on internal seam state, but the screen itself works in production (covered by manual smoke + integration). Becomes P2 only if an adapter regression slips because of the missing automation.

**✅ Partial resolution — 2026-05-10 (H14)**
`LiveTrackingMap`'s 13 enumerated branches (T-2a–T-2m) were closed without introducing the IMapController port. The audit handoff assumed `LiveTrackingMap` itself awaited `gmaps.GoogleMapController.future`, but in practice `IAppMap`'s contract is **declarative** — the parent passes `cameraTarget`/`cameraBounds`/`onUserGesture` as widget props and the adapter animates internally. So the existing `appMapBuilderProvider` Riverpod override IS the seam for camera/marker assertions; only the `launchUrl` call in the phone-call FAB needed a new port (`IUrlLauncher`, commit 179b861).

Test commit: f9dc93d. 15 widget tests cover all 13 T-2 branches + 2 happy/error variants for the call FAB. Recording stub `IAppMap` captures camera/marker/polyline/gesture props per build; sequence-driven `_FakeDirectionsService` + `_FakeUrlLauncher` round out the test seam.

The remaining adapter-side scope (Google/OSM controller-coupled branches) keeps this flag open but at reduced severity.

---

## 37. OSRM public-instance for production directions

**Where**
- `frontend/lib/core/widgets/map/osrm_directions_service.dart:25-28` — default `baseUrl: 'https://router.project-osrm.org'`.
- `frontend/lib/core/widgets/map/map_provider.dart` — `directionsServiceProvider` falls back to `OsrmDirectionsService` when `MAP_PROVIDER=osm` (no API key required).

**What's wrong**
The default OSM map provider builds against the public OSRM demo instance (`router.project-osrm.org`). That host is explicitly **demo-only** — the OSRM project asks not to be used at production scale. Symptoms in real traffic:
- Soft rate-limits during regional bursts → 429s (now mapped to `DirectionsRateLimited` per audit P1-1, but the user-visible UX is still "ETA missing").
- Periodic 5xx during peak load → `DirectionsServerFailure(503)`.
- 8-30 second tail latency on cold paths even when the timeout (8s, audit H3) catches the worst.

The source comment at `osrm_directions_service.dart:14-16` literally says *"flag.md will note this; production must self-host OSRM or fall back to Google."* The flag was never opened in session 4. Audit M6-contract caught the gap.

**Why we shipped it**
- Self-hosting OSRM is not booking-flow work — it's infra spinup (a Docker image + tile data + a small instance). Out of scope for the live-tracking sprint.
- Google Directions is keyed (`GOOGLE_MAPS_API_KEY`); without provisioned billing the OSM/OSRM path is the only one that boots from a fresh dev clone. The dual-provider abstraction explicitly aims for "OSM works without keys, Google works with them."
- The directions layer is **soft-fail** UX (audit comment in `live_tracking_map.dart:_maybeFetchDirections`'s catch) — when OSRM blows up the live marker still renders, only the polyline + ETA pill go missing. Acceptable for v1 demo; not acceptable for production.

**The proper fix**
Production deployments must point `OsrmDirectionsService.baseUrl` at one of:
1. A self-hosted OSRM container (`osrm-backend` Docker image + Pakistan OSM extract from Geofabrik). Roughly: a 2 vCPU / 4 GB instance per region, ~3 GB tile data, 30 min spinup. Wire the URL through `--dart-define=OSRM_BASE_URL=...` at build time so it ships per-environment.
2. Mapbox Directions (paid, ~$5 / 1000 requests, has Pakistan coverage, returns the same GeoJSON shape OSRM does — minimal code change).
3. Google Directions on the OSM provider too (drop OSRM entirely). Requires `GOOGLE_MAPS_API_KEY` provisioning and rewires `directionsServiceProvider` to always pick `GoogleDirectionsService` regardless of `MAP_PROVIDER`.

Action items when the proper fix lands:
- Add `OSRM_BASE_URL` to `AppConstants` (mirror `GOOGLE_MAPS_API_KEY` pattern).
- Update `MAP_WIDGETS.md` directions section.
- Strike through this flag with `✅ Resolved (date)` and a brief "what changed" line.

**Severity**
P3 in dev / demo (rate-limit lands on 429 path that's already handled gracefully). P1 the day this app onboards real customers — the public OSRM instance will start refusing traffic once the QPS climbs.

---

## 34. JazzCash top-up flow — backend + frontend deferred to Thursday 05-14

**Where**
- `backend/wallet/models.py::WalletTopup` — schema shipped 2026-05-13 (1:0..1 with `WalletTransaction`, holds `gateway_session_id` / `gateway_redirect_url` / `gateway_callback_payload` for in-flight state).
- `backend/wallet/services/gateway_ports.py::PaymentGatewayPort` — `initiate_topup` / `verify_topup` declared but only `MockJazzCashGateway` implements them.
- `backend/wallet/adapters/mock_jazzcash_gateway.py` — fake gateway exercising the Port surface.
- `backend/wallet/api/urls.py` — only `GET /` (balance) wired tonight. No `POST /topups/`, no `/gateways/jazzcash/callback/`.
- `frontend/lib/features/technician/wallet/presentation/widgets/top_up_button.dart` — onTap shows `"JazzCash top-up is launching Thursday."` snackbar.

**What's wrong**
The wallet schema + ledger ship tonight, but the only way money actually enters a tech's wallet today is via Django Admin `WalletTransaction` row creation (which `_ReadOnlyAdmin` actually disallows — admin can only view). For the viva demo this means commission *deductions* are observable (they fire on every COMPLETED booking) but a tech can't replenish their wallet from inside the app yet.

**Why we shipped it that way**
The thesis flow is: tech taps Top up → enters amount → redirected to JazzCash auth → on callback success the wallet credits. That spans (a) a `POST /api/wallet/topups/` endpoint that calls `gateway.initiate_topup`, (b) a redirect surface on the FE, (c) a `POST /api/wallet/gateways/jazzcash/callback/` webhook with signature verification, (d) a real `JazzCashGateway` adapter that the user is chasing sandbox credentials for. Bundling that into tonight's sprint would have blown past morning and risked breaking the ACID ledger sprint by interleaving HTTP integration work with model design work.

**The proper fix (Thu 05-14)**
1. Real `wallet/adapters/jazzcash_gateway.py::JazzCashGateway` implementing `PaymentGatewayPort` — HMAC sign / verify, real REST calls.
2. Register `'jazzcash'` in `settings.PAYMENT_GATEWAYS`; flip `DEFAULT_PAYMENT_GATEWAY='jazzcash'` for prod.
3. `POST /api/wallet/topups/` — creates `WalletTopup(PENDING)`, calls `gateway.initiate_topup`, persists `gateway_session_id` + redirect URL, returns redirect URL to FE.
4. `POST /api/wallet/gateways/jazzcash/callback/` — verifies signature, calls `gateway.verify_topup`, on success calls `ledger.record_transaction(TOPUP_CREDIT)` and links the resulting `WalletTransaction` to the `WalletTopup`. Auto-creates `TechnicianJazzCashAccount(is_default=True)` if the tech has no default payout account yet (covers flag 37).
5. Frontend top-up screen with amount input, redirect/webview handling, and post-callback refresh of `WalletNotifier`.

**Severity**
P1 for viva — supervisor's thesis check expects the top-up flow to demo. Mock gateway ships tonight to keep the Protocol surface honest; the real path lands on Thursday.

---

## 35. Tech withdrawal request — UI form + admin action deferred to Thursday 05-14

**Where**
- `backend/wallet/models.py::WithdrawalRequest` + `WithdrawalFulfilment` — schemas ship tonight (status enum, payout account XOR constraint, admin_external_ref + admin_notes fields).
- `backend/wallet/admin.py::WithdrawalRequestAdmin` — registered tonight but read-only. No `approve_and_process` admin action yet.
- `backend/wallet/api/urls.py` — no `POST /withdrawals/` endpoint.
- `frontend/lib/features/technician/wallet/presentation/widgets/withdraw_button.dart` — onTap snackbar `"Withdrawal requests open Thursday."`.

**What's wrong**
The thesis flow specifies: tech submits a withdraw request (entering a bank account OR using their saved JazzCash account from top-up), admin processes manually via Django Admin, ledger records the `WITHDRAWAL_DEBIT`. Tonight the schema is in place but the UX is a snackbar; admin can see the empty `WithdrawalRequest` table but can't process anything.

**Why we shipped it that way**
Withdraw is downstream of top-up (the saved payout account is captured during the first top-up — see flag 37). With top-up itself deferred to Thursday, building withdraw tonight would either require a separate "manually add payout account" entry flow (scope creep) or land a UI that's immediately broken because no payout accounts exist yet.

**The proper fix (Thu 05-14)**
1. `POST /api/wallet/withdrawals/` — accepts `amount` + `payout_account_id` (one of bank/jazzcash). Creates `WithdrawalRequest(PENDING_REVIEW)`. NO ledger write yet — the debit happens on admin approval.
2. Frontend withdraw screen with amount input + payout-account picker (default-preselected). Lists existing `TechnicianBankAccount` + `TechnicianJazzCashAccount` rows. "Add new bank account" form for techs who don't yet have one (covers the "tech who hasn't topped up yet wants to withdraw" edge case — unlikely but possible).
3. `WithdrawalRequestAdmin.actions = ['approve_and_process']` — admin clicks, enters `admin_external_ref` (real JazzCash merchant txn id from out-of-band payout), service writes `WalletTransaction(WITHDRAWAL_DEBIT)` + `WithdrawalFulfilment` row, broadcasts `WALLET_BALANCE_UPDATED`.

**Severity**
P1 for viva — thesis demonstrates the full withdraw flow including admin approval. The schema-first approach tonight means Thursday is pure plumbing.

---

## 36. Wallet lockout enforcement — `can_accept_job` always permits

**Where**
- `backend/wallet/adapters/wallet_finance_adapter.py::WalletFinanceAdapter.can_accept_job` — returns `(True, None)` unconditionally.
- `backend/bookings/services/job_request_dispatch.py::PLATFORM_COMMISSION_RATE = Decimal("0.20")` — commission rate is known.
- No `MIN_WALLET_BALANCE` / threshold constant defined yet.
- `CLAUDE.md` business rule: *"Wallet Lockout: Technician blocked from accepting jobs if wallet balance < commission threshold, until JazzCash top-up"* — currently unenforced.

**What's wrong**
A tech with a deeply-negative wallet balance can still accept new jobs tonight; `can_accept_job` never refuses. The hook is in place (Port surface ships), but the policy decision is unimplemented.

**Why we shipped it that way**
Without top-up shipping tonight, enforcing the lockout would brick every seeded tech on first commission deduction. The lockout becomes safe to enable on Thursday alongside the top-up path — tech can hit the threshold, get blocked, top up, get unblocked.

**The proper fix (Thu 05-14)**
1. Define `WALLET_LOCKOUT_THRESHOLD: Decimal` in `wallet/services/` (or settings). Likely `Decimal('0.00')` for v1 — go below zero, you're blocked.
2. `can_accept_job` checks `technician.current_wallet_balance + commission_for_pending_job >= threshold`. Returns `(False, 'wallet_below_threshold')` otherwise.
3. The orchestrator's `accept_job_booking` already wraps the call in the FinancePort hook; this becomes the natural gate.
4. Frontend surfaces the rejection with a "Top up to accept this job" CTA inside the incoming-job-request sheet.

**Severity**
P1 for prod (platform's revenue floor). P2 for viva — thesis says lockout exists; demoing it requires Thursday's top-up flow to also exist (so the tech can unblock themselves).

---

## 37. Payout account auto-capture on first top-up — deferred

**Where**
- `backend/wallet/models.py::TechnicianJazzCashAccount` — schema shipped tonight, no writers.
- `backend/wallet/adapters/jazzcash_gateway.py` — does not exist yet; the auto-capture happens inside its `verify_topup` success path.

**What's wrong**
The thesis flow says: when a tech tops up via JazzCash for the first time, the JazzCash mobile number they paid from is auto-saved as a default `TechnicianJazzCashAccount` for future withdrawals. Tonight the table exists but no code writes to it.

**Why we shipped it that way**
Tied to flag 34 — the auto-capture happens inside the gateway callback handler, which doesn't ship until Thursday.

**The proper fix (Thu 05-14)**
Inside the `/gateways/jazzcash/callback/` handler, after `ledger.record_transaction(TOPUP_CREDIT)`: check whether the tech has any `is_active=True` payout account (bank or JazzCash). If none, create a `TechnicianJazzCashAccount(is_default=True, source='auto_topup')` from the MSISDN in `gateway_callback_payload`. If the tech already has a default, leave it alone (they explicitly configured something else).

**Severity**
P2 — feature works without auto-capture (tech can manually add a withdraw destination in the withdraw form), but the thesis flow is cleaner with auto-capture and that's the demo path.

---

## 38. Customer-side dispute / refund models — schemas land with chatbot/dispute day

**Where**
- `backend/wallet/models.py` — only the *tech-side* financial models ship tonight. The thesis schema (Figure 3.15) also includes `SupportTicket`, `TicketEvidence`, `RefundRequest`, `CustomerBankAccount` — none shipped tonight.
- `backend/wallet/models.py::RefundDeduction` — *did* ship tonight (it's a 1:1 subtype of `WalletTransaction`, written when admin issues a refund and debits the tech), but no UI or admin action creates one yet.

**What's wrong**
The chatbot's dispute-intake flow (`project_chatbot_scope.md`: narrative + 3 photos + bank mini-form, post-completion entry only) is going to write `SupportTicket` + `TicketEvidence` + `RefundRequest` + `CustomerBankAccount` rows. None of those tables exist in the database tonight. When chatbot day runs, it will need to ship its own migration `0002_dispute_models.py` adding those four tables.

**Why we shipped it that way**
Scoping discipline. Tonight is the wallet sprint, not the dispute sprint. Conflating them would have ballooned the change set and made review harder. The thesis schema cleanly separates "tech-side money" from "customer-side dispute/refund" — tonight ships the first, chatbot day ships the second.

**The proper fix (Wed 05-13 evening / chatbot day)**
1. Add `wallet/models.py` entries for `SupportTicket` (with `text` / `description` fields — note the thesis schema has both, may be redundant; pick one or disambiguate as title/body), `TicketEvidence` (FK to ticket + `photo_url`), `RefundRequest` (amount, status, admin_note, processed_at), `CustomerBankAccount` (mirror of `TechnicianBankAccount`).
2. New migration `wallet/migrations/0002_dispute_models.py`.
3. Wire admin pages for all four.
4. Refund flow: admin reviews `RefundRequest`, approves → service writes a `WalletTransaction(REFUND_DEBIT)` for the tech (using the existing `RefundDeduction` subtype that ships tonight) + records the refund payout to the customer's bank account.

**Severity**
P1 for chatbot day (thesis demonstrates the full dispute → refund flow). P3 for tonight (deferred deliberately; no code references the missing tables).


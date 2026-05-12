# Session 1 — Wire the main isolate

> **One of three sessions** that close flag #7 in `flag.md`.
> Order: this file → `session_2_auth_bridge.md` → `session_3_android_native_and_finalize.md`.
> Each session is its own commit on its own branch, manually verified before the next begins.

---

## What this session is

Flag #7 in `flag.md` documents that the entire realtime subsystem (`SystemEventNotifier`, `WsConnectionNotifier`, `EventSyncNotifier`, `FCMHandler`, `firebaseMessagingBackgroundHandler`, `EventUrgencyRouter`, feature-side queue notifiers like `IncomingJobQueueNotifier`) is fully implemented and unit-tested in isolation, but **none of it runs in the production app boot path**. Tests pass because every realtime test exercises the stack via direct `ProviderContainer` calls — no test calls `runApp`, so no test catches the missing wiring. The result: a logically-correct subsystem and a production app that delivers zero realtime events.

This session closes **gaps 1, 2, 3, and 5** of flag #7:

1. `main.dart` does not call `Firebase.initializeApp()`.
2. `main.dart` does not register the FCM background handler.
3. `AppLifecycleOrchestrator` is never mounted in the widget tree.
5. `navigatorKey` and `scaffoldMessengerKey` are not constructed or threaded.

It deliberately does **not** close gap 4 (auth-side `bootAfterAuth` / `teardownOnLogout` calls). That's Session 2's scope. Splitting this way gives Session 1 a clean, testable mid-state: the app cold-starts, Firebase initializes, the orchestrator's `WidgetsBindingObserver` registers — but auth never triggers boot/teardown, so no events flow. **Inert but observable** is the intended outcome of this session.

Read `flag.md` section 7 in full before starting if you haven't already. Read `frontend/lib/core/realtime/presentation/app_lifecycle_orchestrator.dart` end-to-end (it has a long class-level docstring documenting the contract) and `frontend/lib/core/realtime/REALTIME_EVENTS_FEATURE.md` for the architectural overview.

---

## Decisions taken (from prior architectural review)

These were proposed as questions in an earlier scratchpad. The user accepted all recommended answers. Re-stated here so this session is self-contained:

- **Q1 — Boot timing: `unawaited(bootAfterAuth(...))`, not `await`.** *(Relevant to Session 2; noted here for full decision-context.)* Awaiting `bootAfterAuth` from `AuthNotifier.build()` or `verifyOtp` would block the auth state on the WebSocket handshake — multiple seconds on slow networks. That causes a `/login` flash on cold start with cached user, and an OTP-screen spinner stall on fresh login. Fire-and-forget is correct: the boot's side-effects (WS connect, FCM register, sync) all surface their own state via their own providers; auth state shouldn't gate on them.
- **Q2 — Circular import: accept the cycle (option C1).** Session 2 will add an `auth_notifier.dart → app_lifecycle_orchestrator.dart` import. The orchestrator already imports `auth_notifier.dart` (line 19). Dart compiles cyclical imports fine; the orchestrator's class-level docstring (lines 7-18) explicitly sanctions the `core → features` direction. Extracting a bridge file is overhead without a real coupling problem to solve.
- **Q3 — iOS native capabilities: OUT OF SCOPE.** User has no MacBook; the project is **Android-only** for now. Flag #7 step 5 (Info.plist `UIBackgroundModes`, Push Notifications entitlement, APNs key) is **NOT addressed in any of these three sessions**. Do not edit `frontend/ios/Runner/Info.plist`. Session 3 will open a new flag (#8) to track the iOS work for a future Mac-equipped sprint.
- **Q4 — Three sessions, three commits.** This file documents Session 1 of 3. Each session is a separate, testable commit on its own branch. Manually verify each session before moving on.
- **Q5 — flag.md resolution: at the END of Session 3.** Do **not** edit `flag.md` in this session. Session 3 strikes flag #7 with a "Resolved for Android" entry and appends flag #8 for the deferred iOS work.

---

## Files this session touches

Three files, total. No other file in the repo should change in this commit.

1. `frontend/lib/core/realtime/presentation/providers/dependency_injection.dart` — ADD two providers (navigator key + messenger key).
2. `frontend/lib/core/routing/app_router.dart` — modify GoRouter constructor to accept the navigator key.
3. `frontend/lib/main.dart` — initialize Firebase, register the FCM background handler, mount the orchestrator, thread the messenger key into `MaterialApp.router`.

---

## Pre-flight

```bash
git checkout main
git pull
git checkout -b session-1-wire-main-isolate

cd frontend
flutter pub get
flutter analyze        # baseline must be clean
```

Confirm dependencies (already in `pubspec.yaml` — verified for this session):
- `firebase_core: ^4.7.0`
- `firebase_messaging: ^16.2.0`

If either is missing, stop and flag the user — flag #7 mentions the realtime team already added them, so absence is unexpected.

Also verify the FCM background handler exists at `frontend/lib/core/realtime/presentation/services/fcm_background_handler.dart`. Flag #7 references it; Session 1 imports it.

---

## File 1: `dependency_injection.dart` (ADD two providers)

Open `frontend/lib/core/realtime/presentation/providers/dependency_injection.dart`.

This file already exposes realtime providers (`eventLocalDataSourceProvider`, `eventSecureStorageProvider`, etc.). Append at the end of the file (or alongside the other DI declarations — order is not load-bearing):

```dart
/// Shared `GlobalKey<NavigatorState>` that both `EventUrgencyRouter` and
/// `GoRouter` use. Kept as a plain `Provider` (not `@riverpod`) because
/// `GlobalKey` instances are imperative singletons that don't fit code-
/// generation cleanly. Riverpod's provider-singleton guarantee gives us
/// the "same instance for both consumers" invariant `EventUrgencyRouter`
/// needs to push routes against the live navigator.
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (_) => GlobalKey<NavigatorState>(),
);

/// Shared `GlobalKey<ScaffoldMessengerState>` so `EventUrgencyRouter` can
/// surface SnackBars/Banners on the same `ScaffoldMessenger` that
/// `MaterialApp.router` mounts.
final scaffoldMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (_) => GlobalKey<ScaffoldMessengerState>(),
);
```

Make sure the file imports:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

(They are likely already present since other realtime providers use them. If not, add them.)

### Why a plain `Provider`, not `@riverpod`?
Code-gen `@riverpod` providers infer types from function return values and add lifecycle hooks. For an imperative singleton like `GlobalKey<NavigatorState>()`, code-gen adds zero value and complicates the override path. The plain `Provider` form is the idiomatic Riverpod choice here.

---

## File 2: `app_router.dart` (MODIFY — single-line addition)

Open `frontend/lib/core/routing/app_router.dart`.

### Add import at the top
Add alongside the existing imports:

```dart
import '../realtime/presentation/providers/dependency_injection.dart';
```

### Modify `routerProvider`
Currently (lines 19-24):

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Accessing the user through the AsyncValue wrapper
  final user = ref.watch(authProvider.select((async) => async.value?.user));

  return GoRouter(
    initialLocation: '/login',
```

Change to:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Accessing the user through the AsyncValue wrapper
  final user = ref.watch(authProvider.select((async) => async.value?.user));
  final navigatorKey = ref.watch(navigatorKeyProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
```

That's the only change in this file. Routes, redirect logic, and the `user` selector are unchanged.

---

## File 3: `main.dart` (REPLACE)

Current `frontend/lib/main.dart` is 49 lines. After this session it will be ~74 lines. Replace the entire contents with:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/realtime/presentation/app_lifecycle_orchestrator.dart';
import 'core/realtime/presentation/providers/dependency_injection.dart'
    as realtime_di;
import 'core/realtime/presentation/services/fcm_background_handler.dart';
import 'core/routing/app_router.dart';
import 'features/technician/onboarding/presentation/providers/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase on the main isolate. Without this, foreground FCM
  // listeners (`onMessage`, `onMessageOpenedApp`, `getInitialMessage`) and
  // `getToken()` would crash on first use. The BG isolate also calls
  // `Firebase.initializeApp()` independently inside
  // `firebaseMessagingBackgroundHandler` — these two initializations are
  // deliberately separate (different isolates).
  await Firebase.initializeApp();

  // Register the BG handler so the OS has a Dart-side callback to invoke
  // for FCM data messages while the app is terminated. Must run before
  // `runApp`. `firebaseMessagingBackgroundHandler` is a top-level function
  // (required by FCM — instance methods are not addressable from the BG
  // isolate).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const _Bootstrap(),
    ),
  );
}

/// Bridges `ProviderScope` to `AppLifecycleOrchestrator`. The orchestrator
/// needs `ref` to resolve the shared navigator/messenger keys; `runApp`'s
/// `child` builder doesn't expose a `ref` synchronously. Pulling this into
/// a `ConsumerWidget` is cleaner than nesting a `Consumer` builder inline.
class _Bootstrap extends ConsumerWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLifecycleOrchestrator(
      navigatorKey: ref.watch(realtime_di.navigatorKeyProvider),
      scaffoldMessengerKey: ref.watch(realtime_di.scaffoldMessengerKeyProvider),
      child: const MyApp(),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final messengerKey = ref.watch(realtime_di.scaffoldMessengerKeyProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Technician on Demand',
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
```

### Why does `MyApp` also `ref.watch(scaffoldMessengerKeyProvider)`?
The orchestrator passes the messenger key to `EventUrgencyRouter` (orchestrator line 187 area). `MaterialApp.router` mounts that messenger via its `scaffoldMessengerKey` parameter. Both consumers must share the same key instance so `EventUrgencyRouter.handleEvent` can surface banners on the visible scaffold. Riverpod's provider-singleton guarantee makes this trivial: both `ref.watch(scaffoldMessengerKeyProvider)` calls return the same `GlobalKey`.

### Why a `_Bootstrap` widget instead of inlining?
Inlining a `Consumer` builder inside `ProviderScope.child` works but explodes indentation and obscures intent. `_Bootstrap` is private to `main.dart`, has a single responsibility (wire the orchestrator), and reads cleanly.

---

## Gotchas

1. **Order of `Firebase.initializeApp` and `onBackgroundMessage`.** Firebase MUST initialize first. Reverse the order and the BG handler registration may attempt to touch un-initialized Firebase internals. Stick to the order shown.
2. **Hot-reload is safe; hot-restart is safe.** `Firebase.initializeApp()` is idempotent — repeat calls return the existing default app, not a crash. `FirebaseMessaging.onBackgroundMessage(...)` re-registration on hot-reload is also safe. No special handling needed.
3. **`GlobalKey` reuse across hot-reload.** `Provider<GlobalKey<...>>` returns the same instance for the lifetime of the `ProviderScope`. Hot-reload preserves the `ProviderScope`, so the keys survive — no key-mismatch bugs between the orchestrator and `MaterialApp.router`. Hot-restart recreates the scope and gives fresh keys; `MaterialApp.router` and the orchestrator are also rebuilt at that point, so they pick up the same fresh keys consistently.
4. **`SharedPreferences.getInstance()` ordering.** Keep this AFTER Firebase init. Firebase failure is the more catastrophic of the two and you want it surfaced first.
5. **Don't add `try/catch` around `Firebase.initializeApp()`.** If Firebase fails to initialize, the app should crash visibly so the developer notices. Swallowing the exception leaves a half-broken app where FCM silently doesn't work.
6. **No tests are added in this session.** Tests are deferred to Session 3 (auth-bridge unit test + optional `runApp` widget test). The reason: this session's surface is small enough that manual verification is sufficient, and the bridge unit test in Session 3 covers the higher-value risk (auth-bridge regression).

---

## Verification

This session's verification is intentionally narrow. Auth-side flow (login → event delivery) is Session 2's scope. Here we only confirm the wiring doesn't break the cold-start path.

### 1. Static analysis
```bash
cd frontend
flutter analyze
```
Must be clean. Zero new warnings, zero new errors.

### 2. Cold start (no logged-in user)
```bash
flutter run                    # Android device or emulator
```
- App opens to `/login` (the GoRouter redirect for null user — unchanged).
- Console shows no `Firebase` exceptions.
- Console shows no `MissingPluginException`.

### 3. Confirm orchestrator mounted (temporary debug print — DO NOT COMMIT)
In `app_lifecycle_orchestrator.dart` `initState` (around line 183), temporarily add:

```dart
print('[DEBUG] AppLifecycleOrchestrator initState ran');
```

Cold-start the app. The line should appear once in the Flutter console. Background the app (home button) and bring it back — `didChangeAppLifecycleState` runs (add a print there too if you want explicit confirmation: `print('[DEBUG] lifecycle: $state')`).

**Revert these debug prints before committing.**

### 4. Confirm Firebase initialized (temporary debug print — DO NOT COMMIT)
Temporarily add to `main.dart` after `Firebase.initializeApp()`:

```dart
print('[DEBUG] Firebase apps: ${Firebase.apps.map((a) => a.name).toList()}');
```

Should print `[DEBUG] Firebase apps: [[DEFAULT]]`. **Revert before committing.**

### 5. Hot-reload sanity
With the app running on `/login`, edit any unrelated UI file (e.g. add a space in `LoginScreen`'s text). Hot-reload (`r` in the `flutter run` terminal). The app should reload without crashing or losing the route. Then hot-restart (`R`) — also clean.

### 6. Existing flows still work (regression check)
- Log in with phone `+923001234567` and dev OTP `123456` (per CLAUDE.md → "OTP IN DEVELOPMENT").
- Navigate around (home, search, addresses).
- Log out.
- Re-launch.

State transitions match pre-session behavior. **No realtime events are expected to flow yet** — that's Session 2.

---

## What this session does NOT fix

- WebSocket does not connect on login — Session 2.
- FCM token does not register with Django — Session 2 (depends on WS init).
- Logout does not tear down WS / FCM — Session 2.
- Android `POST_NOTIFICATIONS` permission still missing — Session 3.
- iOS native config — out of scope (no MacBook).
- No widget test exists yet for the cold-start `runApp` tree — Session 3 (optional).

If you trigger an event from the Django shell during this session's verification, the WS won't deliver it and the app won't notify. **That is correct.** Don't chase it as a bug.

---

## Definition of done

- [ ] `flutter analyze` clean.
- [ ] App cold-starts to `/login` without crash on Android device/emulator.
- [ ] Hot-reload + hot-restart both clean.
- [ ] Login + logout flows still functional (no regression in existing screens).
- [ ] Temporary debug prints removed before commit.
- [ ] Three files modified, no others.
- [ ] Commit message: `feat(realtime): mount orchestrator + initialize Firebase in main isolate (flag #7 partial)`.
- [ ] Commit pushed; PR opened against `main` (or merged if your workflow allows direct merges).

When done, **stop**. Manually verify on your device. Then move to `session_2_auth_bridge.md`.

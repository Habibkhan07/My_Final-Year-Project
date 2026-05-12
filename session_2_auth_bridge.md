# Session 2 — Auth bridge (boot/teardown)

> **Two of three sessions** that close flag #7 in `flag.md`.
> Order: `session_1_wire_main_isolate.md` → this file → `session_3_android_native_and_finalize.md`.
> Session 1 must be merged before starting this one.

---

## What this session is

Session 1 mounted `AppLifecycleOrchestrator` above `MaterialApp.router`, initialized Firebase, and registered the FCM background handler. The lifecycle observer is alive and the realtime providers are reachable — but the orchestrator's `bootAfterAuth` / `teardownOnLogout` static helpers are never called. So the WebSocket never connects, FCM never registers a device with Django, and the entire event-flow chain stays dormant.

This session closes **gap 4** of flag #7: wire the three transition points in `AuthNotifier` (`build`, `verifyOtp`, `logout`) to call the orchestrator's bridge helpers. After this session, real events flow:

- **Cold-start with cached user** → `build()` fires `unawaited(bootAfterAuth(ref, token))` → WS connects, FCM registers, missed-event sync runs.
- **Fresh login via `verifyOtp`** → same chain.
- **Logout** → `teardownOnLogout` runs (WS disconnect → FCM unregister → `SystemEventNotifier.reset` → cleared local caches) **before** the auth repository clears the local token.

A small but load-bearing refactor of the orchestrator is also part of this session: `bootAfterAuth` and `teardownOnLogout` change their signatures from `WidgetRef` → `Ref` so they're callable from `Notifier.build()`.

---

## Decisions taken

(Same decisions as Session 1 — restated for self-containment.)

- **Q1 — `unawaited(bootAfterAuth(...))`, not `await`.** This is the most important call in this session. Awaiting boot blocks the auth state on WS handshake. With `unawaited`, the user sees their cached UI immediately and WS connects in the background. WS errors surface on `wsConnectionProvider`'s own state, not on auth state.
- **Q2 — Circular import is accepted.** This session adds an `import` of `app_lifecycle_orchestrator.dart` into `auth_notifier.dart`. The orchestrator already imports `auth_notifier.dart` (line 19). Dart compiles this fine; the orchestrator's class-level docstring explicitly sanctions the `core → features` direction.
- **Q3 — iOS out of scope.** Project is Android-only for now. Do not edit `ios/Runner/Info.plist` or any iOS file.
- **Load-bearing ordering: `teardownOnLogout` BEFORE `repository.logout()`.** The WS disconnect notifies the server to unregister the FCM device; that call needs the auth token still valid. `repository.logout()` is what clears the token from `FlutterSecureStorage`. Reversing the order silently breaks server-side device-unregister (you'd see stale FCM subscriptions on the backend).

---

## Files this session touches

Two files. No other file in the repo should change in this commit.

1. `frontend/lib/core/realtime/presentation/app_lifecycle_orchestrator.dart` — refactor two static method signatures (`WidgetRef` → `Ref`) and update the dartdoc example to use `unawaited` for `bootAfterAuth`.
2. `frontend/lib/features/auth/presentation/providers/auth_notifier.dart` — wire boot/teardown calls at three transition points.

After saving the changes, regenerate `auth_notifier.g.dart` via build_runner.

---

## Pre-flight

```bash
git checkout main
git pull                       # Session 1 should be in main now
git checkout -b session-2-auth-bridge

cd frontend
flutter pub get
flutter analyze                # baseline must be clean
```

Confirm Session 1 is in place by reading `frontend/lib/main.dart`. It must contain `Firebase.initializeApp()`, `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`, and the `_Bootstrap` widget. If not, finish Session 1 first.

Re-read these before changing anything:
- `frontend/lib/core/realtime/presentation/app_lifecycle_orchestrator.dart` — focus on `bootAfterAuth` (lines 116-130) and `teardownOnLogout` (line 160). Confirm the body uses only `ref.read(...)` (no `ref.watch` or `WidgetRef`-only methods). The flag claims this; **verify with your own eyes** before refactoring the signature.
- `frontend/lib/features/auth/presentation/providers/auth_notifier.dart` — three integration points are `build()` (line 13), `verifyOtp()` (line 40), `logout()` (line 97).

---

## File 1: `app_lifecycle_orchestrator.dart` (MODIFY — signatures + dartdoc)

The body of `bootAfterAuth` and `teardownOnLogout` is correct as-is. Only the signatures change so they're callable from `Notifier.build()` (which has a `Ref`, not a `WidgetRef`).

### Change 1: `bootAfterAuth` signature (line 116)

Before:
```dart
static Future<void> bootAfterAuth(WidgetRef ref, String authToken) async {
```

After:
```dart
static Future<void> bootAfterAuth(Ref ref, String authToken) async {
```

### Change 2: `teardownOnLogout` signature (line 160)

Before:
```dart
static Future<void> teardownOnLogout(WidgetRef ref) => performTeardown(
```

After:
```dart
static Future<void> teardownOnLogout(Ref ref) => performTeardown(
```

### Change 3: Update dartdoc example (line ~75-77)

The class-level dartdoc currently shows `await AppLifecycleOrchestrator.bootAfterAuth(ref, token);`. Since this session uses `unawaited`, update the example so it doesn't mislead future readers.

Before:
```dart
/// // After a successful login that yields an auth token:
/// await AppLifecycleOrchestrator.bootAfterAuth(ref, token);
///
/// // Before clearing local auth state on logout:
/// await AppLifecycleOrchestrator.teardownOnLogout(ref);
```

After:
```dart
/// // After a successful login that yields an auth token (fire-and-forget;
/// // awaiting would stall auth state on the WS handshake):
/// unawaited(AppLifecycleOrchestrator.bootAfterAuth(ref, token));
///
/// // Before clearing local auth state on logout (awaited — WS device-
/// // unregister needs the token still valid):
/// await AppLifecycleOrchestrator.teardownOnLogout(ref);
```

### Imports
At the top of the file, the existing import:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```
exports both `Ref` and `WidgetRef`. **No import changes needed.**

### Why `Ref` works (sanity check)
`bootAfterAuth` body uses only:
- `ref.read(eventSyncProvider.notifier).onUnauthorized = ...` — works on `Ref`.
- `ref.read(authProvider.notifier).logout()` — works on `Ref`. Note: this lives inside a closure that fires LATER (when a 401 reaches `EventSyncNotifier`). It is not invoked synchronously during `bootAfterAuth`'s execution, so there's no reentrancy from `AuthNotifier.build()`.
- `ref.read(incomingJobQueueProvider)` — works on `Ref`.
- `ref.read(fcmHandlerProvider).initialize()` — works on `Ref`.
- `ref.read(wsConnectionProvider.notifier).connect(...)` — works on `Ref`.

`performTeardown` doesn't take a ref at all. `teardownOnLogout` is an arrow function that only does `ref.read(...)` for each provider. Both work identically with `Ref`.

---

## File 2: `auth_notifier.dart` (MODIFY three methods)

Open `frontend/lib/features/auth/presentation/providers/auth_notifier.dart`.

### Change 1: Add import (top of file)

After the existing `import 'auth_state.dart';` line, add:

```dart
import '../../../../core/realtime/presentation/app_lifecycle_orchestrator.dart';
```

The `dart:async` import (line 2) is already present; that gives us `unawaited`.

### Change 2: `build()` (lines 12-23)

Before:
```dart
@override
FutureOr<AuthState> build() async {
  // 1. Check for cached session on startup
  final repository = ref.read(authRepositoryProvider);
  final user = await repository.getCachedUser();

  if (user != null) {
    return AuthState(user: user);
  }

  return const AuthState();
}
```

After:
```dart
@override
FutureOr<AuthState> build() async {
  final repository = ref.read(authRepositoryProvider);
  final user = await repository.getCachedUser();

  if (user != null) {
    if (user.token != null) {
      // Fire-and-forget: WS handshake takes seconds on slow networks;
      // awaiting would leave auth in AsyncLoading and the router would
      // route to /login. WS errors surface on wsConnectionProvider, not
      // on auth state.
      unawaited(AppLifecycleOrchestrator.bootAfterAuth(ref, user.token!));
    }
    return AuthState(user: user);
  }

  return const AuthState();
}
```

### Change 3: `verifyOtp()` (lines 40-49)

Before:
```dart
Future<void> verifyOtp(String phone, String otp) async {
  if (state.isLoading) return;

  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final useCase = ref.read(verifyOtpUseCaseProvider);
    final user = await useCase.execute(phone, otp);
    return AuthState(user: user);
  });
}
```

After:
```dart
Future<void> verifyOtp(String phone, String otp) async {
  if (state.isLoading) return;

  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final useCase = ref.read(verifyOtpUseCaseProvider);
    final user = await useCase.execute(phone, otp);
    if (user.token != null) {
      // Fire-and-forget; see build() for rationale.
      unawaited(AppLifecycleOrchestrator.bootAfterAuth(ref, user.token!));
    }
    return AuthState(user: user);
  });
}
```

### Change 4: `logout()` (lines 97-101)

Before:
```dart
Future<void> logout() async {
  state = const AsyncLoading();
  await ref.read(authRepositoryProvider).logout();
  state = const AsyncData(AuthState());
}
```

After:
```dart
Future<void> logout() async {
  state = const AsyncLoading();
  // Teardown BEFORE repository.logout(): WS disconnect notifies the server
  // to unregister the FCM device, and that call needs the auth token still
  // valid. `repository.logout()` is what clears the token from secure
  // storage. Reversing this order silently breaks device-unregister.
  await AppLifecycleOrchestrator.teardownOnLogout(ref);
  await ref.read(authRepositoryProvider).logout();
  state = const AsyncData(AuthState());
}
```

### Do NOT change `requestOtp` or `completeSignup`
- `requestOtp` doesn't yield an authenticated user (returns a message string). No boot to fire.
- `completeSignup` runs after `verifyOtp` has already triggered boot. The orchestrator's helpers are idempotent (FCM init guards against double-register; WS connect short-circuits if already connected), but re-firing here produces noisy logs and zero new behavior.

### Regenerate the `.g.dart` file

```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

This is necessary because `auth_notifier.g.dart` is generated from the `@Riverpod(keepAlive: true)` annotation. The body changes shouldn't alter generated output, but run it anyway for safety. Re-run `flutter analyze` after.

---

## Gotchas

1. **`build()` is async — does Riverpod allow `unawaited` inside it?** Yes. `build()` returns `FutureOr<AuthState>`. The body awaits the cache read, then synchronously schedules the boot via `unawaited`, then returns the state. Riverpod doesn't care what fire-and-forget work happens before the return — the boot's microtask queue carries it to its own resolution.

2. **`ref` lifetime inside the unawaited closure.** `bootAfterAuth(ref, ...)` captures `ref`. Boot can take seconds. If the user logs out before boot finishes, `ref` is still valid because `AuthNotifier` is `keepAlive: true` — its `ref` lives as long as the `ProviderScope` (which lives as long as the app). No "ref used after dispose" risk.

3. **Race between `bootAfterAuth` and `teardownOnLogout`.** If a user logs out faster than the boot completes, teardown runs while boot is still trying to register FCM / connect WS. The orchestrator's `performTeardown` calls `wsConnection.disconnect()` which is safe to call on a connecting socket (the connection cascade aborts). FCM `unregister` is safe even if `initialize` hasn't finished. The race is benign, but logs may show "WS connecting → disconnected" in rapid succession on fast logout. Acceptable.

4. **Why is `teardownOnLogout` awaited but `bootAfterAuth` is not?** Asymmetric for a reason. Boot's failure mode is "user has no realtime events for a while" — graceful degradation, no UX block warranted. Teardown's failure mode is "auth token cleared before server-side device-unregister fires" — leaves stale FCM subscriptions on the backend, dispatching events to a phone that's logged out. The latter is server-state pollution, the former is in-app inconvenience. Hence the asymmetry.

5. **`ref.read(authProvider.notifier).logout()` reentrancy from `onUnauthorized`.** `bootAfterAuth` sets `eventSync.onUnauthorized = () => ref.read(authProvider.notifier).logout()`. If a 401 fires during boot's FCM register call, this triggers `logout()` which calls `teardownOnLogout`. `performTeardown` (orchestrator line 157) clears `eventSync.onUnauthorized = null`, so a second logout firing is impossible. Safe by construction.

6. **Don't introduce raw `try/catch` in `auth_notifier.dart`.** Per CLAUDE.md → Riverpod Rules: "Async mutations: ALWAYS `state = await AsyncValue.guard(...)` — never manual `try/catch` with `AsyncLoading()`/`AsyncError()`". The boot call is `unawaited` and fire-and-forget — its errors are surfaced by the realtime providers themselves, not by the auth notifier.

---

## Verification

Backend (Django) must be running for these checks. Standard dev OTP `123456` applies (CLAUDE.md → "OTP IN DEVELOPMENT").

### 1. Static analysis & code-gen
```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test                   # all existing tests still pass
```
All three must be clean.

### 2. Backend up
In a separate terminal:
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```
Tail this terminal during the manual checks below — it's where you'll see WS connect, FCM register, and logout traces.

### 3. Fresh login → WS connect (manual)
- Cold-launch the Flutter app on Android.
- Phone: `+923001234567` (or whatever test phone you use).
- Tap "Request OTP" → enter `123456` → submit.

Expected Django console output (interleaved):
- Existing OTP-verify success log.
- WebSocket connect log from `realtime/consumers/event_consumer.py` (e.g. `Connected: user_<id>` or `WebSocket CONNECT /ws/events/`).
- FCM device-register POST hit (e.g. `POST /api/realtime/fcm/register/ 201`).

If you see auth login but **no** WS connect line, the bridge is broken. Most likely causes:
- `dart run build_runner build` wasn't re-run after the auth_notifier edit.
- The `unawaited(...)` call is unreachable (e.g. `user.token == null` because the auth response didn't include one).
- An import cycle is being silently broken at runtime — re-read both edits.

### 4. Cold-start with cached user (manual)
- Force-quit the app (do not log out — long-press the app card and swipe away).
- Re-launch the app.

Expected Django console: a fresh WS connect AND a fresh FCM register, both arriving within ~1-2s of cold-launch (no user input required). The auth state restores from `FlutterSecureStorage` and `build()` fires `unawaited(bootAfterAuth)` automatically.

### 5. Logout → ordered teardown (manual)
- While logged in, watch the Django console.
- Tap logout in the app.

Expected log sequence:
1. WS disconnect (`Disconnected: user_<id>` or similar).
2. FCM device-unregister POST returns 200/204 (the call succeeds because the token is still valid at this point).
3. Auth logout endpoint POST returns 200 (token cleared).

If the device-unregister returns 401, the ordering is wrong — verify in `auth_notifier.dart` that `await AppLifecycleOrchestrator.teardownOnLogout(ref)` runs **before** `await ref.read(authRepositoryProvider).logout()`.

### 6. End-to-end event delivery (manual smoke test)
With the technician logged in and on the home screen (or wherever the app lands post-login):

```bash
cd backend
python manage.py shell
```
```python
from realtime.services.event_dispatch import EventDispatchService
from accounts.models import User
tech = User.objects.get(phone='+923001234567')   # adjust phone
EventDispatchService.broadcast_event(
    user=tech,
    event_type='job_new_request',
    payload={
        'job_id': 999,
        'expires_at': '2026-05-01T20:00:00Z',
        'service_name': 'AC Repair',
        'payout': '1500',
        'distance_km': 2.3,
        'address_line': 'Test address',
    },
)
```

The Flutter app should immediately push to `/technician/incoming-job-request`.

If the app receives the event but doesn't navigate, the issue is downstream of the auth bridge:
- `EventUrgencyRouter` route registration for `job_new_request` (see `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart` — it should be in `_listRouteEvents`).
- The list-route screen (`/technician/incoming-job-request`) must exist in `app_router.dart` (it does — Session 1 didn't touch that).

If the app doesn't receive the event at all (no log, no banner, no nav):
- WS isn't connected. Check Django console for the connect log from step 3. If absent, `bootAfterAuth` isn't firing — re-read the auth_notifier edit.

### 7. Crash recovery (manual)
- While logged in, turn off the device's network.
- Force-kill the app.
- Turn the network back on.
- Re-launch the app.

Expected:
- App restores cached user (existing behavior, no change from Session 2).
- WS reconnects via `bootAfterAuth` triggered from `build()`.
- The `EventSyncNotifier` sync cascade drains any events that arrived while offline (`syncMissedEvents → syncUnacknowledgedCritical → flush pending ACKs`).

---

## What this session does NOT fix

- **Android `POST_NOTIFICATIONS` permission**: still missing. Without it, on Android 13+, `FirebaseMessaging.requestPermission()` won't surface the OS dialog AND no system-tray notification will appear. **You can still see in-app events** because WS delivers them directly while the app is in the foreground — but the FCM-via-system-notification path (background / terminated) is broken until Session 3.
- **iOS native config**: out of scope (no MacBook).
- **Widget tests covering the cold-start `runApp` path**: deferred to Session 3.
- **`flag.md` resolution entry**: deferred to Session 3.

---

## Definition of done

- [ ] `flutter analyze` clean.
- [ ] `dart run build_runner build --delete-conflicting-outputs` clean.
- [ ] `flutter test` passes (existing tests still green).
- [ ] Manual login from cold-launch shows WS connect + FCM register in Django console.
- [ ] Cold-start with cached user shows WS connect.
- [ ] Logout shows WS disconnect → FCM unregister (200) → auth logout, in order.
- [ ] End-to-end test event from Django shell pushes a route in the app.
- [ ] No `WidgetRef` references left in `app_lifecycle_orchestrator.dart`.
- [ ] No raw `try/catch` introduced in `auth_notifier.dart` (must keep `AsyncValue.guard` pattern per CLAUDE.md).
- [ ] Two source files modified, one generated file updated, no others changed.
- [ ] Commit message: `feat(realtime): wire AuthNotifier to orchestrator boot/teardown (flag #7 partial)`.

When done, **stop**. Manually verify on your device. Then move to `session_3_android_native_and_finalize.md`.

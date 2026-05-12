# Session 3 — Android native capabilities + finalize flag #7

> **Three of three sessions** that close flag #7 in `flag.md`.
> Order: `session_1_wire_main_isolate.md` → `session_2_auth_bridge.md` → this file.
> Sessions 1 and 2 must be merged before starting this one.

---

## What this session is

Sessions 1 and 2 mounted the realtime stack on the main isolate and hooked auth into the orchestrator's boot/teardown. Events now flow over the WebSocket while the app is in the foreground. But on Android 13+ (API 33+), the system-tray notification path is still broken: `FirebaseMessaging.requestPermission()` won't surface the OS dialog and no notification banner will appear, because the manifest is missing the `POST_NOTIFICATIONS` permission.

This session:

1. Closes **gap 7** of flag #7: adds `POST_NOTIFICATIONS` to `AndroidManifest.xml`.
2. Lands a defense-in-depth unit test on the auth ↔ orchestrator bridge so future refactors can't silently un-wire it.
3. Updates `flag.md`: strikes flag #7 as "Resolved for Android" and appends flag #8 to track the deferred iOS work.

iOS work (flag #7 step 5: `Info.plist` `UIBackgroundModes`, Push Notifications entitlement, APNs auth key upload) is **intentionally NOT done**. The user has no MacBook and the project is Android-only for the foreseeable future. Flag #8 captures the iOS work for a future Mac-equipped sprint.

There's also an **OPTIONAL fourth file** at the bottom of this document: a widget test that pumps the full `runApp` tree. Per the architectural review, this is the load-bearing safety net that would have prevented flag #7 from shipping in the first place — every existing realtime test exercises the stack via `ProviderContainer` and bypasses `runApp`, so no test catches missing wiring. The optional widget test requires non-trivial Firebase platform-channel mocking. Land it if smooth in your environment; otherwise document as a follow-up and ship Session 3 without it.

---

## Decisions taken

(Same decisions as Sessions 1 and 2.)

- **Q3 — iOS out of scope.** Confirmed by the user: no MacBook, Android-only. Flag #7 resolution is **scoped to Android**. New flag #8 opens for iOS.
- **Q5 — flag.md resolution at the end of Session 3.** Strike #7 as "Resolved for Android (date)" with a "What changed" block. Append a fresh flag #8 covering flag #7's step 5 plus the related Firebase-Console-side APNs key upload.

---

## Files this session touches

Floor (required):

1. `frontend/android/app/src/main/AndroidManifest.xml` — add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />`.
2. `frontend/test/features/auth/presentation/providers/auth_notifier_realtime_bridge_test.dart` — NEW unit test asserting boot/teardown bridge calls.
3. `flag.md` (repo root) — strike flag #7; append flag #8.

Optional (land if Firebase mocking goes smoothly):

4. `frontend/test/main_app_boot_widget_test.dart` — widget test pumping the full `runApp` tree. Requires `firebase_core_platform_interface` in dev deps and a small refactor of `main.dart` to extract a testable `buildAppRoot`. See "OPTIONAL: load-bearing widget test" at the bottom.

---

## Pre-flight

```bash
git checkout main
git pull                       # Sessions 1 and 2 should be in main
git checkout -b session-3-android-finalize

cd frontend
flutter pub get
flutter analyze                # clean baseline
flutter test                   # all existing tests pass
```

Re-read `flag.md` section 7 in full so the resolution entry you write later matches the existing flag conventions (struck-through heading, `✅ Resolved (YYYY-MM-DD)` line, "What changed" block). Confirm today's date via `date +%F` and use that in the resolution heading.

---

## File 1: `AndroidManifest.xml` (MODIFY — single line addition)

Open `frontend/android/app/src/main/AndroidManifest.xml`.

Currently (lines 1-3):
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

After:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

That's the only change in this file. **Do NOT add a manual `<service>` block for `FirebaseMessagingService`** — the FCM plugin's manifest-merger contributes those automatically.

### Confirming the merge after build
After your next `flutter run`, inspect the merged manifest at `frontend/build/app/intermediates/merged_manifests/<flavor>/AndroidManifest.xml` (the exact path varies by build flavor). Confirm:
- `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` is present.
- Several `<service>` blocks for `com.google.firebase.messaging.*` are present (added by the FCM plugin's merger).

---

## File 2: `auth_notifier_realtime_bridge_test.dart` (NEW)

This test catches the most likely regression: a future refactor of `AuthNotifier` that drops the `unawaited(bootAfterAuth(...))` calls without realizing the realtime stack depends on them. It does **not** mock Firebase or the WebSocket transport — it stops at the orchestrator's static method calls by spying on the providers the bridge would touch (`fcmHandlerProvider`, `wsConnectionProvider`, `eventSyncProvider`). When the bridge fires correctly, those mocks see `initialize()` and `connect(token)` calls; when it doesn't, the test fails.

### Why this approach
Two options were considered:
- **Option A** — extract `bootAfterAuth`/`teardownOnLogout` to an injected interface, mock the interface. Large refactor; rejected per Q2 decision (accept the cycle, don't introduce a bridge file).
- **Option B** — assert observable side-effects: spy on the providers the bridge touches.

Option B keeps the production code shape exactly as Session 2 left it, with no testing-only seams in `app_lifecycle_orchestrator.dart`.

### Test directory
Per CLAUDE.md → "Test directory mirrors `lib/` exactly", the test path mirrors the production file:
- Production: `frontend/lib/features/auth/presentation/providers/auth_notifier.dart`
- Test: `frontend/test/features/auth/presentation/providers/auth_notifier_realtime_bridge_test.dart`

### Test file scaffold

Create the file with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/presentation/notifiers/event_sync_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/core/realtime/presentation/services/fcm_handler.dart';
import 'package:frontend/features/auth/domain/entities/user_entity.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements IAuthRepository {}
class _MockFcmHandler extends Mock implements FCMHandler {}
class _MockWsConnection extends Mock implements WsConnectionNotifier {}
class _MockSystemEvent extends Mock implements SystemEventNotifier {}
class _MockEventSync extends Mock implements EventSyncNotifier {}

void main() {
  late _MockAuthRepository authRepo;
  late _MockFcmHandler fcm;
  late _MockWsConnection ws;
  late _MockSystemEvent sysEvents;
  late _MockEventSync sync;

  setUpAll(() {
    // Adjust the `UserEntity` constructor call below to match your real
    // entity's required fields. Inspect `lib/features/auth/domain/entities/
    // user_entity.dart` if this fails to compile.
    registerFallbackValue(
      const UserEntity(
        id: 0,
        phone: '',
        firstName: null,
        lastName: null,
        token: null,
        nameRequired: false,
        isTechnician: false,
      ),
    );
  });

  setUp(() {
    authRepo = _MockAuthRepository();
    fcm = _MockFcmHandler();
    ws = _MockWsConnection();
    sysEvents = _MockSystemEvent();
    sync = _MockEventSync();

    when(() => fcm.initialize()).thenAnswer((_) async {});
    when(() => fcm.unregister()).thenAnswer((_) async {});
    when(() => ws.connect(any())).thenAnswer((_) async {});
    when(() => ws.disconnect()).thenReturn(null);
    when(() => sysEvents.reset()).thenReturn(null);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          fcmHandlerProvider.overrideWithValue(fcm),
          // Note: the override APIs for code-gen `@riverpod` providers vary
          // by Riverpod version. If `overrideWith(() => mock)` doesn't
          // compile for these notifiers, switch to the form your project
          // uses elsewhere (grep test/ for `overrideWith` examples).
          wsConnectionProvider.overrideWith(() => ws),
          systemEventProvider.overrideWith(() => sysEvents),
          eventSyncProvider.overrideWith(() => sync),
        ],
      );

  group('AuthNotifier realtime bridge', () {
    test('build() with cached user+token triggers bootAfterAuth', () async {
      const user = UserEntity(
        id: 1,
        phone: '+923001234567',
        firstName: 'Test',
        lastName: 'User',
        token: 'abc123',
        nameRequired: false,
        isTechnician: true,
      );
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => user);

      final container = makeContainer();
      // Warm-up: wait for build() to finish.
      await container.read(authProvider.future);
      // Boot is fire-and-forget — give the microtask queue a tick.
      await Future<void>.delayed(Duration.zero);

      verify(() => fcm.initialize()).called(1);
      verify(() => ws.connect('abc123')).called(1);

      container.dispose();
    });

    test('build() with no cached user does not trigger boot', () async {
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => null);

      final container = makeContainer();
      await container.read(authProvider.future);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => fcm.initialize());
      verifyNever(() => ws.connect(any()));

      container.dispose();
    });

    test('logout() runs WS disconnect BEFORE auth repo logout', () async {
      const user = UserEntity(
        id: 1,
        phone: '+923001234567',
        firstName: 'Test',
        lastName: 'User',
        token: 'abc123',
        nameRequired: false,
        isTechnician: true,
      );
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => user);
      when(() => authRepo.logout()).thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(authProvider.future);
      await Future<void>.delayed(Duration.zero);

      // Reset call history captured during boot.
      clearInteractions(ws);
      clearInteractions(fcm);
      clearInteractions(authRepo);

      await container.read(authProvider.notifier).logout();

      // The load-bearing ordering invariant from CLAUDE.md / flag #7:
      // teardown's WS disconnect must precede the auth repo's logout
      // (which clears the token from secure storage).
      verifyInOrder([
        () => ws.disconnect(),
        () => authRepo.logout(),
      ]);

      container.dispose();
    });
  });
}
```

### If imports don't resolve
Adjust them to match your codebase. Likely friction points:

- **`UserEntity` constructor signature**: open `lib/features/auth/domain/entities/user_entity.dart` and match the fields. The test scaffold above guesses common fields (`firstName`, `lastName`, `token`, `nameRequired`, `isTechnician`); your actual entity may differ.
- **`IAuthRepository` interface name**: if the abstract class is `AuthRepository` (not `IAuthRepository`), update the mock declaration.
- **`overrideWith(() => mock)` for code-gen notifiers**: this depends on the Riverpod version. If it doesn't compile, look at any existing test in `frontend/test/` that overrides a `@riverpod class` notifier and copy that pattern. Common alternatives:
  ```dart
  // Some Riverpod versions use overrideWithValue:
  wsConnectionProvider.overrideWithValue(ws),
  ```

If after 30 minutes you can't get the override pattern right for `WsConnectionNotifier`/`SystemEventNotifier`/`EventSyncNotifier`, scope the test down to just the `fcmHandlerProvider` (which uses a plain `Provider`, easy to override) and verify only `fcm.initialize()` was called. That's a weaker assertion but still catches the most common regression (bridge calls dropped entirely).

---

## File 3: `flag.md` (MODIFY — strike #7, append #8)

Today's date: confirm via `date +%F`. The example below uses `2026-05-01`; replace with the actual date when you do this.

### Strike flag #7 (partial — Android only)

Find the heading at `flag.md` line ~116:
```markdown
## 7. Realtime stack defined but never mounted in app boot
```

Change to:
```markdown
## ~~7. Realtime stack defined but never mounted in app boot~~ ✅ Resolved for Android (2026-05-01)
```

Insert a "What changed" block at the top of flag #7's body (right under the new heading, before the existing "Where" section — which can stay as historical context, or you can remove it if you prefer the resolution to be terminal):

```markdown
**What changed**
- `main.dart` initializes Firebase on the main isolate and registers
  `firebaseMessagingBackgroundHandler` before `runApp`. The bootstrap is
  wrapped in an `AppLifecycleOrchestrator` that owns the realtime
  subsystem's runtime wiring (lifecycle observer, `EventUrgencyRouter`).
- `core/realtime/presentation/providers/dependency_injection.dart` exposes
  shared `navigatorKeyProvider` / `scaffoldMessengerKeyProvider`. Both
  `MaterialApp.router` and `GoRouter` (`core/routing/app_router.dart`) read
  the same provider so banners and route pushes target the live tree.
- `app_lifecycle_orchestrator.dart`: `bootAfterAuth` and `teardownOnLogout`
  signatures changed from `WidgetRef` → `Ref` so they're callable from
  `Notifier.build()`.
- `auth_notifier.dart` calls `unawaited(bootAfterAuth(...))` from `build()`
  (cold-start with cached user) and from `verifyOtp` (fresh login). Boot is
  fire-and-forget — awaiting it would stall auth on the WS handshake. On
  `logout()`, `teardownOnLogout` is `await`ed BEFORE `repository.logout()`
  so the WS device-unregister hits the server with a still-valid token.
- `android/app/src/main/AndroidManifest.xml` declares `POST_NOTIFICATIONS`
  so Android 13+ surfaces the runtime permission dialog via
  `FCMHandler.requestPermission()` and the system tray banner appears on
  FCM messages.
- New unit test `test/features/auth/presentation/providers/auth_notifier_
  realtime_bridge_test.dart` asserts that `build()` fires boot and
  `logout()` orders WS disconnect before repo logout.

**Out of scope, deferred** — iOS native capabilities (Info.plist
`UIBackgroundModes`, Push Notifications entitlement, APNs auth key upload)
are NOT addressed. The project is Android-only for now (no Mac in the
development environment). Tracked separately as flag #8.
```

If you want to keep flag #7's original "What's wrong / Why we shipped it that way / The proper fix" body for historical context, leave them in place under the "What changed" block. Per CLAUDE.md ("Resolved flags get struck through with an ✅ Resolved (date) line and short 'What changed' summary; never delete"), keeping them is the safer default.

### Append flag #8

At the bottom of `flag.md`, after flag #7's closing `---`, append:

```markdown
---

## 8. iOS realtime push capabilities

**Where**
- `frontend/ios/Runner/Info.plist`
- `frontend/ios/Runner/Runner.xcodeproj/project.pbxproj` (Push Notifications
  capability toggle)
- `frontend/ios/Runner/Runner.entitlements` (created when the capability
  toggle runs)
- Firebase Console → Project Settings → Cloud Messaging → Apple app
  configuration (APNs auth key upload — out-of-band, not code-tracked)

**What's wrong**
The realtime stack is wired correctly on the main isolate (flag #7), but on
iOS, FCM cannot deliver background or terminated-state messages because:

1. `Info.plist` has no `UIBackgroundModes` array containing
   `remote-notification`. iOS will not wake the app for background data
   messages without it.
2. The Push Notifications capability is not enabled in `Runner.xcodeproj`.
   `Info.plist` alone doesn't switch this on; Xcode also needs an
   `aps-environment` entitlement.
3. APNs auth key has not been uploaded to Firebase Console. Without it,
   FCM cannot translate Cloud Messages to APNs.

**Why we shipped it that way**
The development environment is Linux-only (no MacBook), and the project's
target market is Android-only for the foreseeable future. iOS support is
deferred until a Mac-equipped sprint.

**The proper fix**
1. On a Mac with Xcode:
   - Open `frontend/ios/Runner.xcworkspace`.
   - Select `Runner` target → Signing & Capabilities → `+ Capability` →
     Push Notifications. This generates `Runner.entitlements` with
     `aps-environment`.
   - `+ Capability` → Background Modes → check `Remote notifications`.
     Xcode writes the `UIBackgroundModes` array into `Info.plist`.
2. In Firebase Console → Project Settings → Cloud Messaging → Apple app
   configuration, upload the APNs auth key (`.p8` file from Apple Developer
   Portal under Keys → Apple Push Notifications service).
3. Build & install on a real iOS device (simulator can't test push).
   Verify the FCM permission prompt fires and a system-tray notification
   appears for a `job_new_request` event dispatched from the Django shell.
4. Confirm the BG handler isolate cold-launches correctly — tap a
   notification while the app is killed, verify the route push to
   `/technician/incoming-job-request` fires after `getInitialMessage()`
   returns the payload.

**Search hints**
- `Runner.entitlements` — should appear at
  `frontend/ios/Runner/Runner.entitlements` after the capability toggle.
- `UIBackgroundModes` — search `Info.plist` to confirm the array landed.
- The `.p8` APNs key never goes in the repo — it lives only in Firebase
  Console and Apple Developer Portal.

**Severity**
Blocking for any iOS production rollout. Not blocking for the current
Android-only target.
```

---

## Verification

### 1. Static analysis & test suite
```bash
cd frontend
flutter analyze
flutter test                   # the new bridge test should pass
```
Both clean.

### 2. Android permission prompt fires
- Run on an **Android 13+ device or emulator** (API 33+). Pre-API-33 devices don't have a runtime `POST_NOTIFICATIONS` concept and skip this dialog.
- Cold-launch the app, log in.
- Expected: a system permission dialog appears asking for notification access. This is `POST_NOTIFICATIONS` requested via `FCMHandler.requestPermission()` → `FirebaseMessaging.requestPermission()`.
- Grant the permission.

If the dialog does NOT appear:
- Check the merged manifest: `frontend/build/app/intermediates/merged_manifests/.../AndroidManifest.xml` — search for `POST_NOTIFICATIONS`. If absent, your edit didn't take. Run `flutter clean && flutter run`.
- Check device API level: `adb shell getprop ro.build.version.sdk`. Must be ≥33.

### 3. End-to-end push notification (system tray, backgrounded app)
- Foreground the app, log in (grant notification permission if prompted).
- Press home (background but don't kill).
- From Django shell:

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
        'address_line': 'Test',
    },
)
```

A system-tray notification should appear on the device within ~1-2s. Tap it → app foregrounds and routes to `/technician/incoming-job-request`.

If the WS path delivers in-app but the system tray doesn't:
- Confirm the FCM device token registered with Django (Django console should show a device-register POST after login from Session 2's verification).
- Check that the backend dispatcher is calling FCM Send when WS push fails (offline / app closed). Confirm with a Django log line on the dispatch path.
- Verify Firebase project's Cloud Messaging API is enabled in Google Cloud Console.

### 4. Terminated-state delivery
- Force-kill the app (long-press the app card, swipe away).
- Trigger the same Django shell event.
- A system-tray notification appears.
- Tap it → app cold-launches and routes to `/technician/incoming-job-request`.

This exercises `firebaseMessagingBackgroundHandler` (which writes the event into `event_sync_pending_bg_events` storage) AND `getInitialMessage()` on cold-launch. If the route push doesn't happen on cold-launch even though the notification appeared, the BG handler is running but its event isn't being drained on resume — `AppLifecycleOrchestrator._onResumed` calls `fcmHandler.processPendingBackgroundEvents()` which should drain the queue. Confirm this path runs at cold launch (the `_onResumed` call fires on the first `AppLifecycleState.resumed` transition, which happens immediately after cold launch on Android).

### 5. Logout cleanup
- Log out.
- Trigger the Django shell event for the same user.
- Expected: **no** notification appears (FCM device unregistered as part of teardown).
- Log back in.
- Trigger event again — notification reappears (re-registered).

### 6. Confirm flag.md is updated
- Open `flag.md` at the repo root.
- Verify flag #7 is struck-through with `✅ Resolved for Android (date)`.
- Verify "What changed" block is present.
- Verify flag #8 (iOS) is appended at the bottom.
- Markdown renders cleanly (no broken syntax) in your editor's preview.

---

## OPTIONAL: load-bearing widget test

> Land if practical (~30 minutes of work). Otherwise document as a follow-up issue and ship Session 3 without it.

The architectural review identified this gap: every existing realtime test exercises the stack via direct `ProviderContainer` calls — no test calls `runApp`, so no test catches the missing-wiring class of bug that allowed flag #7 to ship. Closing flag #7 without adding a test that pumps `runApp` means the same gap can reopen silently if a future refactor unwires `main.dart`.

The challenge is that `Firebase.initializeApp()` requires a real platform-channel response. In tests, you mock the channel.

### Step 1 — Add dev dep
In `frontend/pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  firebase_core_platform_interface: ^5.4.0    # match your firebase_core's interface version
  # ... existing dev deps
```

Run `flutter pub get`. If the version constraint doesn't resolve, check what `firebase_core: ^4.7.0` pulls in transitively and pin to that:
```bash
flutter pub deps | grep firebase_core_platform_interface
```

### Step 2 — Refactor `main.dart` to extract `buildAppRoot`

`main()` mixes async initialization with widget construction, which makes it hard to call from tests. Extract a synchronous `buildAppRoot` function so the test can pump just the widget tree.

In `frontend/lib/main.dart`, after the existing imports, add:

```dart
Widget buildAppRoot({required SharedPreferences sharedPreferences}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: const _Bootstrap(),
  );
}
```

And refactor `main()` to call it:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(buildAppRoot(sharedPreferences: sharedPreferences));
}
```

This is a behaviour-preserving refactor — production runtime is identical.

### Step 3 — Write the widget test

Create `frontend/test/main_app_boot_widget_test.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall call) async {
      switch (call.method) {
        case 'Firebase#initializeCore':
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'mock',
                'appId': 'mock',
                'messagingSenderId': 'mock',
                'projectId': 'mock',
              },
              'pluginConstants': <String, dynamic>{},
            }
          ];
        case 'Firebase#initializeApp':
          return {
            'name': call.arguments['appName'],
            'options': call.arguments['options'],
            'pluginConstants': <String, dynamic>{},
          };
        default:
          return null;
      }
    },
  );
}

void main() {
  setUpAll(() async {
    _setupFirebaseCoreMocks();
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp();
  });

  testWidgets('runApp tree boots without throwing', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildAppRoot(sharedPreferences: prefs));
    // The router redirects to /login when there's no cached user. We just
    // need the tree to construct without exceptions.
    expect(tester.takeException(), isNull);
  });
}
```

This test:
- Mocks the `firebase_core` platform channel so `Firebase.initializeApp()` succeeds without a real Firebase project.
- Mocks `SharedPreferences` with empty initial values.
- Pumps `buildAppRoot` (the extracted widget tree).
- Asserts no exception was thrown during build.

It does **not** exercise login, event delivery, or FCM — those are unit-tested separately. Its single value is regression coverage: if a future refactor unwires `Firebase.initializeApp()` from `main.dart`, the orchestrator from the tree, or the messenger key from `MaterialApp.router`, the pump throws and this test fails loudly.

### If `firebase_messaging` mocking is also required
On some FCM versions, importing `firebase_messaging` triggers extra platform-channel calls during init. If the test hits a `MissingPluginException` for `plugins.flutter.io/firebase_messaging`, add a similar mock handler for that channel — return `null` for all method calls. Or, more aggressively, swap the explicit FCM-related call in `main.dart` to a no-op variant under test (controlled via a `bool isTest` parameter to `buildAppRoot`).

If after 30 minutes you can't get this test green, add a follow-up flag (#9) documenting the deferral and ship Session 3 without it. The bridge unit test in File 2 still provides meaningful coverage.

---

## Definition of done

- [ ] `flutter analyze` clean.
- [ ] `flutter test` passes (including the new `auth_notifier_realtime_bridge_test.dart` and, if landed, the optional widget test).
- [ ] Android `POST_NOTIFICATIONS` runtime dialog fires on Android 13+ device on first logged-in launch.
- [ ] System-tray notification appears for a backgrounded app on a `job_new_request` event from the Django shell.
- [ ] Tapping a system-tray notification on a force-killed app cold-launches the app and routes to `/technician/incoming-job-request`.
- [ ] Logout fully unregisters FCM (no notification on subsequent events until re-login).
- [ ] `flag.md`: flag #7 struck-through with `✅ Resolved for Android (date)` heading and "What changed" block. Flag #8 (iOS) appended at the bottom.
- [ ] Three to four files modified, no others changed.
- [ ] Commit message: `feat(realtime): close flag #7 for Android — manifest + bridge test + flag log update`.

When done, the realtime stack is fully alive on Android. iOS work is deferred to flag #8 for a future Mac-equipped sprint.

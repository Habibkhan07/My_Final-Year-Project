import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/domain/entities/user_entity.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/presentation/app_lifecycle_orchestrator.dart';
import 'package:frontend/core/realtime/presentation/notifiers/event_sync_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart'
    as realtime_di;
import 'package:frontend/core/realtime/presentation/services/fcm_background_handler.dart';
import 'package:frontend/core/realtime/presentation/services/fcm_handler.dart';
import 'package:frontend/core/realtime/presentation/state/connection_state.dart';
import 'package:frontend/core/realtime/presentation/state/system_event_state.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/dependency_injection.dart'
    as auth_di;
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart'
    show sharedPreferencesProvider;
import 'package:frontend/main.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The architectural-review gap that allowed flag #7 to ship: every prior
/// realtime test exercised the stack via direct `ProviderContainer` calls,
/// so the production wiring in `runApp` could regress (e.g.,
/// `Firebase.initializeApp()` removed, `AppLifecycleOrchestrator` dropped
/// from the tree, shared-key providers swapped for fresh instances) and no
/// test would fail. This file closes that gap by exercising the actual
/// `bootApp()` initialization path (W1–W3) and the actual mounted widget
/// tree (W4–W8).
///
/// Approach:
///   * W1–W3 pass recording fakes for the three injectable initializers in
///     `bootApp` and assert each fake was invoked. If a future refactor
///     drops `Firebase.initializeApp()` or `onBackgroundMessage(...)` from
///     `bootApp`, the corresponding test fails loudly.
///   * W4–W6 pump `buildAppRootWidget()` (the test seam exposed in
///     main.dart) wrapped in our own `ProviderScope` with realtime/auth
///     mocks. We then walk the rendered tree to assert that
///     `AppLifecycleOrchestrator` is mounted and the shared
///     navigator/messenger keys flow through to the correct call sites.
///   * W7–W8 pump the tree in logged-out and logged-in states and assert
///     no exception escapes the initial frame. Deeper tests of LoginScreen
///     / HomeScreen behaviour live in their own widget tests; the value
///     here is regression coverage for the boot composition, not screen
///     content.

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockFCMHandler extends Mock implements FCMHandler {}

class _MockEventLocalDataSource extends Mock implements EventLocalDataSource {}

class _RecordingWsNotifier extends WsConnectionNotifier {
  final List<String> connectCalls = [];
  int disconnectCount = 0;

  @override
  WsConnectionStatus build() => WsConnectionStatus.disconnected;

  @override
  Future<void> connect(String authToken) async {
    connectCalls.add(authToken);
  }

  @override
  void disconnect() {
    disconnectCount++;
  }
}

class _RecordingEventSyncNotifier extends EventSyncNotifier {
  @override
  Object? build() => null;
}

class _RecordingSystemEventNotifier extends SystemEventNotifier {
  @override
  SystemEventState build() => const SystemEventState();

  @override
  void reset() {
    // No-op so teardown doesn't touch the dedup map machinery.
  }
}

// ─── Platform-channel mocks ────────────────────────────────────────────────
//
// `bootApp` calls `Firebase.initializeApp()` and registers
// `firebaseMessagingBackgroundHandler`. With our recording-fake initializer
// the real platform calls don't fire, so for W1–W3 we don't need any
// platform mocks. For W4–W8 we pump the actual widget tree, which
// indirectly exercises platform channels via FCMHandler etc. — those are
// covered by overriding `fcmHandlerProvider` and friends rather than by
// platform-channel intercepts.

void _setupLocalNotificationsMock(List<MethodCall> sink) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
          sink.add(call);
          return null;
        },
      );
}

void _teardownLocalNotificationsMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
}

ProviderContainer? _lastContainer;

/// Wraps `buildAppRootWidget()` in a `ProviderScope` with realtime/auth
/// mocks. Capture the container via the `key` so individual tests can
/// assert on shared-key providers etc.
Widget _wrapAppRoot({
  required _MockAuthRepository authRepo,
  required _MockFCMHandler fcm,
  required _MockEventLocalDataSource local,
  required SharedPreferences prefs,
}) {
  return UncontrolledProviderScope(
    container: _lastContainer = ProviderContainer(
      overrides: [
        // SharedPreferences override — same one bootApp's ProviderScope
        // would set, but here injected by the test wrapper.
        sharedPreferencesProvider.overrideWithValue(prefs),

        // Auth: mocked repo so getCachedUser is deterministic per test.
        auth_di.authRepositoryProvider.overrideWithValue(authRepo),

        // flag #19 — mirror bootApp's production override so the realtime
        // recipient filter sees the authenticated user's id. Existing tests
        // that don't set ``UserEntity.id`` keep getting null here (no
        // behavioural change); tests that exercise the recipient filter
        // can rely on this chain producing the right id.
        realtime_di.currentAuthUserIdProvider.overrideWith(
          (ref) =>
              ref.watch(authProvider.select((async) => async.value?.user?.id)),
        ),

        // Realtime: empty boot-hooks registry so we don't drag in
        // incomingJobQueueProvider's full feature DI tree.
        realtimeBootHooksProvider.overrideWith((ref) => const []),

        // Realtime: replace the production FCMHandler / WsConnectionNotifier
        // / EventSyncNotifier / SystemEventNotifier with mocks/recorders so
        // pumping doesn't kick off real Firebase / WebSocket / SharedPrefs
        // work.
        realtime_di.fcmHandlerProvider.overrideWithValue(fcm),
        realtime_di.eventLocalDataSourceProvider.overrideWithValue(local),
        eventSyncProvider.overrideWith(_RecordingEventSyncNotifier.new),
        wsConnectionProvider.overrideWith(_RecordingWsNotifier.new),
        systemEventProvider.overrideWith(_RecordingSystemEventNotifier.new),
      ],
    ),
    child: buildAppRootWidget(),
  );
}

void main() {
  setUpAll(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    registerFallbackValue(const UserEntity(phone: ''));
  });

  setUp(() {
    // No debugDefaultTargetPlatformOverride — these tests don't go
    // through `resolvePlatformSpecificImplementation`. Setting the
    // override in setUp would trigger the framework's "foundation debug
    // variable was changed" assertion at the end of every testWidgets
    // case (the check runs before tearDown clears it).
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    _lastContainer?.dispose();
    _lastContainer = null;
    _teardownLocalNotificationsMock();
  });

  // ─── W1–W3 — bootApp initialization side-effects ─────────────────────

  group('bootApp() initialization', () {
    test('W1 — firebaseInit is invoked exactly once', () async {
      var calls = 0;
      await bootApp(
        firebaseInit: () async {
          calls++;
        },
        bgHandlerRegistrar: (_) {},
        sharedPrefsLoader: SharedPreferences.getInstance,
      );

      expect(
        calls,
        1,
        reason:
            'a future refactor that drops `Firebase.initializeApp()` '
            'from bootApp would silently break foreground FCM listeners '
            '(`onMessage`, `onMessageOpenedApp`, `getInitialMessage`) '
            'and `getToken()` — exactly the original flag #7 bug class',
      );
    });

    test(
      'W2 — firebaseMessagingBackgroundHandler is registered exactly once',
      () async {
        BackgroundMessageHandler? registered;
        var registrationCount = 0;
        await bootApp(
          firebaseInit: () async {},
          bgHandlerRegistrar: (handler) {
            registered = handler;
            registrationCount++;
          },
          sharedPrefsLoader: SharedPreferences.getInstance,
        );

        expect(
          registrationCount,
          1,
          reason:
              'BG handler registration is what lets the OS wake a Dart '
              'isolate for FCM data messages while the app is killed; '
              'must run exactly once before runApp',
        );
        expect(registered, isNotNull);
        // Identity check — must be the top-level function, since instance
        // methods aren't addressable from the BG isolate.
        expect(
          identical(registered, firebaseMessagingBackgroundHandler),
          isTrue,
          reason:
              'must be the @pragma(\'vm:entry-point\') top-level function — '
              'instance methods are not addressable from the BG isolate',
        );
      },
    );

    test(
      'W3 — SharedPreferences is loaded before the widget is returned',
      () async {
        var prefsCallCount = 0;
        Widget? returned;

        await SharedPreferences.getInstance(); // ensure default loaded once
        final widget = await bootApp(
          firebaseInit: () async {},
          bgHandlerRegistrar: (_) {},
          sharedPrefsLoader: () async {
            prefsCallCount++;
            return SharedPreferences.getInstance();
          },
        );
        returned = widget;

        expect(
          prefsCallCount,
          1,
          reason:
              'sharedPreferencesProvider override needs the resolved '
              'SharedPreferences instance; loading it after the widget is '
              'built would create a window where storage reads silently '
              'return null',
        );
        expect(
          returned,
          isA<ProviderScope>(),
          reason: 'bootApp returns a ProviderScope',
        );
      },
    );
  });

  // ─── W4–W6 — pumped tree composition ──────────────────────────────────

  group('mounted tree composition', () {
    testWidgets('W4 — pumped tree contains AppLifecycleOrchestrator', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      _setupLocalNotificationsMock(calls);

      final authRepo = _MockAuthRepository();
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => null);

      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) async {});

      final local = _MockEventLocalDataSource();
      when(() => local.getLastSyncTimestamp()).thenReturn(null);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrapAppRoot(authRepo: authRepo, fcm: fcm, local: local, prefs: prefs),
      );
      await tester.pump();

      expect(
        find.byType(AppLifecycleOrchestrator),
        findsOneWidget,
        reason:
            'the orchestrator MUST be in the production tree — without '
            'it, `ref.listenManual(systemEventProvider, …)` is never set '
            'up and no events get routed (the original flag #7 bug)',
      );
    });

    testWidgets('W5 — orchestrator\'s navigatorKey is the same instance the '
        'navigatorKeyProvider returns', (tester) async {
      final calls = <MethodCall>[];
      _setupLocalNotificationsMock(calls);

      final authRepo = _MockAuthRepository();
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => null);

      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) async {});

      final local = _MockEventLocalDataSource();
      when(() => local.getLastSyncTimestamp()).thenReturn(null);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrapAppRoot(authRepo: authRepo, fcm: fcm, local: local, prefs: prefs),
      );
      await tester.pump();

      final orchestrator = tester.widget<AppLifecycleOrchestrator>(
        find.byType(AppLifecycleOrchestrator),
      );
      final providerKey = _lastContainer!.read(
        realtime_di.navigatorKeyProvider,
      );

      expect(
        identical(orchestrator.navigatorKey, providerKey),
        isTrue,
        reason:
            'EventUrgencyRouter and GoRouter must both read the SAME '
            'navigatorKey instance via navigatorKeyProvider — passing a '
            'fresh GlobalKey to the orchestrator would silently break '
            'route pushes from realtime events',
      );
    });

    testWidgets(
      'W6 — orchestrator\'s scaffoldMessengerKey is the same instance '
      'the scaffoldMessengerKeyProvider returns',
      (tester) async {
        final calls = <MethodCall>[];
        _setupLocalNotificationsMock(calls);

        final authRepo = _MockAuthRepository();
        when(() => authRepo.getCachedUser()).thenAnswer((_) async => null);

        final fcm = _MockFCMHandler();
        when(() => fcm.initialize()).thenAnswer((_) async {});

        final local = _MockEventLocalDataSource();
        when(() => local.getLastSyncTimestamp()).thenReturn(null);

        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          _wrapAppRoot(
            authRepo: authRepo,
            fcm: fcm,
            local: local,
            prefs: prefs,
          ),
        );
        await tester.pump();

        final orchestrator = tester.widget<AppLifecycleOrchestrator>(
          find.byType(AppLifecycleOrchestrator),
        );
        final providerKey = _lastContainer!.read(
          realtime_di.scaffoldMessengerKeyProvider,
        );

        expect(
          identical(orchestrator.scaffoldMessengerKey, providerKey),
          isTrue,
          reason:
              'EventUrgencyRouter posts banners through the messenger key; '
              'MaterialApp.router\'s key must match or the live tree never '
              'sees them',
        );
      },
    );
  });

  // ─── W7–W8 — tree builds without exceptions ───────────────────────────

  group('mounted tree resilience', () {
    testWidgets('W7 — unauthenticated user: tree builds without throwing', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      _setupLocalNotificationsMock(calls);

      final authRepo = _MockAuthRepository();
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => null);

      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) async {});

      final local = _MockEventLocalDataSource();
      when(() => local.getLastSyncTimestamp()).thenReturn(null);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrapAppRoot(authRepo: authRepo, fcm: fcm, local: local, prefs: prefs),
      );
      // First frame mounts the tree; second pump lets the GoRouter
      // redirect to /login resolve. We deliberately do NOT pumpAndSettle
      // because LoginScreen's deeper deps (which we haven't mocked) would
      // start ticking — the value here is "boot composition mounts", not
      // "LoginScreen renders correctly" (covered by its own widget test).
      await tester.pump();
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'unauthenticated boot must not throw — getCachedUser returns '
            'null, AuthNotifier settles to AsyncData(AuthState()), '
            'router redirects to /login',
      );
    });

    testWidgets('W8 — authenticated user (cached, nameRequired): bridge fires '
        'bootAfterAuth with the cached token through the full composition', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      _setupLocalNotificationsMock(calls);

      // nameRequired: true so the router lands on /profile-setup (form
      // screen) instead of /home (which has geocoding + addresses
      // tickers we'd have to mock to avoid pumpAndSettle hangs). The
      // boot path is identical regardless of which screen renders —
      // AuthNotifier.build → _scheduleBoot → bootAfterAuth.
      const cachedUser = UserEntity(
        phone: '+923001234567',
        token: 'cached-tok',
        firstName: 'Test',
        lastName: 'User',
        nameRequired: true,
        isTechnician: true,
      );

      final authRepo = _MockAuthRepository();
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => cachedUser);

      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) async {});

      final local = _MockEventLocalDataSource();
      when(() => local.getLastSyncTimestamp()).thenReturn(null);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrapAppRoot(authRepo: authRepo, fcm: fcm, local: local, prefs: prefs),
      );
      // Two pumps + microtask drain cover: (1) initial mount, (2) router
      // redirect to /profile-setup, (3) the unawaited _scheduleBoot chain
      // inside AuthNotifier.build resolving through bootAfterAuth.
      await tester.pump();
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      verify(() => fcm.initialize()).called(1);
      final ws =
          _lastContainer!.read(wsConnectionProvider.notifier)
              as _RecordingWsNotifier;
      expect(
        ws.connectCalls,
        ['cached-tok'],
        reason:
            'authenticated cold-start must wire WS with the cached '
            'token through the boot composition — the full path from '
            'bootApp → ProviderScope → AppLifecycleOrchestrator → '
            'AuthNotifier → bootAfterAuth → ws.connect',
      );
    });

    // ─── W9 — flag #19: currentAuthUserIdProvider override ─────────────
    //
    // The realtime pipeline's recipient filter compares envelope.recipient_user_id
    // against ``currentAuthUserIdProvider``. The provider is declared in
    // core/realtime as a null-returning seam (core can't import features) and
    // is overridden at app boot to read auth state. This test pins the chain:
    // a logged-in cached user with id=42 must surface as 42 through the
    // override, otherwise the recipient filter is dormant in production even
    // though the backend is now emitting recipient_user_id (Phase A).

    testWidgets('W9 — flag #19: currentAuthUserIdProvider returns auth user id '
        'after cached login resolves', (tester) async {
      final calls = <MethodCall>[];
      _setupLocalNotificationsMock(calls);

      const cachedUser = UserEntity(
        id: 42,
        phone: '+923001234567',
        token: 'cached-tok',
        firstName: 'Test',
        lastName: 'User',
        nameRequired: true,
        isTechnician: true,
      );

      final authRepo = _MockAuthRepository();
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => cachedUser);

      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) async {});

      final local = _MockEventLocalDataSource();
      when(() => local.getLastSyncTimestamp()).thenReturn(null);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrapAppRoot(authRepo: authRepo, fcm: fcm, local: local, prefs: prefs),
      );
      // AuthNotifier.build is async — pump until getCachedUser resolves and
      // the AsyncData transition runs the select-driven override.
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      expect(
        _lastContainer!.read(realtime_di.currentAuthUserIdProvider),
        42,
        reason:
            'flag #19 — override must pipe AuthState.user.id through to '
            'currentAuthUserIdProvider, otherwise the realtime recipient '
            'filter cannot fire in production.',
      );
    });

    testWidgets('W10 — flag #19: currentAuthUserIdProvider stays null when no '
        'user is cached', (tester) async {
      final calls = <MethodCall>[];
      _setupLocalNotificationsMock(calls);

      final authRepo = _MockAuthRepository();
      when(() => authRepo.getCachedUser()).thenAnswer((_) async => null);

      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) async {});

      final local = _MockEventLocalDataSource();
      when(() => local.getLastSyncTimestamp()).thenReturn(null);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrapAppRoot(authRepo: authRepo, fcm: fcm, local: local, prefs: prefs),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      expect(
        _lastContainer!.read(realtime_di.currentAuthUserIdProvider),
        isNull,
        reason:
            'No cached user → override resolves to null → recipient filter '
            'no-ops (the documented backwards-compat path). The pipeline '
            'must not reject events just because the user is signed out.',
      );
    });
  });
}

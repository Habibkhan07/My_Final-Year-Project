import 'dart:async';

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
import 'package:frontend/core/realtime/presentation/services/fcm_handler.dart';
import 'package:frontend/core/realtime/presentation/state/connection_state.dart';
import 'package:frontend/core/realtime/presentation/state/system_event_state.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/use_cases/verify_otp_use_case.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/dependency_injection.dart'
    as auth_di;
import 'package:frontend/features/technician/location_broadcaster/presentation/providers/dependency_injection.dart'
    as location_broadcaster_di;
import 'package:frontend/features/technician/location_broadcaster/presentation/services/foreground_location_lifecycle.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockFCMHandler extends Mock implements FCMHandler {}

class _MockEventLocalDataSource extends Mock implements EventLocalDataSource {}

class _MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class _MockForegroundLocationLifecycle extends Mock
    implements ForegroundLocationLifecycle {}

// ─── Recording fakes for code-gen `@riverpod class` notifiers ────────────
//
// We can't `Mock` these via mocktail because Riverpod's `overrideWith`
// for class providers wants a constructor that returns an instance of
// the generated base class. Subclassing the real notifier and overriding
// just the methods the bridge touches lets the rest inherit, mirrors the
// pattern in `app_lifecycle_orchestrator_test.dart`.

class _RecordingWsNotifier extends WsConnectionNotifier {
  final List<String> connectCalls = [];
  int disconnectCount = 0;
  Completer<void>? blockConnect;

  @override
  WsConnectionStatus build() => WsConnectionStatus.disconnected;

  @override
  Future<void> connect(String authToken) async {
    connectCalls.add(authToken);
    if (blockConnect != null) await blockConnect!.future;
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
  int resetCalls = 0;

  @override
  SystemEventState build() => const SystemEventState();

  @override
  void reset() {
    resetCalls++;
    // Don't call super — the real reset() touches state in ways that
    // would require us to wire the dedup map, which is out of scope for
    // bridge tests. The contract we care about here is "reset was called
    // exactly once during teardown."
  }
}

// ─── Test scaffold ────────────────────────────────────────────────────────

class _Deps {
  _Deps()
    : authRepo = _MockAuthRepository(),
      fcm = _MockFCMHandler(),
      local = _MockEventLocalDataSource(),
      fgLifecycle = _MockForegroundLocationLifecycle(),
      verifyOtp = _MockVerifyOtpUseCase();

  final _MockAuthRepository authRepo;
  final _MockFCMHandler fcm;
  final _MockEventLocalDataSource local;
  final _MockForegroundLocationLifecycle fgLifecycle;
  final _MockVerifyOtpUseCase verifyOtp;
}

/// Pre-stubs every method the bridge exercises so individual tests don't
/// false-positive on a missing stub. Tests can override stubs as needed.
void _stubDefaults(_Deps deps) {
  when(() => deps.fcm.initialize()).thenAnswer((_) async {});
  when(() => deps.fcm.unregister()).thenAnswer((_) async {});
  when(() => deps.fgLifecycle.tearDown()).thenAnswer((_) async {});
  when(() => deps.local.clearLastSyncTimestamp()).thenAnswer((_) async {});
  when(() => deps.local.clearCachedEvents()).thenAnswer((_) async {});
  when(() => deps.local.clearPendingAcks()).thenAnswer((_) async {});
}

ProviderContainer _buildContainer(_Deps deps) {
  return ProviderContainer(
    overrides: [
      auth_di.authRepositoryProvider.overrideWithValue(deps.authRepo),
      auth_di.verifyOtpUseCaseProvider.overrideWithValue(deps.verifyOtp),

      // Default registries contain real tech + customer feature
      // providers; reading them would eagerly instantiate full feature
      // DI trees when bootAfterAuth walks them. Override both to `[]`
      // so this test stays narrow — the registry contract is covered
      // separately by R1/R2/R3 in `app_lifecycle_orchestrator_test.dart`.
      realtimeBootHooksProvider.overrideWith((ref) => const []),
      realtimeTechnicianBootHooksProvider
          .overrideWith((ref) => const []),

      realtime_di.fcmHandlerProvider.overrideWithValue(deps.fcm),
      realtime_di.eventLocalDataSourceProvider.overrideWithValue(deps.local),
      location_broadcaster_di.foregroundLocationLifecycleProvider
          .overrideWithValue(deps.fgLifecycle),

      // Code-gen notifier overrides — recording subclasses defined above.
      eventSyncProvider.overrideWith(_RecordingEventSyncNotifier.new),
      wsConnectionProvider.overrideWith(_RecordingWsNotifier.new),
      systemEventProvider.overrideWith(_RecordingSystemEventNotifier.new),
    ],
  );
}

/// Drains the microtask queue. `_scheduleBoot` uses `unawaited(...)`, so
/// the bridge calls only land after the microtask that schedules them
/// runs. A single `Future.delayed(Duration.zero)` is enough because the
/// recording fakes complete synchronously.
Future<void> _drainMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(() {
    // Required by mocktail's `any()` matcher for `UserEntity`-typed args.
    // Phone is the only required field; everything else defaults.
    registerFallbackValue(const UserEntity(phone: ''));
  });

  // ─── Cold-start (build()) path ─────────────────────────────────────────

  group('build() — cold-start bridge', () {
    test(
      'A1 — cached user with non-empty token fires bootAfterAuth with that token',
      () async {
        final deps = _Deps();
        _stubDefaults(deps);
        const cachedUser = UserEntity(
          phone: '+923001234567',
          token: 'cached-tok',
          firstName: 'Test',
          lastName: 'User',
          isTechnician: true,
        );
        when(
          () => deps.authRepo.getCachedUser(),
        ).thenAnswer((_) async => cachedUser);

        final container = _buildContainer(deps);
        addTearDown(container.dispose);

        await container.read(authProvider.future);
        await _drainMicrotasks();

        verify(() => deps.fcm.initialize()).called(1);
        final ws =
            container.read(wsConnectionProvider.notifier)
                as _RecordingWsNotifier;
        expect(
          ws.connectCalls,
          ['cached-tok'],
          reason:
              'cold-start with cached user must boot the realtime stack '
              'with the cached token — original flag #7 bug class',
        );
      },
    );

    test('A2 — no cached user does not fire boot', () async {
      final deps = _Deps();
      _stubDefaults(deps);
      when(() => deps.authRepo.getCachedUser()).thenAnswer((_) async => null);

      final container = _buildContainer(deps);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await _drainMicrotasks();

      verifyNever(() => deps.fcm.initialize());
      final ws =
          container.read(wsConnectionProvider.notifier) as _RecordingWsNotifier;
      expect(
        ws.connectCalls,
        isEmpty,
        reason: 'launching logged-out must not open a ghost WS connection',
      );
    });

    test('A3 — cached user with null token does not fire boot', () async {
      final deps = _Deps();
      _stubDefaults(deps);
      const cachedUser = UserEntity(phone: '+923001234567');
      when(
        () => deps.authRepo.getCachedUser(),
      ).thenAnswer((_) async => cachedUser);

      final container = _buildContainer(deps);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await _drainMicrotasks();

      verifyNever(() => deps.fcm.initialize());
      final ws =
          container.read(wsConnectionProvider.notifier) as _RecordingWsNotifier;
      expect(
        ws.connectCalls,
        isEmpty,
        reason:
            '_scheduleBoot null-guard must prevent NPE in '
            'wsConnection.connect(null!)',
      );
    });

    test(
      'A4 — cached user with empty-string token does not fire boot',
      () async {
        final deps = _Deps();
        _stubDefaults(deps);
        const cachedUser = UserEntity(phone: '+923001234567', token: '');
        when(
          () => deps.authRepo.getCachedUser(),
        ).thenAnswer((_) async => cachedUser);

        final container = _buildContainer(deps);
        addTearDown(container.dispose);

        await container.read(authProvider.future);
        await _drainMicrotasks();

        verifyNever(() => deps.fcm.initialize());
        final ws =
            container.read(wsConnectionProvider.notifier)
                as _RecordingWsNotifier;
        expect(
          ws.connectCalls,
          isEmpty,
          reason:
              '_scheduleBoot empty-string guard prevents 4001/4003 backend '
              'kick on corrupted-cache token',
        );
      },
    );

    test(
      'A7 — getCachedUser throwing surfaces AsyncError without firing boot',
      () async {
        final deps = _Deps();
        _stubDefaults(deps);
        when(
          () => deps.authRepo.getCachedUser(),
        ).thenThrow(StateError('cache corrupted'));

        final container = _buildContainer(deps);
        addTearDown(container.dispose);

        // Awaiting .future re-throws the build()'s exception — we expect
        // exactly the StateError we stubbed and nothing else. After that,
        // state.hasError is reliably true.
        await expectLater(
          container.read(authProvider.future),
          throwsA(isA<StateError>()),
        );
        await _drainMicrotasks();

        final state = container.read(authProvider);
        expect(
          state.hasError,
          isTrue,
          reason: 'a cache failure must surface to UI as AsyncError',
        );

        verifyNever(() => deps.fcm.initialize());
        final ws =
            container.read(wsConnectionProvider.notifier)
                as _RecordingWsNotifier;
        expect(
          ws.connectCalls,
          isEmpty,
          reason: 'no half-state boot on cache corruption',
        );
      },
    );
  });

  // ─── Fresh-login (verifyOtp) path ──────────────────────────────────────

  group('verifyOtp() — fresh-login bridge', () {
    test(
      'A5 — verifyOtp success fires boot with the FRESH token, not a stale cached one',
      () async {
        final deps = _Deps();
        _stubDefaults(deps);

        // Seed cache with one user…
        const cachedUser = UserEntity(
          phone: '+923001234567',
          token: 'stale-cached-tok',
          isTechnician: true,
        );
        when(
          () => deps.authRepo.getCachedUser(),
        ).thenAnswer((_) async => cachedUser);

        // …and have verifyOtp return a *different* token. Production code
        // must pass the fresh token to bootAfterAuth, not whatever
        // state.value.user.token happens to be.
        const verifiedUser = UserEntity(
          phone: '+923001234567',
          token: 'fresh-verified-tok',
          isTechnician: true,
        );
        when(
          () => deps.verifyOtp.execute(any(), any()),
        ).thenAnswer((_) async => verifiedUser);

        final container = _buildContainer(deps);
        addTearDown(container.dispose);

        // Boot from cached user happens during initial build()…
        await container.read(authProvider.future);
        await _drainMicrotasks();

        final ws =
            container.read(wsConnectionProvider.notifier)
                as _RecordingWsNotifier;
        expect(ws.connectCalls, [
          'stale-cached-tok',
        ], reason: 'sanity: cold-start path used cached token');

        // …then verifyOtp lands and must boot with the FRESH token.
        await container
            .read(authProvider.notifier)
            .verifyOtp('+923001234567', '123456');
        await _drainMicrotasks();

        expect(
          ws.connectCalls,
          ['stale-cached-tok', 'fresh-verified-tok'],
          reason:
              'verifyOtp must pass the use-case-returned token to '
              'bootAfterAuth, not the previously-cached token. Catches '
              'the regression where someone passes state.value.user.token '
              'instead of the freshly-returned user.token.',
        );
        verify(() => deps.fcm.initialize()).called(2);
      },
    );

    test('A8 — requestOtp does not fire boot', () async {
      final deps = _Deps();
      _stubDefaults(deps);
      when(() => deps.authRepo.getCachedUser()).thenAnswer((_) async => null);
      when(
        () => deps.authRepo.requestOtp(any()),
      ).thenAnswer((_) async => 'sms sent');

      final container = _buildContainer(deps);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await container.read(authProvider.notifier).requestOtp('+923001234567');
      await _drainMicrotasks();

      verifyNever(() => deps.fcm.initialize());
      final ws =
          container.read(wsConnectionProvider.notifier) as _RecordingWsNotifier;
      expect(
        ws.connectCalls,
        isEmpty,
        reason: 'requestOtp issues no token; must not boot the stack',
      );
    });

    test('A9 — completeSignup does not fire boot', () async {
      final deps = _Deps();
      _stubDefaults(deps);
      const cachedUser = UserEntity(
        phone: '+923001234567',
        token: 'cached-tok',
        nameRequired: true,
      );
      when(
        () => deps.authRepo.getCachedUser(),
      ).thenAnswer((_) async => cachedUser);
      when(() => deps.authRepo.persistUser(any())).thenAnswer((_) async {});

      final container = _buildContainer(deps);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await _drainMicrotasks();

      // Boot fired once during build(). completeSignup should NOT re-boot —
      // boot already happened in verifyOtp / build, and re-booting would
      // double-subscribe.
      final ws =
          container.read(wsConnectionProvider.notifier) as _RecordingWsNotifier;
      final connectsBefore = ws.connectCalls.length;

      // Reset interaction history so verifyNever below counts only what
      // happens during completeSignup.
      clearInteractions(deps.fcm);
      _stubDefaults(deps);
      when(
        () => deps.authRepo.completeSignup(any(), any(), any()),
      ).thenAnswer((_) async => 'signup complete');
      when(() => deps.authRepo.persistUser(any())).thenAnswer((_) async {});

      await container
          .read(authProvider.notifier)
          .completeSignup('First', 'Last');
      await _drainMicrotasks();

      expect(
        ws.connectCalls.length,
        connectsBefore,
        reason:
            'completeSignup must not re-boot — boot already happened on '
            'cold-start with cached user; double-boot would double-'
            'subscribe to systemEventProvider',
      );
      verifyNever(() => deps.fcm.initialize());
    });
  });

  // ─── Logout teardown ───────────────────────────────────────────────────

  group('logout() — teardown bridge', () {
    test('A6 — logout runs FULL teardown (ws.disconnect → fcm.unregister → '
        'sysEvent.reset → local.clear* → onUnauthorized=null) BEFORE '
        'repository.logout()', () async {
      final deps = _Deps();
      _stubDefaults(deps);
      const cachedUser = UserEntity(
        phone: '+923001234567',
        token: 'tok',
        isTechnician: true,
      );
      when(
        () => deps.authRepo.getCachedUser(),
      ).thenAnswer((_) async => cachedUser);
      when(() => deps.authRepo.logout()).thenAnswer((_) async {});

      final container = _buildContainer(deps);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await _drainMicrotasks();

      // Wire onUnauthorized so we can pin its null-out at teardown tail.
      // bootAfterAuth's own assignment may have already happened, but we
      // re-set to a sentinel we can identify.
      final eventSync =
          container.read(eventSyncProvider.notifier)
              as _RecordingEventSyncNotifier;
      eventSync.onUnauthorized = () {};

      // Reset interaction history so verifyInOrder counts only logout()'s
      // calls, not anything from the boot phase.
      clearInteractions(deps.fcm);
      clearInteractions(deps.fgLifecycle);
      clearInteractions(deps.local);
      clearInteractions(deps.authRepo);
      // Re-stub after clearInteractions wipes the when() configuration.
      _stubDefaults(deps);
      when(() => deps.authRepo.logout()).thenAnswer((_) async {});

      // Snapshot ws.disconnect and sysEvent.reset call counts before
      // logout so we can assert deltas (not absolute counts).
      final ws =
          container.read(wsConnectionProvider.notifier) as _RecordingWsNotifier;
      final wsDisconnectsBefore = ws.disconnectCount;
      final sysEvent =
          container.read(systemEventProvider.notifier)
              as _RecordingSystemEventNotifier;
      final sysResetsBefore = sysEvent.resetCalls;

      await container.read(authProvider.notifier).logout();

      // ── Strict ordering invariants ────────────────────────────────────
      //
      // The auth-bridge invariant from auth_notifier.dart:131-137 says
      // teardown MUST complete before repository.logout(), because
      // teardown's WS disconnect triggers an FCM device-unregister POST
      // through the auth interceptor — the interceptor reads the token
      // from secure storage, and repository.logout() is what clears it.
      // Reverse the order and the device-unregister 401s silently,
      // leaving stale FCM subscriptions on the backend.
      //
      // We pin every step that was added to performTeardown by the
      // session-1 privacy fix so a future contributor can't silently
      // collapse a step into "obvious cleanup" and break the
      // multi-tenant device invariant.
      verifyInOrder([
        () => deps.fcm.unregister(),
        // Audit C3 (S-1): tech-location FG service teardown sits between
        // FCM unregister and the local-cache clears, ensuring the saved
        // auth token blob in FlutterForegroundTask shared-prefs is wiped
        // BEFORE repository.logout() invalidates the token server-side.
        () => deps.fgLifecycle.tearDown(),
        () => deps.local.clearLastSyncTimestamp(),
        () => deps.local.clearCachedEvents(),
        () => deps.local.clearPendingAcks(),
        () => deps.authRepo.logout(),
      ]);

      // ws.disconnect and sysEvent.reset are recorded by the fakes, not
      // by mocktail, so they don't appear in verifyInOrder. Assert
      // separately that they fired exactly once during this logout.
      expect(
        ws.disconnectCount,
        wsDisconnectsBefore + 1,
        reason: 'ws.disconnect must fire exactly once during logout',
      );
      expect(
        sysEvent.resetCalls,
        sysResetsBefore + 1,
        reason: 'systemEvent.reset must fire exactly once during logout',
      );

      // onUnauthorized must be cleared by performTeardown's tail step
      // — otherwise an in-flight 401 response could trigger a second
      // logout against fresh state.
      expect(
        eventSync.onUnauthorized,
        isNull,
        reason: 'eventSync.onUnauthorized must be nulled by teardown tail',
      );
    });

    test(
      'A10 — logout while AsyncLoading short-circuits without re-tearing-down',
      () async {
        final deps = _Deps();
        _stubDefaults(deps);
        const cachedUser = UserEntity(
          phone: '+923001234567',
          token: 'tok',
          isTechnician: true,
        );
        when(
          () => deps.authRepo.getCachedUser(),
        ).thenAnswer((_) async => cachedUser);

        // Block the authRepo.logout() so the first logout() call parks
        // mid-flight in AsyncLoading state, allowing the second call to
        // hit the state.isLoading guard.
        final logoutGate = Completer<void>();
        when(() => deps.authRepo.logout()).thenAnswer((_) => logoutGate.future);

        final container = _buildContainer(deps);
        addTearDown(container.dispose);

        await container.read(authProvider.future);
        await _drainMicrotasks();

        clearInteractions(deps.fcm);
        _stubDefaults(deps);
        when(() => deps.authRepo.logout()).thenAnswer((_) => logoutGate.future);

        final ws =
            container.read(wsConnectionProvider.notifier)
                as _RecordingWsNotifier;
        final wsDisconnectsBefore = ws.disconnectCount;

        // Fire-and-forget the first logout — it parks at the
        // authRepo.logout() await.
        final firstLogout = container.read(authProvider.notifier).logout();
        await _drainMicrotasks();

        // Second logout call — must short-circuit on state.isLoading guard.
        await container.read(authProvider.notifier).logout();

        // teardown should have run exactly once (from the first call).
        verify(() => deps.fcm.unregister()).called(1);
        expect(
          ws.disconnectCount,
          wsDisconnectsBefore + 1,
          reason:
              'ws.disconnect must NOT fire a second time while the first '
              'logout is still mid-flight (state.isLoading guard at '
              'auth_notifier.dart:129)',
        );

        // Release the gate so the first logout resolves cleanly.
        logoutGate.complete();
        await firstLogout;
      },
    );
  });
}

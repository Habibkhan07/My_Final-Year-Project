import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'package:frontend/features/auth/domain/failures/auth_failure.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/use_cases/request_otp_use_case.dart';
import 'package:frontend/features/auth/domain/use_cases/verify_otp_use_case.dart';
import 'package:frontend/features/auth/domain/use_cases/complete_signup_use_case.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/auth_state.dart';
import 'package:frontend/features/auth/presentation/providers/dependency_injection.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockRequestOtpUseCase extends Mock implements RequestOtpUseCase {}
class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}
class MockCompleteSignupUseCase extends Mock implements CompleteSignupUseCase {}
class FakeUserEntity extends Fake implements UserEntity {}

class _MockFcmHandler extends Mock implements FCMHandler {}
class _MockEventLocal extends Mock implements EventLocalDataSource {}

/// Records `connect`/`disconnect` calls so boot/teardown bridge tests can
/// verify the auth notifier reaches the WS layer with the right token.
/// Overrides only the methods Session 2 wires; everything else inherits.
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

/// Tracks the most recent assignment to `onUnauthorized` plus a small log of
/// transitions. The boot bridge sets it; teardown nulls it; the sentinel
/// reads it. All three must be observable.
class _RecordingEventSyncNotifier extends EventSyncNotifier {
  final List<void Function()?> onUnauthorizedHistory = [];

  @override
  Object? build() => null;

  @override
  set onUnauthorized(void Function()? value) {
    onUnauthorizedHistory.add(value);
    super.onUnauthorized = value;
  }
}

class _RecordingSystemEventNotifier extends SystemEventNotifier {
  int resetCount = 0;

  @override
  SystemEventState build() => const SystemEventState();

  @override
  void reset() {
    resetCount++;
  }
}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AsyncLoading<AuthState>());
    registerFallbackValue(FakeUserEntity());
  });

  late ProviderContainer container;
  late MockAuthRepository mockRepo;
  late MockRequestOtpUseCase mockRequestOtp;
  late MockVerifyOtpUseCase mockVerifyOtp;
  late MockCompleteSignupUseCase mockCompleteSignup;

  const tPhone = '+923001234567';
  const tOtp = '123456';
  const tToken = 'abc123token';

  /// Stubs every realtime provider the auth-bridge reaches into during
  /// boot/teardown so tests that don't assert against the bridge can still
  /// exercise `build()` / `verifyOtp()` / `logout()` without hitting real
  /// FCM, WS, or SharedPreferences. Boot-bridge tests use their own
  /// recording fakes via `seedBridgeContainer`.
  silentRealtimeOverrides() {
    final fcm = _MockFcmHandler();
    when(() => fcm.initialize()).thenAnswer((_) async {});
    when(() => fcm.unregister()).thenAnswer((_) async {});

    final local = _MockEventLocal();
    when(() => local.getLastSyncTimestamp()).thenReturn(null);
    when(() => local.clearLastSyncTimestamp()).thenAnswer((_) async {});
    when(() => local.clearCachedEvents()).thenAnswer((_) async {});
    when(() => local.clearPendingAcks()).thenAnswer((_) async {});

    return [
      realtimeBootHooksProvider.overrideWith((ref) => const []),
      realtime_di.fcmHandlerProvider.overrideWithValue(fcm),
      realtime_di.eventLocalDataSourceProvider.overrideWithValue(local),
      eventSyncProvider.overrideWith(_RecordingEventSyncNotifier.new),
      wsConnectionProvider.overrideWith(_RecordingWsNotifier.new),
      systemEventProvider.overrideWith(_RecordingSystemEventNotifier.new),
    ];
  }

  setUp(() {
    mockRepo = MockAuthRepository();
    mockRequestOtp = MockRequestOtpUseCase();
    mockVerifyOtp = MockVerifyOtpUseCase();
    mockCompleteSignup = MockCompleteSignupUseCase();

    // build() calls getCachedUser — return null by default (no prior session)
    when(() => mockRepo.getCachedUser()).thenAnswer((_) async => null);
    when(() => mockRepo.logout()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        requestOtpUseCaseProvider.overrideWithValue(mockRequestOtp),
        verifyOtpUseCaseProvider.overrideWithValue(mockVerifyOtp),
        completeSignupUseCaseProvider.overrideWithValue(mockCompleteSignup),
        ...silentRealtimeOverrides(),
      ],
    );
  });

  tearDown(() => container.dispose());

  // ---------------------------------------------------------------------------
  // build / initial state
  // ---------------------------------------------------------------------------

  group('build', () {
    test('initial state is AsyncData(AuthState()) when no cached session', () async {
      await container.read(authProvider.future);
      expect(container.read(authProvider), const AsyncData(AuthState()));
    });

    test('initial state contains cached user when session exists', () async {
      const cachedUser = UserEntity(phone: tPhone, token: tToken, nameRequired: false);
      final mockRepoWithUser = MockAuthRepository();
      when(() => mockRepoWithUser.getCachedUser()).thenAnswer((_) async => cachedUser);

      final c = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockRepoWithUser),
        ...silentRealtimeOverrides(),
      ]);
      addTearDown(c.dispose);

      await c.read(authProvider.future);
      expect(c.read(authProvider).value?.user?.phone, tPhone);
    });
  });

  // ---------------------------------------------------------------------------
  // requestOtp
  // ---------------------------------------------------------------------------

  group('requestOtp', () {
    test('emits AsyncLoading then AsyncData with successMessage on success', () async {
      await container.read(authProvider.future);
      when(() => mockRequestOtp.execute(tPhone)).thenAnswer((_) async => 'OTP Sent');

      final listener = Listener<AsyncValue<AuthState>>();
      container.listen(authProvider, listener.call, fireImmediately: false);

      final future = container.read(authProvider.notifier).requestOtp(tPhone);

      verify(() => listener.call(
        const AsyncData(AuthState()),
        any(that: isA<AsyncLoading<AuthState>>()),
      )).called(1);

      await future;

      verify(() => listener.call(
        any(that: isA<AsyncLoading<AuthState>>()),
        const AsyncData(AuthState(successMessage: 'OTP Sent')),
      )).called(1);

      expect(container.read(authProvider),
          const AsyncData(AuthState(successMessage: 'OTP Sent')));
    });

    test('emits AsyncError with InvalidInput on SMS delivery failure', () async {
      await container.read(authProvider.future);
      when(() => mockRequestOtp.execute(tPhone)).thenThrow(
        const InvalidInput('Failed to send OTP via SMS: test error', {}),
      );

      await container.read(authProvider.notifier).requestOtp(tPhone);

      final state = container.read(authProvider);
      expect(state, isA<AsyncError<AuthState>>());
      expect(state.error, isA<InvalidInput>());
      expect((state.error as InvalidInput).message, contains('Failed to send OTP'));
    });

    test('emits AsyncError with InvalidInput on phone validation failure', () async {
      await container.read(authProvider.future);
      final errors = {'phone': ['Enter a valid Pakistani mobile number.']};
      when(() => mockRequestOtp.execute(tPhone)).thenThrow(
        InvalidInput('Invalid input data.', errors),
      );

      await container.read(authProvider.notifier).requestOtp(tPhone);

      final state = container.read(authProvider);
      expect(state.error, isA<InvalidInput>());
      expect((state.error as InvalidInput).errors['phone']?.first,
          'Enter a valid Pakistani mobile number.');
    });
  });

  // ---------------------------------------------------------------------------
  // verifyOtp
  // ---------------------------------------------------------------------------

  group('verifyOtp', () {
    const tUser = UserEntity(
      phone: tPhone,
      token: tToken,
      isTechnician: false,
      nameRequired: true,
    );

    test('emits AsyncData with user on success', () async {
      await container.read(authProvider.future);
      when(() => mockVerifyOtp.execute(tPhone, tOtp)).thenAnswer((_) async => tUser);

      await container.read(authProvider.notifier).verifyOtp(tPhone, tOtp);

      final state = container.read(authProvider);
      expect(state.value?.user?.phone, tPhone);
      expect(state.value?.user?.token, tToken);
    });

    test('emits AsyncError with InvalidInput on wrong OTP — message and field errors both set', () async {
      await container.read(authProvider.future);
      final errors = {'otp': ['Invalid OTP.']};
      // Fixed: InvalidInput now takes (message, errors) — was single-arg before
      when(() => mockVerifyOtp.execute(tPhone, tOtp)).thenThrow(
        InvalidInput('Invalid OTP.', errors),
      );

      await container.read(authProvider.notifier).verifyOtp(tPhone, tOtp);

      final state = container.read(authProvider);
      expect(state, isA<AsyncError<AuthState>>());
      final failure = state.error as InvalidInput;
      expect(failure.message, 'Invalid OTP.');
      expect(failure.errors, errors);
    });

    test('emits AsyncError with InvalidInput when OTP has expired', () async {
      await container.read(authProvider.future);
      when(() => mockVerifyOtp.execute(tPhone, tOtp)).thenThrow(
        const InvalidInput(
          'OTP has expired. Please request a new one.',
          {'otp': ['OTP has expired. Please request a new one.']},
        ),
      );

      await container.read(authProvider.notifier).verifyOtp(tPhone, tOtp);

      final state = container.read(authProvider);
      expect((state.error as InvalidInput).message, contains('expired'));
    });
  });

  // ---------------------------------------------------------------------------
  // completeSignup
  // ---------------------------------------------------------------------------

  group('completeSignup', () {
    const tUserWithToken = UserEntity(
      phone: tPhone,
      token: tToken,
      nameRequired: true,
    );

    ProviderContainer makeContainerWithUser() {
      final mockRepoWithUser = MockAuthRepository();
      when(() => mockRepoWithUser.getCachedUser())
          .thenAnswer((_) async => tUserWithToken);
      when(() => mockRepoWithUser.persistUser(any())).thenAnswer((_) async {});

      return ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockRepoWithUser),
        completeSignupUseCaseProvider.overrideWithValue(mockCompleteSignup),
        ...silentRealtimeOverrides(),
      ]);
    }

    test('emits AsyncData with updated user and successMessage on success', () async {
      final c = makeContainerWithUser();
      addTearDown(c.dispose);
      await c.read(authProvider.future);

      when(() => mockCompleteSignup.execute('Ali', 'Raza', tToken))
          .thenAnswer((_) async => 'Profile updated successfully.');

      await c.read(authProvider.notifier).completeSignup('Ali', 'Raza');

      final state = c.read(authProvider);
      expect(state.value?.successMessage, 'Profile updated successfully.');
      expect(state.value?.user?.nameRequired, false);
    });

    test('emits AsyncError with Unauthorized when token is missing', () async {
      // Container with no cached user → token will be null
      await container.read(authProvider.future);

      await container.read(authProvider.notifier).completeSignup('Ali', 'Raza');

      expect(container.read(authProvider).error, isA<Unauthorized>());
    });
  });

  // ---------------------------------------------------------------------------
  // updateProfileNames
  // ---------------------------------------------------------------------------

  group('updateProfileNames', () {
    test('mutates user synchronously — never emits AsyncLoading', () async {
      const initialUser = UserEntity(
        phone: tPhone,
        token: tToken,
        nameRequired: true,
      );
      final mockRepoWithUser = MockAuthRepository();
      when(() => mockRepoWithUser.getCachedUser()).thenAnswer((_) async => initialUser);
      when(() => mockRepoWithUser.persistUser(any())).thenAnswer((_) async {});

      final c = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockRepoWithUser),
        ...silentRealtimeOverrides(),
      ]);
      addTearDown(c.dispose);
      await c.read(authProvider.future);

      final listener = Listener<AsyncValue<AuthState>>();
      c.listen(authProvider, listener.call, fireImmediately: false);

      c.read(authProvider.notifier).updateProfileNames('Ali', 'Raza');
      await Future.delayed(Duration.zero);

      final finalState = c.read(authProvider);
      expect(finalState, isA<AsyncData<AuthState>>());
      expect(finalState.value?.user?.firstName, 'Ali');
      expect(finalState.value?.user?.lastName, 'Raza');
      expect(finalState.value?.user?.nameRequired, false);

      // Must never transition through AsyncLoading
      verifyNever(() => listener.call(
        any(), any(that: isA<AsyncLoading<AuthState>>()),
      ));
    });
  });

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------

  group('logout', () {
    test('clears state to AsyncData(AuthState()) and calls repository.logout', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      await container.read(authProvider.future);

      await container.read(authProvider.notifier).logout();

      expect(container.read(authProvider), const AsyncData(AuthState()));
      verify(() => mockRepo.logout()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // Realtime bridge — boot/teardown wiring (Session 2 / flag #7 gap 4)
  //
  // These groups verify that AuthNotifier connects to AppLifecycleOrchestrator
  // at the three documented transition points (build / verifyOtp / logout) and
  // that the load-bearing invariants hold:
  //   * `bootAfterAuth(ref, token)` is fire-and-forget, but it MUST reach
  //     `wsConnection.connect(token)` for valid tokens — otherwise no events
  //     ever flow.
  //   * Empty/null tokens MUST short-circuit (symmetry with `_onResumed`).
  //   * `teardownOnLogout` MUST run BEFORE `repository.logout()` clears the
  //     auth token, because the FCM device-unregister POST that runs inside
  //     teardown reads the token from secure storage.
  //   * `logout()` MUST be guarded against double-tap (the bridge would
  //     otherwise fire twice in parallel).
  // ---------------------------------------------------------------------------

  group('realtime bridge', () {
    late MockAuthRepository bridgeRepo;
    late MockVerifyOtpUseCase bridgeVerifyOtp;
    late _MockFcmHandler bridgeFcm;
    late _MockEventLocal bridgeLocal;
    late ProviderContainer bridgeContainer;
    late _RecordingWsNotifier bridgeWs;
    late _RecordingEventSyncNotifier bridgeEventSync;
    late _RecordingSystemEventNotifier bridgeSystemEvent;

    /// Builds a container with every realtime provider overridden so the
    /// bridge can run without touching real FCM, WS, or storage. Returns
    /// after the typed notifier instances are pre-resolved so each test can
    /// observe their state.
    void seedBridgeContainer({UserEntity? cachedUser}) {
      bridgeRepo = MockAuthRepository();
      when(() => bridgeRepo.getCachedUser())
          .thenAnswer((_) async => cachedUser);
      when(() => bridgeRepo.logout()).thenAnswer((_) async {});

      bridgeVerifyOtp = MockVerifyOtpUseCase();

      bridgeFcm = _MockFcmHandler();
      when(() => bridgeFcm.initialize()).thenAnswer((_) async {});
      when(() => bridgeFcm.unregister()).thenAnswer((_) async {});

      bridgeLocal = _MockEventLocal();
      // SystemEventNotifier.build reads this if the real notifier is used;
      // the recording fake bypasses it, but stub anyway in case the chain
      // reaches the local data source via teardown's clear* calls.
      when(() => bridgeLocal.getLastSyncTimestamp()).thenReturn(null);
      when(() => bridgeLocal.clearLastSyncTimestamp())
          .thenAnswer((_) async {});
      when(() => bridgeLocal.clearCachedEvents()).thenAnswer((_) async {});
      when(() => bridgeLocal.clearPendingAcks()).thenAnswer((_) async {});

      bridgeContainer = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(bridgeRepo),
        verifyOtpUseCaseProvider.overrideWithValue(bridgeVerifyOtp),
        // Empty registry keeps the bridge tests narrow — feature wake-ups
        // are exercised in the orchestrator's own test file.
        realtimeBootHooksProvider.overrideWith((ref) => const []),
        realtime_di.fcmHandlerProvider.overrideWithValue(bridgeFcm),
        realtime_di.eventLocalDataSourceProvider.overrideWithValue(bridgeLocal),
        eventSyncProvider.overrideWith(_RecordingEventSyncNotifier.new),
        wsConnectionProvider.overrideWith(_RecordingWsNotifier.new),
        systemEventProvider.overrideWith(_RecordingSystemEventNotifier.new),
      ]);

      bridgeWs = bridgeContainer.read(wsConnectionProvider.notifier)
          as _RecordingWsNotifier;
      bridgeEventSync = bridgeContainer.read(eventSyncProvider.notifier)
          as _RecordingEventSyncNotifier;
      bridgeSystemEvent = bridgeContainer.read(systemEventProvider.notifier)
          as _RecordingSystemEventNotifier;
    }

    tearDown(() => bridgeContainer.dispose());

    // ─── build() ─────────────────────────────────────────────────────────

    group('build (boot bridge)', () {
      test('AB1 — cached user with a valid token fires bootAfterAuth and '
          'reaches wsConnection.connect with that token', () async {
        const cached = UserEntity(
          phone: '+923001234567',
          token: tToken,
          nameRequired: false,
        );
        seedBridgeContainer(cachedUser: cached);

        await bridgeContainer.read(authProvider.future);
        // Drain microtasks so the unawaited boot future runs to completion.
        await pumpEventQueue();

        expect(bridgeWs.connectCalls, [tToken],
            reason: 'boot must reach WS.connect with the cached token');
        verify(() => bridgeFcm.initialize()).called(1);
        // onUnauthorized is set exactly once by boot; no teardown happened
        // here, so it is still non-null at the end.
        expect(bridgeEventSync.onUnauthorizedHistory.length, 1);
        expect(bridgeEventSync.onUnauthorizedHistory.last, isNotNull);
      });

      test('AB2 — cached user with null token does NOT fire boot', () async {
        const cached = UserEntity(
          phone: '+923001234567',
          token: null,
          nameRequired: false,
        );
        seedBridgeContainer(cachedUser: cached);

        await bridgeContainer.read(authProvider.future);
        await pumpEventQueue();

        expect(bridgeWs.connectCalls, isEmpty);
        verifyNever(() => bridgeFcm.initialize());
        expect(bridgeEventSync.onUnauthorizedHistory, isEmpty);
      });

      test('AB3 — cached user with empty-string token does NOT fire boot '
          '(symmetry with _onResumed)', () async {
        const cached = UserEntity(
          phone: '+923001234567',
          token: '',
          nameRequired: false,
        );
        seedBridgeContainer(cachedUser: cached);

        await bridgeContainer.read(authProvider.future);
        await pumpEventQueue();

        expect(bridgeWs.connectCalls, isEmpty);
        verifyNever(() => bridgeFcm.initialize());
      });

      test('AB4 — no cached user does NOT fire boot', () async {
        seedBridgeContainer(cachedUser: null);

        await bridgeContainer.read(authProvider.future);
        await pumpEventQueue();

        expect(bridgeWs.connectCalls, isEmpty);
        verifyNever(() => bridgeFcm.initialize());
      });
    });

    // ─── verifyOtp() ─────────────────────────────────────────────────────

    group('verifyOtp (boot bridge)', () {
      test('AB5 — successful verify with a token fires boot', () async {
        seedBridgeContainer();
        const verified = UserEntity(
          phone: tPhone,
          token: tToken,
          nameRequired: true,
        );
        when(() => bridgeVerifyOtp.execute(tPhone, tOtp))
            .thenAnswer((_) async => verified);

        await bridgeContainer.read(authProvider.future);
        await bridgeContainer
            .read(authProvider.notifier)
            .verifyOtp(tPhone, tOtp);
        await pumpEventQueue();

        expect(bridgeWs.connectCalls, [tToken]);
        verify(() => bridgeFcm.initialize()).called(1);
      });

      test('AB6 — successful verify with null token does NOT fire boot',
          () async {
        seedBridgeContainer();
        const verified = UserEntity(
          phone: tPhone,
          token: null,
          nameRequired: true,
        );
        when(() => bridgeVerifyOtp.execute(tPhone, tOtp))
            .thenAnswer((_) async => verified);

        await bridgeContainer.read(authProvider.future);
        await bridgeContainer
            .read(authProvider.notifier)
            .verifyOtp(tPhone, tOtp);
        await pumpEventQueue();

        expect(bridgeWs.connectCalls, isEmpty);
        // Auth state still lands successfully — only the bridge short-circuits.
        expect(bridgeContainer.read(authProvider).value?.user?.phone, tPhone);
      });
    });

    // ─── logout() ────────────────────────────────────────────────────────

    group('logout (teardown bridge)', () {
      test('AB7 — teardown runs BEFORE repository.logout (ordering invariant)',
          () async {
        const cached = UserEntity(
          phone: tPhone,
          token: tToken,
          nameRequired: false,
        );
        seedBridgeContainer(cachedUser: cached);
        await bridgeContainer.read(authProvider.future);
        await pumpEventQueue();

        // Pre-condition: boot fired, so onUnauthorized is non-null.
        expect(bridgeEventSync.onUnauthorizedHistory.last, isNotNull);
        clearInteractions(bridgeFcm);
        clearInteractions(bridgeLocal);
        clearInteractions(bridgeRepo);

        await bridgeContainer.read(authProvider.notifier).logout();

        // Strict ordering — performTeardown's documented sequence, then
        // repository.logout LAST. mocktail's verifyInOrder catches a swap
        // (which would silently break server-side device-unregister, the
        // whole reason ordering matters).
        verifyInOrder([
          () => bridgeFcm.unregister(),
          () => bridgeLocal.clearLastSyncTimestamp(),
          () => bridgeLocal.clearCachedEvents(),
          () => bridgeLocal.clearPendingAcks(),
          () => bridgeRepo.logout(),
        ]);
        // WS disconnect and systemEvent reset are recorded on the fakes,
        // not on mocktail mocks — assert via the recorders.
        expect(bridgeWs.disconnectCount, 1);
        expect(bridgeSystemEvent.resetCount, 1);
        // onUnauthorized was set (by boot) then nulled (by teardown).
        expect(bridgeEventSync.onUnauthorizedHistory.last, isNull);
        // Final state.
        expect(bridgeContainer.read(authProvider),
            const AsyncData(AuthState()));
      });

      test('AB8 — second concurrent logout call no-ops via isLoading guard',
          () async {
        const cached = UserEntity(
          phone: tPhone,
          token: tToken,
          nameRequired: false,
        );
        seedBridgeContainer(cachedUser: cached);
        await bridgeContainer.read(authProvider.future);
        await pumpEventQueue();
        clearInteractions(bridgeFcm);
        clearInteractions(bridgeRepo);
        bridgeWs.disconnectCount = 0;
        bridgeSystemEvent.resetCount = 0;

        // Block teardown so the first logout is in-flight when the second
        // call fires; without the isLoading guard, the second would race the
        // first into a parallel teardown + repository.logout.
        final blocker = Completer<void>();
        when(() => bridgeFcm.unregister())
            .thenAnswer((_) => blocker.future);

        final firstFuture =
            bridgeContainer.read(authProvider.notifier).logout();
        // Yield so first call enters AsyncLoading and awaits unregister.
        await pumpEventQueue();

        // Second call should early-return because state.isLoading is true.
        final secondFuture =
            bridgeContainer.read(authProvider.notifier).logout();
        await secondFuture;

        // Unblock and finish the first call.
        blocker.complete();
        await firstFuture;

        // Each teardown step ran exactly once — guard held.
        verify(() => bridgeFcm.unregister()).called(1);
        verify(() => bridgeRepo.logout()).called(1);
        expect(bridgeWs.disconnectCount, 1);
        expect(bridgeSystemEvent.resetCount, 1);
      });
    });
  });
}

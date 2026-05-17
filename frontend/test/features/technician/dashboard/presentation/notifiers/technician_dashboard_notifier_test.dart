import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';
import 'package:frontend/features/technician/dashboard/domain/failures/technician_dashboard_failure.dart';
import 'package:frontend/features/technician/dashboard/domain/repositories/technician_dashboard_repository.dart';
import 'package:frontend/features/technician/dashboard/presentation/notifiers/technician_dashboard_notifier.dart';
import 'package:frontend/features/technician/dashboard/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/dashboard/presentation/state/technician_dashboard_state.dart';

class MockTechnicianDashboardRepository extends Mock
    implements TechnicianDashboardRepository {}

TechnicianDashboardEntity _entity({
  double walletBalance = 1500.00,
  bool isOnline = true,
}) {
  return TechnicianDashboardEntity(
    walletBalance: walletBalance,
    isOnline: isOnline,
    profilePicture: 'http://example.com/p.png',
    upNextJob: UpNextJobEntity(
      jobId: 99482,
      serviceTitle: 'AC Deep Wash',
      scheduledTime: DateTime.utc(2026, 4, 26, 14),
      customerName: 'Ali R.',
      addressText: '14 Street, Gulberg III',
      lat: 31.5204,
      lng: 74.3587,
    ),
    laterTodayJobs: [
      LaterTodayJobEntity(
        jobId: 99483,
        serviceTitle: 'Ceiling Fan Repair',
        scheduledTime: DateTime.utc(2026, 4, 26, 16),
        addressText: 'DHA Phase 5',
      ),
    ],
  );
}

void main() {
  late MockTechnicianDashboardRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockTechnicianDashboardRepository();
    container = ProviderContainer(
      overrides: [
        technicianDashboardRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('build()', () {
    test('loads the dashboard via the repository', () async {
      final entity = _entity();
      when(() => repo.getDashboard()).thenAnswer((_) async => entity);

      final state = await container.read(technicianDashboardProvider.future);

      expect(state.dashboard, entity);
      expect(state.toggleStatus, const AsyncData<void>(null));
      verify(() => repo.getDashboard()).called(1);
    });

    test('surfaces repository failures as AsyncError', () async {
      when(() => repo.getDashboard()).thenAnswer((_) async {
        throw const DashboardPermissionFailure();
      });

      // Listen until the provider settles into an error state. Reading
      // `.future` directly is unreliable here because Riverpod auto-disposes
      // the provider once the throwaway subscription closes, masking the
      // real domain error with a "disposed during loading" StateError.
      final completer = Completer<AsyncValue<TechnicianDashboardState>>();
      final sub = container.listen<AsyncValue<TechnicianDashboardState>>(
        technicianDashboardProvider,
        (_, next) {
          if (next.hasError && !completer.isCompleted) {
            completer.complete(next);
          }
        },
      );
      addTearDown(sub.close);

      final result = await completer.future.timeout(const Duration(seconds: 2));
      expect(result.hasError, true);
      expect(result.error, isA<DashboardPermissionFailure>());
    });
  });

  group('refresh()', () {
    test('re-fetches and replaces the cached dashboard', () async {
      final first = _entity(walletBalance: 1000);
      final second = _entity(walletBalance: 2500);
      when(() => repo.getDashboard()).thenAnswer((_) async => first);

      await container.read(technicianDashboardProvider.future);

      when(() => repo.getDashboard()).thenAnswer((_) async => second);

      await container.read(technicianDashboardProvider.notifier).refresh();

      final state = container.read(technicianDashboardProvider).requireValue;
      expect(state.dashboard.walletBalance, 2500);
      verify(() => repo.getDashboard()).called(2);
    });

    test('surfaces refresh failure as AsyncError without crashing', () async {
      final first = _entity();
      when(() => repo.getDashboard()).thenAnswer((_) async => first);
      await container.read(technicianDashboardProvider.future);

      when(
        () => repo.getDashboard(),
      ).thenAnswer((_) async => throw const DashboardServerFailure('boom'));

      await container.read(technicianDashboardProvider.notifier).refresh();

      final state = container.read(technicianDashboardProvider);
      expect(state, isA<AsyncError<TechnicianDashboardState>>());
    });
  });

  group('setOnline()', () {
    test(
      'flips isOnline, persists via repository, settles toggleStatus to data',
      () async {
        when(
          () => repo.getDashboard(),
        ).thenAnswer((_) async => _entity(isOnline: false));
        when(() => repo.setOnline(true)).thenAnswer(
          (_) async => (isOnline: true, walletBalance: 1500.0),
        );
        await container.read(technicianDashboardProvider.future);

        await container
            .read(technicianDashboardProvider.notifier)
            .setOnline(true);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.isOnline, true);
        expect(state.toggleStatus, const AsyncData<void>(null));
        verify(() => repo.setOnline(true)).called(1);
      },
    );

    test(
      'reconciles wallet balance from server response (top-up race)',
      () async {
        // Tech tapped Online with locally-cached balance of 200; a top-up
        // landed mid-request, so the server returns the fresh 2200 number.
        // The notifier must adopt the server's number — not the stale local
        // one — so the wallet pill snaps to the truth in the same round trip.
        when(() => repo.getDashboard()).thenAnswer(
          (_) async => _entity(isOnline: false, walletBalance: 200),
        );
        when(() => repo.setOnline(true)).thenAnswer(
          (_) async => (isOnline: true, walletBalance: 2200.0),
        );
        await container.read(technicianDashboardProvider.future);

        await container
            .read(technicianDashboardProvider.notifier)
            .setOnline(true);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.walletBalance, 2200.0);
        expect(state.dashboard.isOnline, true);
      },
    );

    test(
      'on DashboardWalletLockedFailure reverts isOnline and surfaces error',
      () async {
        // Race: local cache says balance is positive (200), so the local
        // lockout gate passes and the HTTP call goes out. Server has the
        // truth — a commission just landed, balance is now -100. Server
        // refuses with wallet_lockout. Notifier must:
        //   1. Revert the optimistic isOnline=true back to false.
        //   2. Surface the lockout failure on toggleStatus so the screen
        //      listener can show the short snackbar.
        when(() => repo.getDashboard()).thenAnswer(
          (_) async => _entity(isOnline: false, walletBalance: 200),
        );
        when(() => repo.setOnline(true)).thenThrow(
          const DashboardWalletLockedFailure(
            balancePkr: -100,
            owedPkr: 100,
          ),
        );
        await container.read(technicianDashboardProvider.future);

        await container
            .read(technicianDashboardProvider.notifier)
            .setOnline(true);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.isOnline, false,
            reason: 'optimistic flip must revert on lockout');
        expect(state.toggleStatus, isA<AsyncError<void>>());
        final err = (state.toggleStatus as AsyncError).error;
        expect(err, isA<DashboardWalletLockedFailure>());
      },
    );

    test(
      'on generic failure reverts isOnline and surfaces error',
      () async {
        when(() => repo.getDashboard()).thenAnswer(
          (_) async => _entity(isOnline: false, walletBalance: 200),
        );
        when(() => repo.setOnline(true))
            .thenThrow(const DashboardNetworkFailure());
        await container.read(technicianDashboardProvider.future);

        await container
            .read(technicianDashboardProvider.notifier)
            .setOnline(true);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.isOnline, false);
        expect(state.toggleStatus, isA<AsyncError<void>>());
      },
    );

    test(
      'on network/timeout failure reverts to previousIsOnline AND surfaces '
      'DashboardNetworkFailure (so the timeout fix has no stuck-loading)',
      () async {
        // Tech is currently online; taps offline; backend timeout.
        // Must revert to ONLINE (previous state), not stay in the
        // optimistic OFFLINE flip. toggleStatus surfaces the failure
        // for the snackbar.
        when(() => repo.getDashboard()).thenAnswer(
          (_) async => _entity(isOnline: true, walletBalance: 500),
        );
        when(() => repo.setOnline(false))
            .thenThrow(const DashboardNetworkFailure());
        await container.read(technicianDashboardProvider.future);

        await container
            .read(technicianDashboardProvider.notifier)
            .setOnline(false);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.isOnline, true,
            reason: 'must revert to previous (online) state on timeout');
        expect(state.toggleStatus, isA<AsyncError<void>>());
        final err = (state.toggleStatus as AsyncError).error;
        expect(err, isA<DashboardNetworkFailure>());
      },
    );

    test('is a no-op when desired matches current state', () async {
      when(
        () => repo.getDashboard(),
      ).thenAnswer((_) async => _entity(isOnline: true));
      await container.read(technicianDashboardProvider.future);

      final before = container.read(technicianDashboardProvider).requireValue;

      await container
          .read(technicianDashboardProvider.notifier)
          .setOnline(true);

      final after = container.read(technicianDashboardProvider).requireValue;
      expect(identical(after, before), true);
      // CRITICAL: no HTTP call wasted on a no-op.
      verifyNever(() => repo.setOnline(any()));
    });

    test('is a no-op when state has not loaded yet', () async {
      // Stub getDashboard with a never-completing future so build() stays
      // in AsyncLoading for the duration of this test.
      when(
        () => repo.getDashboard(),
      ).thenAnswer((_) => Completer<TechnicianDashboardEntity>().future);

      await container
          .read(technicianDashboardProvider.notifier)
          .setOnline(true);

      final state = container.read(technicianDashboardProvider);
      expect(state, isA<AsyncLoading<TechnicianDashboardState>>());
      verifyNever(() => repo.setOnline(any()));
    });
  });

  group('onWalletBalanceEvent()', () {
    test(
      'patches only the wallet balance, leaves other fields intact',
      () async {
        final entity = _entity(walletBalance: 1500);
        when(() => repo.getDashboard()).thenAnswer((_) async => entity);
        await container.read(technicianDashboardProvider.future);

        container
            .read(technicianDashboardProvider.notifier)
            .onWalletBalanceEvent(2750);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.walletBalance, 2750);
        expect(state.dashboard.isOnline, entity.isOnline);
        expect(state.dashboard.upNextJob, entity.upNextJob);
        expect(state.dashboard.laterTodayJobs, entity.laterTodayJobs);
      },
    );

    test('is a no-op when state has not loaded yet', () async {
      when(
        () => repo.getDashboard(),
      ).thenAnswer((_) => Completer<TechnicianDashboardEntity>().future);

      container
          .read(technicianDashboardProvider.notifier)
          .onWalletBalanceEvent(9999);

      final state = container.read(technicianDashboardProvider);
      expect(state, isA<AsyncLoading<TechnicianDashboardState>>());
    });

    // Auto-offline on negative crossover (mirrors B6 backend).
    test(
      'crossing into negative balance ALSO flips isOnline to false in the same patch',
      () async {
        when(
          () => repo.getDashboard(),
        ).thenAnswer((_) async => _entity(walletBalance: 200, isOnline: true));
        await container.read(technicianDashboardProvider.future);

        container
            .read(technicianDashboardProvider.notifier)
            .onWalletBalanceEvent(-50.0);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.walletBalance, -50.0);
        expect(
          state.dashboard.isOnline,
          false,
          reason:
              'Negative balance must auto-flip offline — matches backend B6',
        );
      },
    );

    test(
      'staying non-negative does NOT touch isOnline (no false-positive offline)',
      () async {
        when(() => repo.getDashboard()).thenAnswer(
          (_) async => _entity(walletBalance: 1000, isOnline: true),
        );
        await container.read(technicianDashboardProvider.future);

        container
            .read(technicianDashboardProvider.notifier)
            .onWalletBalanceEvent(500.0);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.walletBalance, 500.0);
        expect(state.dashboard.isOnline, true); // unchanged
      },
    );

    test(
      'topup clearing lockout does NOT auto-flip back to online (asymmetric recovery)',
      () async {
        // Tech was forced offline at -200; the topup brings them to +50 but
        // they stay offline — coming back online is intentionally manual.
        when(() => repo.getDashboard()).thenAnswer(
          (_) async => _entity(walletBalance: -200, isOnline: false),
        );
        await container.read(technicianDashboardProvider.future);

        container
            .read(technicianDashboardProvider.notifier)
            .onWalletBalanceEvent(50.0);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.walletBalance, 50.0);
        expect(state.dashboard.isOnline, false); // stays offline
      },
    );

    test(
      'already-offline tech going further negative stays offline (idempotent)',
      () async {
        when(() => repo.getDashboard()).thenAnswer(
          (_) async => _entity(walletBalance: -100, isOnline: false),
        );
        await container.read(technicianDashboardProvider.future);

        container
            .read(technicianDashboardProvider.notifier)
            .onWalletBalanceEvent(-300.0);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.walletBalance, -300.0);
        expect(state.dashboard.isOnline, false);
      },
    );
  });

  group('setOnline() — lockout gate', () {
    test(
      'locked tech cannot flip themselves ONLINE — no HTTP call made',
      () async {
        when(() => repo.getDashboard()).thenAnswer(
          (_) async => _entity(walletBalance: -100, isOnline: false),
        );
        await container.read(technicianDashboardProvider.future);

        final before =
            container.read(technicianDashboardProvider).requireValue;

        await container
            .read(technicianDashboardProvider.notifier)
            .setOnline(true);

        final after =
            container.read(technicianDashboardProvider).requireValue;
        // State unchanged — local gate refused, the visual pill is
        // already disabled. Server is still the authority but the local
        // gate avoids an HTTP call when the answer is structurally known.
        expect(after.dashboard.isOnline, false);
        expect(identical(after, before), true);
        verifyNever(() => repo.setOnline(any()));
      },
    );

    test('locked tech CAN still flip themselves OFFLINE', () async {
      // Edge: tech was online (e.g. balance just dipped under and the
      // forced-offline patch hasn't arrived yet) — they should still be
      // able to manually opt out of work.
      when(() => repo.getDashboard()).thenAnswer(
        (_) async => _entity(walletBalance: -100, isOnline: true),
      );
      when(() => repo.setOnline(false)).thenAnswer(
        (_) async => (isOnline: false, walletBalance: -100.0),
      );
      await container.read(technicianDashboardProvider.future);

      await container
          .read(technicianDashboardProvider.notifier)
          .setOnline(false);

      final state = container.read(technicianDashboardProvider).requireValue;
      expect(state.dashboard.isOnline, false);
      verify(() => repo.setOnline(false)).called(1);
    });
  });

  group('onForcedOfflineEvent()', () {
    test('flips isOnline to false when currently online', () async {
      when(
        () => repo.getDashboard(),
      ).thenAnswer((_) async => _entity(isOnline: true));
      await container.read(technicianDashboardProvider.future);

      container
          .read(technicianDashboardProvider.notifier)
          .onForcedOfflineEvent();

      final state = container.read(technicianDashboardProvider).requireValue;
      expect(state.dashboard.isOnline, false);
    });

    test('is idempotent when already offline', () async {
      when(
        () => repo.getDashboard(),
      ).thenAnswer((_) async => _entity(isOnline: false));
      await container.read(technicianDashboardProvider.future);

      final before = container.read(technicianDashboardProvider).requireValue;

      container
          .read(technicianDashboardProvider.notifier)
          .onForcedOfflineEvent();

      final after = container.read(technicianDashboardProvider).requireValue;
      expect(identical(after, before), true);
    });

    test('is a no-op when state has not loaded yet', () async {
      when(
        () => repo.getDashboard(),
      ).thenAnswer((_) => Completer<TechnicianDashboardEntity>().future);

      container
          .read(technicianDashboardProvider.notifier)
          .onForcedOfflineEvent();

      final state = container.read(technicianDashboardProvider);
      expect(state, isA<AsyncLoading<TechnicianDashboardState>>());
    });
  });
}

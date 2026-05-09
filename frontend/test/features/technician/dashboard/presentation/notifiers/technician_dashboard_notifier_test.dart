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
    metrics: const DashboardMetricsEntity(
      jobsCompletedToday: 2,
      cashCollectedToday: 3500.00,
    ),
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
      'optimistically flips isOnline and settles toggleStatus to data',
      () async {
        when(
          () => repo.getDashboard(),
        ).thenAnswer((_) async => _entity(isOnline: false));
        await container.read(technicianDashboardProvider.future);

        await container
            .read(technicianDashboardProvider.notifier)
            .setOnline(true);

        final state = container.read(technicianDashboardProvider).requireValue;
        expect(state.dashboard.isOnline, true);
        expect(state.toggleStatus, const AsyncData<void>(null));
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
        expect(state.dashboard.metrics, entity.metrics);
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

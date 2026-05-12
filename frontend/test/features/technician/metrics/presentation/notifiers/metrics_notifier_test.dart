import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/metrics/domain/entities/technician_metrics_entity.dart';
import 'package:frontend/features/technician/metrics/domain/repositories/metrics_repository.dart';
import 'package:frontend/features/technician/metrics/presentation/notifiers/metrics_notifier.dart';
import 'package:frontend/features/technician/metrics/presentation/providers/dependency_injection.dart';

class _MockRepo extends Mock implements MetricsRepository {}

TechnicianMetricsEntity _entity({
  int jobsToday = 2,
  double cashToday = 3500.0,
  double commissionToday = 700.0,
  int jobsWeek = 8,
  double cashWeek = 15000.0,
}) =>
    TechnicianMetricsEntity(
      jobsCompletedToday: jobsToday,
      cashCollectedToday: cashToday,
      commissionDeductedToday: commissionToday,
      jobsCompletedThisWeek: jobsWeek,
      cashCollectedThisWeek: cashWeek,
    );

void main() {
  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [metricsRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  group('build()', () {
    test('loads metrics via the repository', () async {
      final entity = _entity();
      when(() => repo.getMetrics()).thenAnswer((_) async => entity);

      final result = await container.read(metricsProvider.future);

      expect(result.jobsCompletedToday, 2);
      expect(result.commissionDeductedToday, 700.0);
      verify(() => repo.getMetrics()).called(1);
    });
  });

  group('refresh()', () {
    test('re-fetches and updates state', () async {
      when(() => repo.getMetrics()).thenAnswer((_) async => _entity(jobsToday: 1));
      await container.read(metricsProvider.future);

      when(() => repo.getMetrics()).thenAnswer((_) async => _entity(jobsToday: 5));
      await container.read(metricsProvider.notifier).refresh();

      expect(container.read(metricsProvider).requireValue.jobsCompletedToday, 5);
      verify(() => repo.getMetrics()).called(2);
    });
  });
}

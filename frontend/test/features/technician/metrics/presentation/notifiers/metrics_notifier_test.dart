import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/metrics/domain/entities/technician_metrics_entity.dart';
import 'package:frontend/features/technician/metrics/domain/repositories/metrics_repository.dart';
import 'package:frontend/features/technician/metrics/presentation/notifiers/metrics_notifier.dart';
import 'package:frontend/features/technician/metrics/presentation/providers/dependency_injection.dart';

class _MockRepo extends Mock implements MetricsRepository {}

TechnicianMetricsEntity _entity({
  MetricsPeriod period = MetricsPeriod.week,
  int totalJobs = 8,
  double totalCash = 15000.0,
}) =>
    TechnicianMetricsEntity(
      period: period,
      totalJobs: totalJobs,
      totalCash: totalCash,
      buckets: const [
        MetricsBucket(label: 'Mon', jobs: 2, cash: 4500.0),
        MetricsBucket(label: 'Tue', jobs: 1, cash: 2000.0),
      ],
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

  group('build(period)', () {
    test('loads metrics via the repository for the requested period', () async {
      when(() => repo.getMetrics(MetricsPeriod.week))
          .thenAnswer((_) async => _entity());

      final result =
          await container.read(metricsProvider(MetricsPeriod.week).future);

      expect(result.period, MetricsPeriod.week);
      expect(result.totalJobs, 8);
      verify(() => repo.getMetrics(MetricsPeriod.week)).called(1);
    });

    test('each period family entry is cached independently', () async {
      when(() => repo.getMetrics(MetricsPeriod.week)).thenAnswer(
        (_) async => _entity(period: MetricsPeriod.week, totalJobs: 8),
      );
      when(() => repo.getMetrics(MetricsPeriod.month)).thenAnswer(
        (_) async => _entity(period: MetricsPeriod.month, totalJobs: 42),
      );

      final weekResult =
          await container.read(metricsProvider(MetricsPeriod.week).future);
      final monthResult =
          await container.read(metricsProvider(MetricsPeriod.month).future);

      expect(weekResult.totalJobs, 8);
      expect(monthResult.totalJobs, 42);
      verify(() => repo.getMetrics(MetricsPeriod.week)).called(1);
      verify(() => repo.getMetrics(MetricsPeriod.month)).called(1);
    });
  });

  group('refresh()', () {
    test('re-fetches and updates state for the selected period', () async {
      when(() => repo.getMetrics(MetricsPeriod.week))
          .thenAnswer((_) async => _entity(totalJobs: 1));
      await container.read(metricsProvider(MetricsPeriod.week).future);

      when(() => repo.getMetrics(MetricsPeriod.week))
          .thenAnswer((_) async => _entity(totalJobs: 5));
      await container
          .read(metricsProvider(MetricsPeriod.week).notifier)
          .refresh();

      expect(
        container.read(metricsProvider(MetricsPeriod.week)).requireValue.totalJobs,
        5,
      );
      verify(() => repo.getMetrics(MetricsPeriod.week)).called(2);
    });
  });
}

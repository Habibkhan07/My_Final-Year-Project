import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/technician_metrics_entity.dart';
import '../providers/dependency_injection.dart';

part 'metrics_notifier.g.dart';

/// State holder for the technician Metrics screen.
///
/// **Family-keyed by [MetricsPeriod]** so each tab (Day/Week/Month/Year)
/// caches its own response independently. Tapping the segmented toggle is
/// a provider-key change, not a refetch — already-loaded periods snap back
/// instantly; new periods fetch on first read.
///
/// **keepAlive: false** — when the user backs out of the Metrics screen the
/// notifier disposes; re-entry triggers a fresh fetch so the numbers reflect
/// any jobs completed while away.
@riverpod
class MetricsNotifier extends _$MetricsNotifier {
  @override
  Future<TechnicianMetricsEntity> build(MetricsPeriod period) async {
    return await ref.read(metricsRepositoryProvider).getMetrics(period);
  }

  /// Pull-to-refresh on the currently-selected period.
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(metricsRepositoryProvider).getMetrics(period),
    );
  }
}

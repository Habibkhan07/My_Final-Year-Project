import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/technician_metrics_entity.dart';
import '../providers/dependency_injection.dart';

part 'metrics_notifier.g.dart';

/// State holder for the technician metrics row on the dashboard.
///
/// **keepAlive: false** — metrics are per-session fresh data. When the
/// dashboard is disposed (e.g. during a booking flow), the notifier
/// disposes and re-fetches on return, ensuring the counts reflect any
/// jobs completed while away.
///
/// Pull-to-refresh is delegated to [refresh]. The dashboard screen
/// calls this when the user drags the RefreshIndicator, same as the
/// dashboard notifier itself.
@riverpod
class MetricsNotifier extends _$MetricsNotifier {
  @override
  Future<TechnicianMetricsEntity> build() async {
    return await ref.read(metricsRepositoryProvider).getMetrics();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(metricsRepositoryProvider).getMetrics(),
    );
  }
}

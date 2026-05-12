import '../entities/technician_metrics_entity.dart';
import '../failures/metrics_failure.dart';

/// Throws [MetricsFailure] subtypes on error — never raw exceptions.
abstract interface class MetricsRepository {
  Future<TechnicianMetricsEntity> getMetrics();
}

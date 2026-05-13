import '../../domain/entities/technician_metrics_entity.dart';

/// DTO for GET /api/technicians/metrics/?period=…
///
/// Defensive `?? 0` defaults on numeric fields tolerate a stale backend
/// that omits a field mid-deploy. Unknown period strings fall back to
/// [MetricsPeriod.week] so the client never crashes on a bad wire value.
class TechnicianMetricsModel {
  final String period;
  final int totalJobs;
  final double totalCash;
  final List<MetricsBucketModel> buckets;

  const TechnicianMetricsModel({
    required this.period,
    required this.totalJobs,
    required this.totalCash,
    required this.buckets,
  });

  factory TechnicianMetricsModel.fromJson(Map<String, dynamic> json) =>
      TechnicianMetricsModel(
        period: (json['period'] as String?) ?? 'week',
        totalJobs: (json['total_jobs'] as num? ?? 0).toInt(),
        totalCash: (json['total_cash'] as num? ?? 0).toDouble(),
        buckets: ((json['buckets'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(MetricsBucketModel.fromJson)
            .toList(),
      );

  TechnicianMetricsEntity toEntity() {
    final periodEnum = MetricsPeriod.values.firstWhere(
      (p) => p.wireValue == period,
      orElse: () => MetricsPeriod.week,
    );
    return TechnicianMetricsEntity(
      period: periodEnum,
      totalJobs: totalJobs,
      totalCash: totalCash,
      buckets: buckets.map((m) => m.toEntity()).toList(growable: false),
    );
  }
}

class MetricsBucketModel {
  final String label;
  final int jobs;
  final double cash;

  const MetricsBucketModel({
    required this.label,
    required this.jobs,
    required this.cash,
  });

  factory MetricsBucketModel.fromJson(Map<String, dynamic> json) =>
      MetricsBucketModel(
        label: (json['label'] as String?) ?? '',
        jobs: (json['jobs'] as num? ?? 0).toInt(),
        cash: (json['cash'] as num? ?? 0).toDouble(),
      );

  MetricsBucket toEntity() => MetricsBucket(label: label, jobs: jobs, cash: cash);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_metrics_entity.freezed.dart';

/// Wire enum for the `?period=` query parameter. Single source of truth for
/// the values the backend accepts ('day' | 'week' | 'month' | 'year').
enum MetricsPeriod {
  day('day', 'Day'),
  week('week', 'Week'),
  month('month', 'Month'),
  year('year', 'Year');

  const MetricsPeriod(this.wireValue, this.label);

  /// String sent to the backend in the `period` query param.
  final String wireValue;

  /// Human label shown in the segmented toggle.
  final String label;

  static MetricsPeriod fromWire(String raw) =>
      MetricsPeriod.values.firstWhere((p) => p.wireValue == raw);
}

/// One time-bucket on the metrics chart.
///
/// [label] is the short axis label rendered under the bar
/// ('Mon', 'Today', '15', 'Jan' — depending on period).
@freezed
abstract class MetricsBucket with _$MetricsBucket {
  const factory MetricsBucket({
    required String label,
    required int jobs,
    required double cash,
  }) = _MetricsBucket;
}

/// Contract: fed by GET /api/technicians/metrics/?period=…
///
/// Activity + cash-earnings only — platform-settlement transactions
/// (commission, top-ups, withdrawals) live on the Wallet screen.
@freezed
abstract class TechnicianMetricsEntity with _$TechnicianMetricsEntity {
  const factory TechnicianMetricsEntity({
    required MetricsPeriod period,
    required int totalJobs,
    required double totalCash,
    required List<MetricsBucket> buckets,
  }) = _TechnicianMetricsEntity;
}

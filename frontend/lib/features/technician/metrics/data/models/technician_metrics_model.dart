import '../../domain/entities/technician_metrics_entity.dart';

/// DTO for GET /api/technicians/metrics/
/// All numeric fields default to 0 for backward compat if the backend
/// ever omits a field during a rolling deploy.
class TechnicianMetricsModel {
  final int jobsCompletedToday;
  final double cashCollectedToday;
  final double commissionDeductedToday;
  final int jobsCompletedThisWeek;
  final double cashCollectedThisWeek;

  const TechnicianMetricsModel({
    required this.jobsCompletedToday,
    required this.cashCollectedToday,
    required this.commissionDeductedToday,
    required this.jobsCompletedThisWeek,
    required this.cashCollectedThisWeek,
  });

  factory TechnicianMetricsModel.fromJson(Map<String, dynamic> json) =>
      TechnicianMetricsModel(
        jobsCompletedToday:
            (json['jobs_completed_today'] as num? ?? 0).toInt(),
        cashCollectedToday:
            (json['cash_collected_today'] as num? ?? 0).toDouble(),
        commissionDeductedToday:
            (json['commission_deducted_today'] as num? ?? 0).toDouble(),
        jobsCompletedThisWeek:
            (json['jobs_completed_this_week'] as num? ?? 0).toInt(),
        cashCollectedThisWeek:
            (json['cash_collected_this_week'] as num? ?? 0).toDouble(),
      );

  TechnicianMetricsEntity toEntity() => TechnicianMetricsEntity(
        jobsCompletedToday: jobsCompletedToday,
        cashCollectedToday: cashCollectedToday,
        commissionDeductedToday: commissionDeductedToday,
        jobsCompletedThisWeek: jobsCompletedThisWeek,
        cashCollectedThisWeek: cashCollectedThisWeek,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechnicianMetricsModel &&
          jobsCompletedToday == other.jobsCompletedToday &&
          cashCollectedToday == other.cashCollectedToday &&
          commissionDeductedToday == other.commissionDeductedToday &&
          jobsCompletedThisWeek == other.jobsCompletedThisWeek &&
          cashCollectedThisWeek == other.cashCollectedThisWeek;

  @override
  int get hashCode =>
      jobsCompletedToday.hashCode ^
      cashCollectedToday.hashCode ^
      commissionDeductedToday.hashCode ^
      jobsCompletedThisWeek.hashCode ^
      cashCollectedThisWeek.hashCode;
}

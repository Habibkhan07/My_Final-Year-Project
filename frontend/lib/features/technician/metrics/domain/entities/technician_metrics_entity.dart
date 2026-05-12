import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_metrics_entity.freezed.dart';

/// Contract: Fed by GET /api/technicians/metrics/
///
/// Covers today and the current ISO week (Monday–Sunday).
/// [commissionDeductedToday] is always a positive figure — the ledger stores
/// it negative but the selector flips the sign before returning it.
@freezed
abstract class TechnicianMetricsEntity with _$TechnicianMetricsEntity {
  const factory TechnicianMetricsEntity({
    required int jobsCompletedToday,
    required double cashCollectedToday,
    required double commissionDeductedToday,
    required int jobsCompletedThisWeek,
    required double cashCollectedThisWeek,
  }) = _TechnicianMetricsEntity;
}

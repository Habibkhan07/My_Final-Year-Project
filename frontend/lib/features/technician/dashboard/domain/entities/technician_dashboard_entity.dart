import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_dashboard_entity.freezed.dart';

/// Contract: Fed by GET /api/technicians/dashboard/
@freezed
abstract class UpNextJobEntity with _$UpNextJobEntity {
  const factory UpNextJobEntity({
    required int jobId,
    required String serviceTitle,
    required DateTime scheduledTime,
    required String customerName,
    required String addressText,
    required double lat,
    required double lng,
  }) = _UpNextJobEntity;
}

/// Contract: Fed by GET /api/technicians/dashboard/
@freezed
abstract class LaterTodayJobEntity with _$LaterTodayJobEntity {
  const factory LaterTodayJobEntity({
    required int jobId,
    required String serviceTitle,
    required DateTime scheduledTime,
    required String addressText,
  }) = _LaterTodayJobEntity;
}

/// Contract: Fed by GET /api/technicians/dashboard/
@freezed
abstract class DashboardMetricsEntity with _$DashboardMetricsEntity {
  const factory DashboardMetricsEntity({
    required int jobsCompletedToday,
    required double cashCollectedToday,
  }) = _DashboardMetricsEntity;
}

/// Contract: Fed by GET /api/technicians/dashboard/
/// Master entity for the technician's daily overview.
@freezed
abstract class TechnicianDashboardEntity with _$TechnicianDashboardEntity {
  const factory TechnicianDashboardEntity({
    required double walletBalance,
    required bool isOnline,
    String? profilePicture,
    UpNextJobEntity? upNextJob,
    required List<LaterTodayJobEntity> laterTodayJobs,
    required DashboardMetricsEntity metrics,
  }) = _TechnicianDashboardEntity;
}

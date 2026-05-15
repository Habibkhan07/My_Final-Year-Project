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
    String? customerPhone,
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
/// Metrics (activity + earnings history) are served by the dedicated
/// GET /api/technicians/metrics/ endpoint — see features/technician/metrics/.
@freezed
abstract class TechnicianDashboardEntity with _$TechnicianDashboardEntity {
  const factory TechnicianDashboardEntity({
    required double walletBalance,
    required bool isOnline,
    String? profilePicture,
    UpNextJobEntity? upNextJob,
    required List<LaterTodayJobEntity> laterTodayJobs,
    // ``hasWorkLocation`` gates the in-dashboard banner that prompts the tech
    // to set their work area. Backend-derived: true iff both base_latitude and
    // base_longitude are non-null on TechnicianProfile. Default false for
    // backwards compat — older cached payloads pre-dating this rollout get
    // treated as "not set" so the banner appears once on first launch.
    @Default(false) bool hasWorkLocation,
    String? workAddressLabel,
  }) = _TechnicianDashboardEntity;
}

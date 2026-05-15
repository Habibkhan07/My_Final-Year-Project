import '../../domain/entities/technician_status.dart';

/// Wire shape for `GET /api/technicians/me/status/`. Kept as a plain
/// data class — too small for freezed — and the mapper to the sealed
/// [TechnicianStatus] lives next to it so wire-string handling stays in
/// one file.
class TechnicianStatusModel {
  final bool hasProfile;
  final String? status; // "PENDING" / "APPROVED" / "REJECTED" / null
  final String? rejectionReason;

  const TechnicianStatusModel({
    required this.hasProfile,
    required this.status,
    required this.rejectionReason,
  });

  factory TechnicianStatusModel.fromJson(Map<String, dynamic> json) {
    return TechnicianStatusModel(
      hasProfile: json['has_profile'] as bool? ?? false,
      status: json['status'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  /// Wire-string → sealed variant. An unknown `status` value defaults to
  /// [TechnicianStatusNoProfile] so a backend rollout that adds a fourth
  /// state cannot strand the router on a non-exhaustive switch.
  TechnicianStatus toEntity() {
    if (!hasProfile) return const TechnicianStatusNoProfile();
    switch (status) {
      case 'PENDING':
        return const TechnicianStatusPending();
      case 'APPROVED':
        return const TechnicianStatusApproved();
      case 'REJECTED':
        return TechnicianStatusRejected(reason: rejectionReason);
      default:
        return const TechnicianStatusNoProfile();
    }
  }
}

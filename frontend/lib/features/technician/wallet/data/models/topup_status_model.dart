import '../../domain/entities/topup_status.dart';
import '../../domain/entities/topup_status_type.dart';

/// Wire-shape for ``GET /api/technicians/wallet/topups/<id>/``.
///
/// Backend response (200):
/// ```json
/// {
///   "topup_id": 42,
///   "status": "REDIRECTED",
///   "amount": "1000.00",
///   "gateway_name": "jazzcash",
///   "initiated_at": "2026-05-14T10:00:00Z",
///   "completed_at": null
/// }
/// ```
///
/// ``status`` is one of the [TopupStatusType] wire-strings; unknown
/// values fail closed to [TopupStatusType.failed] at the mapper.
class TopupStatusModel {
  final int topupId;
  final String status;
  final String amount;
  final String gatewayName;
  final String initiatedAt;
  final String? completedAt;

  const TopupStatusModel({
    required this.topupId,
    required this.status,
    required this.amount,
    required this.gatewayName,
    required this.initiatedAt,
    required this.completedAt,
  });

  factory TopupStatusModel.fromJson(Map<String, dynamic> json) =>
      TopupStatusModel(
        topupId: json['topup_id'] as int,
        status: json['status'] as String,
        amount: json['amount'] as String,
        gatewayName: json['gateway_name'] as String,
        initiatedAt: json['initiated_at'] as String,
        completedAt: json['completed_at'] as String?,
      );

  TopupStatus toEntity() => TopupStatus(
        topupId: topupId,
        status: TopupStatusTypeX.parse(status),
        amount: double.parse(amount),
        gatewayName: gatewayName,
        initiatedAt: DateTime.parse(initiatedAt),
        completedAt: completedAt == null ? null : DateTime.parse(completedAt!),
      );
}

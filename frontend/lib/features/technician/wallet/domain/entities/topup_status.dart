import 'topup_status_type.dart';

/// Server-side snapshot of a top-up attempt. Returned by
/// ``GET /api/technicians/wallet/topups/<id>/`` and polled by the
/// notifier while the tech is in the JazzCash webview.
class TopupStatus {
  final int topupId;
  final TopupStatusType status;
  final double amount;
  final String gatewayName;
  final DateTime initiatedAt;
  final DateTime? completedAt;

  const TopupStatus({
    required this.topupId,
    required this.status,
    required this.amount,
    required this.gatewayName,
    required this.initiatedAt,
    required this.completedAt,
  });

  /// Convenience — true when [status] is in a terminal state and the
  /// notifier can stop polling.
  bool get isTerminal => status.isTerminal;

  /// Convenience — true only on [TopupStatusType.completed].
  bool get isSuccess => status.isSuccess;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopupStatus &&
          topupId == other.topupId &&
          status == other.status &&
          amount == other.amount &&
          gatewayName == other.gatewayName &&
          initiatedAt == other.initiatedAt &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(
        topupId,
        status,
        amount,
        gatewayName,
        initiatedAt,
        completedAt,
      );
}

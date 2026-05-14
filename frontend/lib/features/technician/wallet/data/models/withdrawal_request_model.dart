import '../../domain/entities/withdrawal_history_page.dart';
import '../../domain/entities/withdrawal_request.dart';
import '../../domain/entities/withdrawal_status.dart';

/// Wire shape for the create-201 response and each row of the
/// list-200 response on the withdrawals endpoint.
///
/// Mirrors ``backend/wallet/api/serializers.py::WithdrawalRequestReadSerializer``.
/// Decimal amount ships as a string ``"500.00"`` to preserve precision
/// across the JSON boundary; we parse to double here at the data
/// boundary so the domain layer sees a typed value.
class WithdrawalRequestModel {
  final int id;
  final String amount; // Decimal-as-string from server, e.g. "500.00"
  final String status; // Wire enum string, e.g. "PENDING_REVIEW"
  final String uiStatusLabel;
  final PayoutDescriptorModel payout;
  final String adminExternalRef;
  final String requestedAt; // ISO-8601
  final String? reviewedAt; // ISO-8601 or null

  const WithdrawalRequestModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.uiStatusLabel,
    required this.payout,
    required this.adminExternalRef,
    required this.requestedAt,
    required this.reviewedAt,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) =>
      WithdrawalRequestModel(
        id: json['id'] as int,
        amount: (json['amount'] as String?) ?? '0.00',
        status: (json['status'] as String?) ?? 'PENDING_REVIEW',
        uiStatusLabel: (json['ui_status_label'] as String?) ?? '',
        payout: PayoutDescriptorModel.fromJson(
          (json['payout'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
        ),
        adminExternalRef: (json['admin_external_ref'] as String?) ?? '',
        requestedAt: (json['requested_at'] as String?) ?? '',
        reviewedAt: json['reviewed_at'] as String?,
      );

  WithdrawalRequest toEntity() => WithdrawalRequest(
        id: id,
        amount: double.tryParse(amount) ?? 0.0,
        status: WithdrawalStatus.fromWire(status),
        uiStatusLabel: uiStatusLabel,
        payout: payout.toEntity(),
        adminExternalRef: adminExternalRef,
        // ``requestedAt`` is required on the server; the empty-string
        // fallback above is paranoia. ``DateTime.tryParse`` keeps the
        // parser non-throwing if the wire drifts.
        requestedAt:
            DateTime.tryParse(requestedAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
        reviewedAt: reviewedAt == null ? null : DateTime.tryParse(reviewedAt!),
      );
}

class PayoutDescriptorModel {
  final String kind;
  final String label;
  final String masked;

  const PayoutDescriptorModel({
    required this.kind,
    required this.label,
    required this.masked,
  });

  factory PayoutDescriptorModel.fromJson(Map<String, dynamic> json) =>
      PayoutDescriptorModel(
        kind: (json['kind'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
        masked: (json['masked'] as String?) ?? '',
      );

  PayoutDescriptor toEntity() =>
      PayoutDescriptor(kind: kind, label: label, masked: masked);
}

/// Wire shape for ``GET /api/technicians/wallet/withdrawals/``.
///
/// Same cursor-pagination contract as the wallet transactions
/// endpoint — opaque ``next_cursor`` plus a ``results`` array.
class WithdrawalHistoryPageModel {
  final List<WithdrawalRequestModel> results;
  final String? nextCursor;

  const WithdrawalHistoryPageModel({
    required this.results,
    required this.nextCursor,
  });

  factory WithdrawalHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['results'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => WithdrawalRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return WithdrawalHistoryPageModel(
      results: raw,
      nextCursor: json['next_cursor'] as String?,
    );
  }

  WithdrawalHistoryPage toEntity() => WithdrawalHistoryPage(
        results: results.map((m) => m.toEntity()).toList(),
        nextCursor: nextCursor,
      );
}

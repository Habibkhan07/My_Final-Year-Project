import 'withdrawal_status.dart';

/// One tech-facing withdrawal request row.
///
/// Mirrors the backend's ``WithdrawalRequestReadSerializer`` from
/// ``backend/wallet/api/serializers.py``. Wire format is reshaped at
/// the data layer:
///
/// * ``amount``       — Decimal-as-string ``"500.00"`` → ``double``.
/// * ``status``       — wire enum string → [WithdrawalStatus].
/// * ``requested_at`` / ``reviewed_at`` — ISO-8601 strings → DateTime.
///
/// ``uiStatusLabel`` is Dumb-UI ready — the row widget renders it
/// verbatim and never branches on [status].
///
/// ``adminExternalRef`` is the backend's narrowing field: empty string
/// until status reaches ``PROCESSED``, then carries the admin-entered
/// bank wire / JazzCash merchant reference. The history-row widget
/// surfaces it as a copyable receipt id when present.
class WithdrawalRequest {
  final int id;
  final double amount;
  final WithdrawalStatus status;
  final String uiStatusLabel;
  final PayoutDescriptor payout;
  final String adminExternalRef;
  final DateTime requestedAt;
  final DateTime? reviewedAt;

  const WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.status,
    required this.uiStatusLabel,
    required this.payout,
    required this.adminExternalRef,
    required this.requestedAt,
    required this.reviewedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithdrawalRequest &&
          id == other.id &&
          amount == other.amount &&
          status == other.status &&
          uiStatusLabel == other.uiStatusLabel &&
          payout == other.payout &&
          adminExternalRef == other.adminExternalRef &&
          requestedAt == other.requestedAt &&
          reviewedAt == other.reviewedAt;

  @override
  int get hashCode => Object.hash(
        id,
        amount,
        status,
        uiStatusLabel,
        payout,
        adminExternalRef,
        requestedAt,
        reviewedAt,
      );
}

/// Snapshot of the payout target carried inline on a [WithdrawalRequest].
///
/// Separate from the standalone [PayoutAccount] sealed family because
/// the wire shape here is a single denormalised block ``{kind, label,
/// masked}`` rather than two parallel lists. This is what the row
/// widget renders — no FK chase, no second fetch.
///
/// [kind] is intentionally a String (``"bank"`` / ``"jazzcash"``)
/// rather than an enum so an unknown future kind doesn't crash the
/// parser; the row widget treats anything other than ``"bank"`` /
/// ``"jazzcash"`` as a generic fallback.
class PayoutDescriptor {
  /// Wire string: ``"bank"`` or ``"jazzcash"``. Drives the icon choice.
  final String kind;

  /// Human label, e.g. "HBL — Ali Khan" or "JazzCash — Ali Khan".
  final String label;

  /// Masked account number / MSISDN, e.g. ``"••1234"`` or
  /// ``"+923•••567"``. Raw value never reaches the client.
  final String masked;

  const PayoutDescriptor({
    required this.kind,
    required this.label,
    required this.masked,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayoutDescriptor &&
          kind == other.kind &&
          label == other.label &&
          masked == other.masked;

  @override
  int get hashCode => Object.hash(kind, label, masked);
}

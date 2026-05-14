/// Lifecycle of a single withdrawal request.
///
/// Wire-string values mirror the backend's ``WithdrawalStatus``
/// TextChoices (see ``backend/wallet/models.py``):
///
/// * ``PENDING_REVIEW``  — fresh submit; admin has not acted yet.
/// * ``APPROVED``        — admin approved; money transfer in progress
///                          (external bank wire / JazzCash merchant);
///                          fulfilment row not yet written.
/// * ``REJECTED``        — admin rejected. Tech can submit a new one.
/// * ``PROCESSED``       — admin clicked Done; WITHDRAWAL_DEBIT row
///                          written; balance debited.
///
/// PENDING_REVIEW + APPROVED are both "in-flight" from the tech's POV
/// — either state blocks a fresh submit (backend returns 409
/// ``duplicate_pending_withdrawal``).
enum WithdrawalStatus {
  pendingReview,
  approved,
  rejected,
  processed;

  /// Parse the backend's wire-string into the enum. Returns
  /// [WithdrawalStatus.pendingReview] as a defensive fallback so an
  /// unrecognised value (mid-rollout new state, mistyped fixture)
  /// doesn't crash the parser — the UI surfaces "Under review" which
  /// is the most conservative interpretation.
  static WithdrawalStatus fromWire(String raw) {
    switch (raw) {
      case 'PENDING_REVIEW':
        return WithdrawalStatus.pendingReview;
      case 'APPROVED':
        return WithdrawalStatus.approved;
      case 'REJECTED':
        return WithdrawalStatus.rejected;
      case 'PROCESSED':
        return WithdrawalStatus.processed;
      default:
        return WithdrawalStatus.pendingReview;
    }
  }

  /// True if this status counts as "in-flight" (blocks a new submit).
  /// The UI uses this to render the pending pill on the wallet screen.
  bool get isInFlight =>
      this == WithdrawalStatus.pendingReview ||
      this == WithdrawalStatus.approved;
}

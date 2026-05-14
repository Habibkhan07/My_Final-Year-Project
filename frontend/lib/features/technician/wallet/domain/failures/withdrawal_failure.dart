/// Sealed failure hierarchy for the withdrawal flow.
///
/// Mapped from data-layer ``HttpFailure`` / ``SocketException`` in
/// ``WithdrawalRepositoryImpl``. One subclass per backend error
/// envelope ``code`` — the frontend's ``_mapFailures`` switches on
/// ``code`` (not status) so a future status renumbering is transparent.
///
/// Distinct hierarchy from [WalletFailure] / [TopupFailure] because
/// the withdrawal flow has its own error space (insufficient funds,
/// duplicate pending, payout-account resolution) that doesn't overlap
/// with balance reads or top-ups. The withdrawal sheet pattern-matches
/// on this family in a ``switch`` expression to render error copy
/// without branching on strings.
///
/// Wire contracts live in ``backend/wallet/api/WALLET_API.md`` —
/// keep them in sync with the subclasses below.
sealed class WithdrawalFailure implements Exception {
  final String message;
  const WithdrawalFailure(this.message);
}

/// Backend ``400 insufficient_funds`` — amount > current wallet balance.
///
/// Wire envelope:
/// ```
/// { "status": 400, "code": "insufficient_funds",
///   "message": "Cannot withdraw Rs. X. Available balance: Rs. Y.",
///   "errors": {"requested_pkr": ["X"], "available_pkr": ["Y"]} }
/// ```
///
/// The ints are asymmetrically rounded by the backend: requested with
/// ROUND_CEILING, available with ROUND_FLOOR — so the displayed gap
/// never collapses to zero when the gate trips. The sheet can render
/// "You requested Rs. X but have Rs. Y" verbatim from these fields.
class InsufficientFundsFailure extends WithdrawalFailure {
  final int requestedPkr;
  final int availablePkr;

  const InsufficientFundsFailure({
    required this.requestedPkr,
    required this.availablePkr,
    String? customMessage,
  }) : super(customMessage ?? 'Withdrawal amount exceeds available balance.');
}

/// Backend ``403 wallet_lockout`` — tech's balance is negative.
///
/// Distinct from the wallet feature's [WalletLockoutFailure] so the
/// withdrawal sheet's pattern-match stays within its own sealed family.
/// Wire contract is identical to the booking-accept lockout envelope:
/// ``balance_pkr`` (negative) + ``owed_pkr`` (positive).
class WalletLockoutForWithdrawalFailure extends WithdrawalFailure {
  final int balancePkr;
  final int owedPkr;

  const WalletLockoutForWithdrawalFailure({
    required this.balancePkr,
    required this.owedPkr,
  }) : super(
          'Wallet is locked. Top up to continue.',
        );
}

/// Backend ``409 duplicate_pending_withdrawal`` — an open
/// ``PENDING_REVIEW`` or ``APPROVED`` request already exists for this
/// tech. Server enforces "one in-flight per tech".
///
/// Carries the pending request's id so the sheet can deep-link the
/// tech to its row in the history screen ("View pending request →").
class DuplicatePendingWithdrawalFailure extends WithdrawalFailure {
  final int pendingRequestId;

  const DuplicatePendingWithdrawalFailure({
    required this.pendingRequestId,
  }) : super(
          'A previous withdrawal is still under review. '
          'Wait for it to be processed before submitting a new one.',
        );
}

/// Backend ``403 inactive_technician`` — tech is not APPROVED, or is
/// approved but ``is_active=False`` (admin soft-ban).
///
/// [status] carries the raw ``TechnicianProfile.status`` value
/// (``"PENDING"`` / ``"REJECTED"``) OR the synthetic ``"DEACTIVATED"``
/// sentinel when the gate trips on ``is_active=False``. The sheet
/// branches on this to show "Account approval pending" vs "Account
/// deactivated — contact support".
class InactiveTechnicianForWithdrawalFailure extends WithdrawalFailure {
  final String status;

  const InactiveTechnicianForWithdrawalFailure({
    required this.status,
  }) : super(
          'Your technician account is not approved for withdrawals.',
        );
}

/// Backend ``400 validation_error`` with a payout-account field key.
///
/// Covers three indistinguishable-by-design server-side cases:
///   * IDOR attempt (payout account belongs to a different tech),
///   * soft-deleted account (``is_active=False``),
///   * unknown id (account never existed).
///
/// The backend collapses all three to the same generic message — no
/// information disclosure about whether the id was real-but-foreign vs
/// real-but-inactive vs never-existed. The sheet renders a generic
/// "Selected payout account is no longer available — please pick
/// another" and re-fetches the picker list.
class InvalidPayoutAccountFailure extends WithdrawalFailure {
  const InvalidPayoutAccountFailure([
    super.message =
        'Selected payout account is no longer available. Please pick another.',
  ]);
}

/// Backend ``400 validation_error`` on the amount field (out of range
/// at the serializer's ``min_value`` / ``max_value`` / ``decimal_places``).
///
/// The server's per-field message is surfaced verbatim because the
/// localised bounds copy lives on the backend (server is the source
/// of truth for the Rs.1–5000 window).
class WithdrawalAmountOutOfRangeFailure extends WithdrawalFailure {
  const WithdrawalAmountOutOfRangeFailure(super.message);
}

/// Fallback for ``400 validation_error`` envelopes that don't match a
/// more specific subclass above (e.g. XOR rule violation when both
/// payout ids are sent, or neither). Carries the server's message
/// verbatim because the XOR shape is unusual enough that a generic
/// "Invalid input" wouldn't help the user.
class WithdrawalValidationFailure extends WithdrawalFailure {
  const WithdrawalValidationFailure(super.message);
}

/// Device offline during submit / list / fetch.
///
/// **No cache fallback** for withdrawals — money-movement requests
/// must NEVER succeed against a stale view of the balance. Per the
/// wallet-vs-financial-truth rule (Fix #9): surface the offline error
/// and let the sheet render "Check your connection and try again."
class WithdrawalNetworkFailure extends WithdrawalFailure {
  const WithdrawalNetworkFailure([
    super.message = 'No internet connection. Please check your settings.',
  ]);
}

/// Backend returned 5xx OR response was unparseable.
///
/// The sheet renders a generic "Something went wrong on our end" and
/// suggests a retry. Logged at the data layer for ops visibility.
class WithdrawalServerFailure extends WithdrawalFailure {
  const WithdrawalServerFailure([
    super.message = 'Withdrawal service is having trouble. Please try again.',
  ]);
}

/// Backend returned 401/403 generic — token expired, or the user is
/// somehow not a registered technician despite reaching this code
/// path. Sheet surfaces a re-login prompt.
class WithdrawalPermissionFailure extends WithdrawalFailure {
  const WithdrawalPermissionFailure([
    super.message = 'You do not have permission to withdraw.',
  ]);
}

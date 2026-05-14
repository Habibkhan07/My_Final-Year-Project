/// Sealed failure hierarchy for the wallet feature.
///
/// Mapped from data-layer ``HttpFailure`` / ``SocketException`` in
/// ``WalletRepositoryImpl``. Each case has user-facing copy attached so
/// the screen can render via a switch expression with no string lookup.
sealed class WalletFailure implements Exception {
  final String message;
  const WalletFailure(this.message);
}

/// Device offline AND no cached value to fall back on.
///
/// Per CLAUDE.md Tier 3 storage rule + Fix #9: wallet balance is NEVER
/// served from cache because it's a financial-truth field. So a network
/// failure here is always surfaced explicitly — no silent stale read.
class WalletNetworkFailure extends WalletFailure {
  const WalletNetworkFailure([
    super.message = 'No internet connection. Please check your settings.',
  ]);
}

/// Backend returned 5xx or unparseable.
class WalletServerFailure extends WalletFailure {
  const WalletServerFailure(super.message);
}

/// Backend returned 401/403 — user is not a registered technician, or
/// the token is invalid. Screen surfaces a re-login prompt.
class WalletPermissionFailure extends WalletFailure {
  const WalletPermissionFailure([
    super.message = 'You do not have permission to access the wallet.',
  ]);
}

/// Backend returned 403 `wallet_lockout` — the tech's wallet balance is
/// currently negative and the requested action is gated on a top-up.
///
/// Wire contract (backend ``wallet.exceptions.WalletLockoutError``):
/// ```
/// { "status": 403, "code": "wallet_lockout",
///   "message": "...",
///   "errors": {"balance_pkr": ["-495"], "owed_pkr": ["495"]} }
/// ```
///
/// No wallet endpoint currently raises this — the GET endpoint always
/// succeeds regardless of lockout, and top-ups are explicitly allowed
/// when locked (clearing the lockout is the whole point). This failure
/// exists for the upcoming withdrawal-request endpoint (next sprint
/// item) which WILL gate on it. The mapping path is in place so the
/// wiring is exercised when withdrawal lands.
///
/// For the immediate demo loop, the dashboard banner consumes
/// ``walletState.isLockedOut`` directly off the GET payload — see
/// [WalletState]. This failure is for write-action paths only.
///
/// The accept-job side has its own counterpart in
/// ``IncomingJobFailure.JobAcceptBlockedByLockout`` — distinct
/// hierarchies, identical wire code.
class WalletLockoutFailure extends WalletFailure {
  /// Signed int rupees from the envelope's ``errors.balance_pkr`` (negative).
  final int balancePkr;

  /// Positive int rupees — the top-up amount that clears the lockout
  /// (rounded UP from the paisa fraction so payment never falls short).
  final int owedPkr;

  const WalletLockoutFailure({
    required this.balancePkr,
    required this.owedPkr,
    String message = 'Wallet is locked. Top up to continue.',
  }) : super(message);
}

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

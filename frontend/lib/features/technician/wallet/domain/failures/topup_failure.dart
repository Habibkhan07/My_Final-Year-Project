/// Sealed failure hierarchy for the top-up flow.
///
/// Kept distinct from ``WalletFailure`` because the topup flow has its
/// own error space (gateway unavailable, user-aborted) that doesn't
/// apply to balance reads. The presentation layer pattern-matches over
/// this family in a ``switch`` expression to render error copy without
/// branching on strings.
///
/// Mapped from data-layer ``HttpFailure`` / ``SocketException`` in
/// ``WalletRepositoryImpl.startTopup`` and ``pollTopupStatus``.
sealed class TopupFailure implements Exception {
  final String message;
  const TopupFailure(this.message);
}

/// Amount validation failed (below Rs.100 or above Rs.25,000).
///
/// The min/max are surfaced separately so the sheet can render a
/// localised "Top-up must be between Rs.100 and Rs.25,000" rather
/// than a generic string.
class TopupInvalidAmount extends TopupFailure {
  final int minimum;
  final int maximum;
  const TopupInvalidAmount({
    required this.minimum,
    required this.maximum,
  }) : super('Top-up amount must be between whole rupees.');
}

/// Backend returned 503 ``gateway_unavailable`` — DEFAULT_PAYMENT_GATEWAY
/// is set to ``jazzcash`` but one of the ``JAZZCASH_*`` env vars is
/// empty. Operator-facing problem; tech sees "Top-up is temporarily
/// unavailable. Please try again later."
class TopupGatewayUnavailable extends TopupFailure {
  const TopupGatewayUnavailable([
    super.message = 'Top-up is temporarily unavailable. Please try again later.',
  ]);
}

/// Device offline during start_topup or polling. No cache fallback
/// per the wallet-vs-financial-truth rule.
class TopupNetworkFailure extends TopupFailure {
  const TopupNetworkFailure([
    super.message = 'No internet connection. Please check your settings.',
  ]);
}

/// Backend returned 5xx or response was unparseable.
class TopupServerFailure extends TopupFailure {
  const TopupServerFailure([
    super.message = 'Top-up service is having trouble. Please try again.',
  ]);
}

/// Backend returned 401/403. Token expired or user is not a technician.
class TopupPermissionFailure extends TopupFailure {
  const TopupPermissionFailure([
    super.message = 'You do not have permission to top up.',
  ]);
}

/// Tech explicitly closed the webview (back button, X tap, system
/// back gesture). Distinct from a gateway-side failure so analytics
/// + screen copy can treat it specially.
class TopupUserAborted extends TopupFailure {
  const TopupUserAborted([
    super.message = 'Top-up cancelled.',
  ]);
}

/// Polling exhausted the 30-second budget without a terminal status.
/// The topup MAY still complete server-side via the gateway's
/// asynchronous callback — the next pull-to-refresh on the wallet
/// screen will surface the result.
class TopupPollTimeout extends TopupFailure {
  const TopupPollTimeout([
    super.message =
        'We could not confirm the top-up status. Pull to refresh in a few seconds.',
  ]);
}

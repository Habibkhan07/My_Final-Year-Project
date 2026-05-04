/// Sealed failure hierarchy for the customer bookings feature.
///
/// Five distinct outcomes that map to distinct UI affordances:
///
///   * [CustomerBookingsNetworkFailure] — `SocketException` with a
///     cache hit. The notifier surfaces the cached page with the
///     `isStaleCache` flag set; the screen shows the offline banner.
///
///   * [CustomerBookingsOfflineNoCache] — `SocketException` with no
///     cache to fall back to. The screen shows the centered offline
///     empty state with a retry button.
///
///   * [CustomerBookingsServerFailure] — HTTP 5xx. Centered error
///     state + retry button. Distinct from the offline state so the
///     copy can read "Couldn't load your bookings" rather than
///     accusing the user's connection.
///
///   * [CustomerBookingsValidationFailure] — HTTP 400 with one of the
///     specific codes the list endpoint can return
///     (`invalid_status_filter`, `invalid_cursor`,
///     `validation_error`). The notifier should clear the offending
///     parameter (cursor or filter) and re-fetch; surfacing this to
///     the user as a snackbar is a fallback for unexpected codes only.
///
///   * [UnknownCustomerBookingsFailure] — catch-all. Same UX as the
///     server failure (retry surfaced) but the message stays neutral.
sealed class CustomerBookingsFailure implements Exception {
  final String message;
  const CustomerBookingsFailure(this.message);
}

/// `SocketException` path **with a cache hit**. The repository served
/// the cached page; this exception is thrown only when the caller
/// explicitly opted into "fail on cache fallback" mode (e.g. a
/// pull-to-refresh that should not pretend to succeed). Default behavior
/// returns the stale page silently with the `isStaleCache` flag set.
class CustomerBookingsNetworkFailure extends CustomerBookingsFailure {
  const CustomerBookingsNetworkFailure([
    super.message = 'No internet connection. Showing your last cached list.',
  ]);
}

/// `SocketException` with **no** cache to fall back to. The screen
/// shows a centered offline empty state with a retry button.
class CustomerBookingsOfflineNoCache extends CustomerBookingsFailure {
  const CustomerBookingsOfflineNoCache([
    super.message = "You're offline. Connect and try again.",
  ]);
}

/// HTTP 5xx — backend hit an internal error.
class CustomerBookingsServerFailure extends CustomerBookingsFailure {
  const CustomerBookingsServerFailure([
    super.message = "Couldn't load your bookings. Please try again.",
  ]);
}

/// HTTP 400 — the request itself was bad. The list endpoint emits
/// three distinct codes here:
///
///   * `invalid_status_filter` — caller passed an unknown status csv.
///   * `invalid_cursor` — opaque cursor token failed decoding.
///   * `validation_error` — generic field-level error envelope (e.g.
///     `page_size` out of range).
///
/// The repository carries the wire `code` so the notifier can branch
/// on it (typically: drop the cursor, refetch the first page).
class CustomerBookingsValidationFailure extends CustomerBookingsFailure {
  /// Wire `code` from the standard error envelope.
  final String code;

  /// Field-level errors map from the envelope's `errors` field.
  final Map<String, dynamic> errors;

  const CustomerBookingsValidationFailure({
    required this.code,
    this.errors = const {},
    String message = 'Invalid request.',
  }) : super(message);
}

/// Catch-all for the unclassified path. Mirrors the technician
/// feature's `UnknownIncomingJobFailure` semantics — keep the
/// retry affordance, neutral copy.
class UnknownCustomerBookingsFailure extends CustomerBookingsFailure {
  const UnknownCustomerBookingsFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

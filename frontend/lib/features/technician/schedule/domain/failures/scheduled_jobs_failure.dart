/// Sealed failure hierarchy for the technician schedule feature.
///
/// Mirrors the customer-side `CustomerBookingsFailure` taxonomy: five
/// outcomes that map to distinct UI affordances. The split is duplicated
/// rather than shared so each feature owns its own copy strings and so
/// future tech-only failure variants (e.g. "wallet-lockout blocks
/// schedule load") can be added without coupling.
///
///   * [ScheduledJobsNetworkFailure] — `SocketException` with cache hit.
///     Notifier surfaces the cached page with `isStaleCache=true`;
///     screen shows the offline banner.
///
///   * [ScheduledJobsOfflineNoCache] — `SocketException` with no cache.
///     Centered offline empty state + retry.
///
///   * [ScheduledJobsServerFailure] — HTTP 5xx. Centered error state +
///     retry. Copy stays neutral ("Couldn't load your schedule") rather
///     than blaming the connection.
///
///   * [ScheduledJobsValidationFailure] — HTTP 400 with one of the
///     specific codes from `SCHEDULED_JOBS_API.md` §1.5
///     (`invalid_status_filter`, `invalid_cursor`, `validation_error`).
///     The notifier should drop the offending param (cursor or filter)
///     and re-fetch; surfacing this to the user as a snackbar is a
///     fallback for unexpected codes only.
///
///   * [UnknownScheduledJobsFailure] — catch-all. Same UX as the server
///     failure but neutral message.
sealed class ScheduledJobsFailure implements Exception {
  final String message;
  const ScheduledJobsFailure(this.message);
}

class ScheduledJobsNetworkFailure extends ScheduledJobsFailure {
  const ScheduledJobsNetworkFailure([
    super.message = 'No internet connection. Showing your last cached schedule.',
  ]);
}

class ScheduledJobsOfflineNoCache extends ScheduledJobsFailure {
  const ScheduledJobsOfflineNoCache([
    super.message = "You're offline. Connect and try again.",
  ]);
}

class ScheduledJobsServerFailure extends ScheduledJobsFailure {
  const ScheduledJobsServerFailure([
    super.message = "Couldn't load your schedule. Please try again.",
  ]);
}

class ScheduledJobsValidationFailure extends ScheduledJobsFailure {
  /// Wire `code` from the standard error envelope.
  final String code;

  /// Field-level errors map from the envelope's `errors` field.
  final Map<String, dynamic> errors;

  const ScheduledJobsValidationFailure({
    required this.code,
    this.errors = const {},
    String message = 'Invalid request.',
  }) : super(message);
}

class UnknownScheduledJobsFailure extends ScheduledJobsFailure {
  const UnknownScheduledJobsFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

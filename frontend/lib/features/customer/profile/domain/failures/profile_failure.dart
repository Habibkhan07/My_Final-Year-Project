/// Sealed failure hierarchy for the customer profile feature.
///
/// Every method on `IProfileRepository` throws a subclass of this. The
/// presentation layer pattern-matches exhaustively on these so a new
/// failure type is a compile error at every consumer until handled.
///
/// `toString()` returns only the human-readable message so a stray
/// `error.toString()` in a snackbar never leaks the Dart class name.
sealed class ProfileFailure implements Exception {
  final String message;
  const ProfileFailure(this.message);

  @override
  String toString() => message;
}

/// `SocketException` on the data source AND the local cache is empty
/// (or stale beyond what the offline-first fall-back can recover from).
class ProfileNetworkFailure extends ProfileFailure {
  const ProfileNetworkFailure([
    super.message = 'No internet connection. Please check your settings.',
  ]);
}

/// Non-2xx from the backend that is NOT 401. Carries the field-level
/// error map straight from the standard error envelope so the edit
/// screen can highlight specific fields (`errors[first_name]`, etc.).
class ProfileServerFailure extends ProfileFailure {
  final Map<String, dynamic> errors;
  const ProfileServerFailure(super.message, [this.errors = const {}]);
}

/// 401 from the backend — the cached token is dead. The auth notifier
/// should treat this as a forced logout (clear storage + redirect to
/// `/login` via go_router's existing `user == null` guard).
class ProfileUnauthorizedFailure extends ProfileFailure {
  const ProfileUnauthorizedFailure([super.message = 'Session expired. Please sign in again.']);
}

/// Malformed JSON / unexpected wire shape. Distinct from server failure
/// so dashboards can tell "backend is up but contract drifted" from
/// "backend rejected the call".
class ProfileParsingFailure extends ProfileFailure {
  const ProfileParsingFailure([super.message = 'Failed to read profile data.']);
}

/// All failure states for the technician work-location feature.
///
/// The repository maps every wire-level failure to one of these sealed
/// subclasses so the presentation layer can pattern-match without ever
/// touching raw HTTP / JSON shapes (per CLAUDE.md error-propagation rules).
sealed class WorkLocationFailure implements Exception {
  final String message;
  const WorkLocationFailure(this.message);

  @override
  String toString() => message;
}

/// Device has no active connection.
class WorkLocationNetworkFailure extends WorkLocationFailure {
  const WorkLocationNetworkFailure([
    super.message = 'No internet connection. Please check your settings.',
  ]);
}

/// 4xx where the caller submitted invalid data (lat/lng out of range, etc.).
class WorkLocationValidationFailure extends WorkLocationFailure {
  const WorkLocationValidationFailure(super.message);
}

/// 404 — the user has no technician profile to update. Most likely a pure
/// customer routed into this screen by mistake.
class WorkLocationProfileMissingFailure extends WorkLocationFailure {
  const WorkLocationProfileMissingFailure([
    super.message =
        'You do not have a technician profile yet. Apply to be a technician first.',
  ]);
}

/// 401 — caller's token expired / missing. Auth shell handles routing back
/// to login; the screen renders the message until that takes over.
class WorkLocationUnauthorizedFailure extends WorkLocationFailure {
  const WorkLocationUnauthorizedFailure([
    super.message = 'Your session has expired. Please log in again.',
  ]);
}

/// 5xx or any non-classifiable failure.
class WorkLocationServerFailure extends WorkLocationFailure {
  const WorkLocationServerFailure(super.message);
}

/// JSON shape did not match the contract — defensive against backend rollout
/// drift. Keeping it separate from server failure makes the diff obvious in
/// observability dashboards.
class WorkLocationParsingFailure extends WorkLocationFailure {
  const WorkLocationParsingFailure([
    super.message = 'Failed to parse the server response.',
  ]);
}

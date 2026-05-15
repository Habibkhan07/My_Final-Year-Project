/// Failures that can happen while resolving the current user's technician
/// status. Kept separate from [TechnicianFailure] because the consumer is
/// the router — not the onboarding form — and bundling them would force
/// the router to switch over irrelevant variants like `DuplicateTechnician`.
sealed class TechStatusFailure implements Exception {
  const TechStatusFailure();
}

/// 401 — auth token missing / expired. The router should route to /login.
class TechStatusUnauthorized extends TechStatusFailure {
  const TechStatusUnauthorized();
}

/// Device is offline or the backend is unreachable.
class TechStatusNetworkFailure extends TechStatusFailure {
  final String message;
  const TechStatusNetworkFailure([this.message = 'No internet connection']);
}

/// Anything else — 5xx, malformed payload, unexpected `code`.
class TechStatusServerFailure extends TechStatusFailure {
  final String message;
  const TechStatusServerFailure(this.message);
}

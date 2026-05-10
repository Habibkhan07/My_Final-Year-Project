/// Sealed failure family for [IDirectionsService] calls.
///
/// LiveTrackingMap soft-fails on any of these — keeps the last
/// polyline + ETA, hides the ETA pill, and never shows a snackbar to
/// the customer. Routing is best-effort UX polish, not load-bearing
/// truth (the live marker is the authoritative state).
sealed class DirectionsFailure implements Exception {
  const DirectionsFailure();
}

/// Provider responded but had no route between the points (e.g. ocean
/// in between, or impossible road network). OSRM returns
/// `code: NoRoute`; Google returns `status: ZERO_RESULTS`.
class DirectionsNoRoute extends DirectionsFailure {
  const DirectionsNoRoute();
}

/// Google-only — quota / billing / per-day cap exceeded.
class DirectionsApiQuotaExceeded extends DirectionsFailure {
  const DirectionsApiQuotaExceeded();
}

/// HTTP-level 429 from the upstream provider. Distinct from
/// [DirectionsApiQuotaExceeded] (which is the in-band Google `status`
/// signal) so retry policy can back off harder on transport-level rate
/// limiting — public OSRM in particular issues 429s before recovering.
/// Caller must NOT treat this as transient network — retrying inside
/// the cooldown window only deepens the rate limit.
class DirectionsRateLimited extends DirectionsFailure {
  const DirectionsRateLimited();
}

/// SocketException, timeout, or unreachable host.
class DirectionsNetworkFailure extends DirectionsFailure {
  const DirectionsNetworkFailure();
}

/// 5xx from the upstream provider. OSRM's public instance does this
/// occasionally during peak traffic.
class DirectionsServerFailure extends DirectionsFailure {
  final int statusCode;
  const DirectionsServerFailure(this.statusCode);
}

/// Catch-all for malformed bodies, unexpected fields, etc. Carries the
/// underlying message for log triage.
class UnknownDirectionsFailure extends DirectionsFailure {
  final String message;
  const UnknownDirectionsFailure(this.message);
}

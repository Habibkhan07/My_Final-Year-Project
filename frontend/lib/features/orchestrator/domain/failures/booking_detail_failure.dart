/// Sealed failure hierarchy for orchestrator detail fetches.
///
/// Domain layer never sees raw HTTP errors. The data-layer repository
/// maps `HttpFailure` codes / `SocketException` / cache-miss to one of
/// these; the screen pattern-matches on the type to render a friendly
/// message + retry affordance.
sealed class BookingDetailFailure implements Exception {
  const BookingDetailFailure();
}

/// 404 — the booking id doesn't exist (or was hard-deleted).
class BookingDetailNotFound extends BookingDetailFailure {
  final int bookingId;
  const BookingDetailNotFound(this.bookingId);
}

/// 403 `not_a_participant` — the auth user isn't the customer or
/// assigned technician on this booking. Should be unreachable in normal
/// nav flow; surfaces only if a deep-link is forged.
class BookingDetailNotParticipant extends BookingDetailFailure {
  const BookingDetailNotParticipant();
}

/// `SocketException` AND no usable local cache. Distinct from the
/// "offline-but-we-have-cache" path, which returns the cached entity
/// without throwing.
class BookingDetailOfflineNoCache extends BookingDetailFailure {
  const BookingDetailOfflineNoCache();
}

/// Generic transport failure (e.g. DNS, TLS handshake) that isn't a
/// `SocketException`. Rare; bucket-all for retryable network errors.
class BookingDetailNetworkFailure extends BookingDetailFailure {
  const BookingDetailNetworkFailure();
}

/// 5xx — server-side problem; user should retry shortly.
class BookingDetailServerFailure extends BookingDetailFailure {
  const BookingDetailServerFailure();
}

/// Anything else — wrapped error string for diagnostic display.
class UnknownBookingDetailFailure extends BookingDetailFailure {
  final String message;
  const UnknownBookingDetailFailure(this.message);
}

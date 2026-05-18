/// Sealed failure hierarchy for the review feature.
///
/// Maps 1:1 to the backend error envelope codes from `REVIEWS_API.md`.
/// The data-layer repository converts `HttpFailure` instances into one
/// of these typed failures; the presentation layer pattern-matches on
/// the type to choose a snackbar message + a CTA (retry / refresh /
/// dismiss). Raw HTTP codes never reach the UI.
sealed class ReviewFailure implements Exception {
  const ReviewFailure();
}

/// 409 `review_already_submitted` — the customer already left a review
/// for this booking. The UI should refresh the snapshot (which will now
/// return the existing review) and flip to the recap body.
class ReviewAlreadySubmitted extends ReviewFailure {
  const ReviewAlreadySubmitted();
}

/// 400 `review_not_eligible` — booking is not in a terminal-success
/// status. Customer hit submit before the tech marked the job complete
/// (race) or some other ineligible transition happened. The envelope's
/// `booking_status` field tells the UI which state the booking is now
/// in, so we surface it for diagnostic display.
class ReviewNotEligible extends ReviewFailure {
  final String? currentBookingStatus;
  const ReviewNotEligible({this.currentBookingStatus});
}

/// 404 `booking_not_found` — the booking id doesn't exist OR is owned
/// by a different customer. Indistinguishable on the wire (by design)
/// and indistinguishable here. Should not occur via normal in-app
/// navigation; surfaces only on forged deep-links / stale notification
/// taps after a booking was deleted.
class ReviewBookingNotFound extends ReviewFailure {
  const ReviewBookingNotFound();
}

/// 400 `validation_error` — usually means an unknown tag key or
/// rating out of range. Carries the field map so the UI can highlight
/// the specific offending chip (vs blanket-erroring the whole form).
class ReviewValidationFailure extends ReviewFailure {
  final Map<String, dynamic> fieldErrors;
  const ReviewValidationFailure({this.fieldErrors = const {}});
}

/// 401 — token expired or missing. The repository converts these into
/// this typed failure; the auth layer's interceptor handles the actual
/// logout cascade, this just keeps the call-site code clean.
class ReviewUnauthorized extends ReviewFailure {
  const ReviewUnauthorized();
}

/// `SocketException` or other transport-level failure. UI offers retry.
class ReviewNetworkFailure extends ReviewFailure {
  const ReviewNetworkFailure();
}

/// 5xx — server-side problem. UI offers retry, surfaces a "try again
/// shortly" message.
class ReviewServerFailure extends ReviewFailure {
  const ReviewServerFailure();
}

/// Anything else — wrapped error string for diagnostic display.
class UnknownReviewFailure extends ReviewFailure {
  final String message;
  const UnknownReviewFailure(this.message);
}

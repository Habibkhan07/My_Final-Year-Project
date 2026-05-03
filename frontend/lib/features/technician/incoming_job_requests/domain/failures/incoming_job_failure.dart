/// Sealed failure hierarchy for the incoming job requests feature.
///
/// Two distinct failure axes:
///   * **Parse-side**: the WS event arrived but the payload couldn't be
///     mapped to a [JobNewRequest]. Surfaced via [MalformedJobPayload];
///     the queue notifier drops the event without throwing into the
///     dispatcher.
///   * **Action-side**: the technician tapped Accept/Decline and the
///     remote call failed. Modeled as four concrete subtypes — the
///     repository's `_mapFailure` switch keys on the standard error
///     envelope's `code` to choose between them, and the host's
///     `_surfaceResult` switch maps each to a distinct UI affordance
///     (snackbar copy + Retry presence + remove-from-queue decision).
sealed class IncomingJobFailure implements Exception {
  final String message;
  const IncomingJobFailure(this.message);
}

/// The `job_new_request` payload was missing a required field or had a
/// non-parseable type. The mapper logs the underlying reason and returns
/// null upstream; the queue notifier skips silently. This failure exists for
/// completeness and for the test contract that asserts the malformed-payload
/// path doesn't throw into the dispatcher.
class MalformedJobPayload extends IncomingJobFailure {
  const MalformedJobPayload(
      [super.message = 'Incoming job request payload was malformed.']);
}

/// Thrown when accept/decline arrives after the booking has already left
/// the `AWAITING` state on the server.
///
/// **When this is reached.**
/// - SLA Celery task fired server-side and flipped the booking to `REJECTED`
///   between the dispatch and the technician's swipe.
/// - Customer cancelled the booking before the technician's tap landed.
/// - The booking is no longer assigned to this technician (404 collapse —
///   the backend deliberately returns 404 for both "missing" and
///   "wrong-owner" to avoid an enumeration leak).
///
/// **Wire contract.**
/// - HTTP `409 booking_no_longer_available` — server explicitly observed
///   the booking in a non-AWAITING state. [currentStatus] echoes the live
///   status (`REJECTED` / `CANCELLED` / `CONFIRMED` / etc.) so the UI can
///   tailor copy if it ever needs to (the current implementation collapses
///   them all under one snackbar).
/// - HTTP `404 not_found` — booking missing OR not assigned to this
///   technician. Treated identically: the offer is gone, remove it.
///   [currentStatus] is null on this path because the server doesn't
///   disclose the row state (it might not exist).
///
/// **UI contract.** The host removes the offer from the queue and surfaces
/// a "This job is no longer available" snackbar with no retry button —
/// retrying would land on the same 409/404.
class OfferNoLongerAvailable extends IncomingJobFailure {
  /// Server-reported live row status when known (echoed from the 409 envelope's
  /// `errors.current_status`). Null on the 404 path because the server cannot
  /// distinguish missing-row from wrong-owner without leaking enumeration.
  final String? currentStatus;

  // Positional super-init because the parent's constructor takes message as
  // a positional parameter. Keeping `currentStatus` named (the convention
  // for optional metadata) means we can't use the `super.message` shorthand,
  // so the explicit `: super(message)` forward stays.
  const OfferNoLongerAvailable({
    this.currentStatus,
    String message = 'This job is no longer available.',
  }) : super(message);
}

/// Device is offline / a `SocketException` was thrown by the HTTP client.
///
/// **UI contract.** The offer stays in the queue; the snackbar carries a
/// Retry action that re-invokes the same operation. The local SLA expiry
/// callback is gated on the in-flight set so the offer card does not pop
/// out from under the user while their request is still hanging.
class IncomingJobNetworkFailure extends IncomingJobFailure {
  const IncomingJobNetworkFailure(
      [super.message = 'Network unavailable. Check your connection and try again.']);
}

/// HTTP 5xx — the server hit an internal error.
///
/// **UI contract.** Same as [IncomingJobNetworkFailure] (offer stays,
/// retry surfaced) but the snackbar copy hints at server-side trouble so
/// the technician understands their device isn't the problem.
class IncomingJobServerFailure extends IncomingJobFailure {
  const IncomingJobServerFailure(
      [super.message = 'Server error. Please try again in a moment.']);
}

/// Catch-all for any other unexpected error path the repository hasn't
/// classified (parsing failure, type cast, an HTTP code we didn't enumerate).
///
/// **UI contract.** Same as the network failure — keep the offer, allow
/// retry. The neutral default message intentionally avoids saying "accept"
/// or "decline" so the same type can carry both action contexts; the host
/// is free to construct a more specific instance if needed.
///
/// Sibling type to [OfferNoLongerAvailable]: that one means "give up on
/// this offer," this one means "try again." Distinguishing them is the
/// reason this hierarchy exists at all.
class UnknownIncomingJobFailure extends IncomingJobFailure {
  const UnknownIncomingJobFailure(
      [super.message = 'Something went wrong. Please try again.']);
}

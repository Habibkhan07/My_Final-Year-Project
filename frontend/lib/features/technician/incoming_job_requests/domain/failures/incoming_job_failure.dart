/// Sealed failure hierarchy for the incoming job requests feature.
///
/// Sparse this sprint — accept / decline endpoints don't exist yet
/// (`backend/bookings/api/BOOKINGS_API.md` §1.1: "The accept endpoint itself
/// is a separate sprint"). The parse-side failure is modeled today; the
/// scaffold for the late-accept failure ([OfferNoLongerAvailable]) is in
/// place ahead of the repository so the moment the accept endpoint lands
/// the repo's `_mapFailures` switch already has the receiver and the host
/// already has the UI mapping.
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

/// Thrown when the technician's accept arrives after the booking has
/// already left the `AWAITING` state — typically because the SLA Celery
/// task fired server-side and flipped the booking to `REJECTED` between
/// the dispatch and the technician's swipe.
///
/// **When this is reached.**
/// - Stale tray notification tapped after the SLA window. Flag #19's
///   mapper-side filter ([JobNewRequestMapper.fromSystemEvent]) closes the
///   common case at ingest, but a notification tapped just inside the
///   window can still race the server's timeout — the swipe runway has a
///   visual margin (the drain stops being swipeable when `maxThumbOffset`
///   clamps to 0), but a fast tap-just-past-zero can still produce a
///   late accept on the wire.
/// - Booking cancelled by the customer between dispatch and accept (rare
///   but legal under the current state machine — see flag #1).
///
/// **Wire contract.** This failure maps from the backend's
/// `code: "booking_no_longer_available"` error envelope (flag #20).
/// Until the backend ships that specific code, the repository's
/// `_mapFailures` switch falls through to a generic
/// `validation_error` → [UnknownIncomingJobFailure] path, which the UI
/// surfaces with a less specific copy. Once the backend code lands, the
/// repo flips one switch case and the technician sees "This job is no
/// longer available" instead of a generic "Couldn't accept" Snackbar.
///
/// **Why the scaffold lives here today.** Placing the type ahead of the
/// repository means (a) the test pinning the sealed hierarchy already
/// covers the new branch, (b) widget-side switch expressions over the
/// sealed parent can be exhaustive ahead of the repo landing, and (c) the
/// repo's PR is a one-line switch addition rather than a
/// type-plus-switch-plus-tests change.
class OfferNoLongerAvailable extends IncomingJobFailure {
  const OfferNoLongerAvailable(
      [super.message = 'This job is no longer available.']);
}

/// Catch-all for HTTP 5xx, network drops, or any other unexpected error
/// path the repository hasn't classified. Surface with a retry-friendly
/// Snackbar — the offer stays in the queue so the technician can swipe
/// again once whatever broke recovers.
///
/// Sibling type to [OfferNoLongerAvailable]: that one means "give up on
/// this offer," this one means "try again." Distinguishing them is the
/// reason this hierarchy exists at all.
class UnknownIncomingJobFailure extends IncomingJobFailure {
  const UnknownIncomingJobFailure(
      [super.message = 'Couldn’t accept the offer. Try again.']);
}

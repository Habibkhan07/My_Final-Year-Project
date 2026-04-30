/// Sealed failure hierarchy for the incoming job requests feature.
///
/// Sparse this sprint — accept / decline endpoints don't exist yet
/// (`backend/bookings/api/BOOKINGS_API.md` §1.1: "The accept endpoint itself
/// is a separate sprint"). Only the parse-side failure is modeled. Network /
/// validation / server failures will land alongside the repository when the
/// accept flow ships.
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
      [String message = 'Incoming job request payload was malformed.'])
      : super(message);
}

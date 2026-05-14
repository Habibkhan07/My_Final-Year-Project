import '../../domain/failures/incoming_job_failure.dart';

/// Outcome of a single accept/decline tap, returned from the queue
/// notifier's [accept]/[decline] methods to the calling widget.
///
/// Modeling the outcome as a sealed type (instead of throwing into the
/// widget) means:
///   * the host can respond differentially with a single exhaustive
///     `switch` expression in `_surfaceResult` — no bare `try/catch`
///     scattered through callbacks;
///   * the in-flight book-keeping inside the notifier remains a
///     local concern (the notifier already knows whether to clear the
///     entry from the in-flight set on success vs. failure);
///   * an outer call site that ignores the result is still safe — no
///     uncaught exception escapes the notifier method.
sealed class JobActionResult {
  const JobActionResult();
}

/// Server transitioned the booking to the action's terminal state
/// (CONFIRMED for accept, REJECTED for decline) — or it was already there
/// from a same-tech idempotent retry. Either way, the offer is now
/// removed from the local queue.
class JobActionSuccess extends JobActionResult {
  const JobActionSuccess();
}

/// Server reported the booking is no longer in AWAITING (SLA fired,
/// customer cancelled, already accepted/declined, or 404 IDOR collapse).
/// The offer is removed from the local queue; the host shows a "no longer
/// available" snackbar with no Retry action — retrying would land on the
/// same 409/404.
class JobActionConflict extends JobActionResult {
  final OfferNoLongerAvailable failure;
  const JobActionConflict(this.failure);
}

/// Device is offline. The offer stays in the queue; the host surfaces a
/// snackbar with a Retry action that re-invokes the same operation.
class JobActionNetworkFailure extends JobActionResult {
  final IncomingJobNetworkFailure failure;
  const JobActionNetworkFailure(this.failure);
}

/// 5xx response or any unclassified failure — the offer stays in the queue
/// and the host surfaces a retry-friendly snackbar. Holds the typed
/// failure so the host can switch on the exact subtype if it ever wants
/// to differentiate copy.
class JobActionUnexpectedFailure extends JobActionResult {
  final IncomingJobFailure failure;
  const JobActionUnexpectedFailure(this.failure);
}

/// The notifier's defensive guard — a second tap landed while the first
/// request was still in flight. Returned without dispatching a second
/// HTTP call. The host treats this as a no-op (the user's intent is
/// already in motion).
class JobActionAlreadyInFlight extends JobActionResult {
  const JobActionAlreadyInFlight();
}

/// Server returned 403 `wallet_lockout` — the tech tapped Accept with a
/// negative wallet balance. The offer STAYS in the queue (the tech may
/// top up and re-attempt within the SLA window); the host shows a
/// snackbar with a "Top up" action routing to the wallet screen instead
/// of a generic Retry button — retrying without topping up first would
/// land on the same 403.
class JobActionBlockedByLockout extends JobActionResult {
  final JobAcceptBlockedByLockout failure;
  const JobActionBlockedByLockout(this.failure);
}

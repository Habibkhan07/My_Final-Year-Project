/// Contract for technician-side actions on a dispatched job offer.
///
/// Implementations talk to the backend's
/// `POST /api/bookings/<id>/{accept,decline}/` endpoints — see
/// `backend/bookings/api/BOOKINGS_API.md` §1.3 / §1.4.
///
/// **Idempotency.** The backend treats a same-tech retry on the terminal
/// status as success: a second accept on a CONFIRMED booking returns 200
/// without re-emitting the customer event. Repository implementations
/// should therefore treat a successful return as "the booking is in the
/// terminal state for this action," not as "we just transitioned it."
///
/// **Error pipeline contract.** Per CLAUDE.md, every failure surfaces as
/// a typed [IncomingJobFailure] — the implementation maps the standard
/// HTTP error envelope to the appropriate sealed subtype:
///
///   * `409 booking_no_longer_available` → [OfferNoLongerAvailable]
///   * `404 not_found`                   → [OfferNoLongerAvailable]
///       (404 is the IDOR-safe collapse; the offer is gone either way)
///   * `5xx` of any code                 → [IncomingJobServerFailure]
///   * `SocketException`                 → [IncomingJobNetworkFailure]
///   * anything else                     → [UnknownIncomingJobFailure]
abstract class IIncomingJobRepository {
  /// Accept the offer with id [jobId].
  ///
  /// Throws [OfferNoLongerAvailable] when the booking has left AWAITING
  /// (SLA fired, customer cancelled, already accepted/declined, or no
  /// longer assigned to this technician).
  /// Throws [IncomingJobNetworkFailure] when the device is offline.
  /// Throws [IncomingJobServerFailure] on HTTP 5xx.
  /// Throws [UnknownIncomingJobFailure] for any other unexpected error.
  Future<void> acceptJobRequest(int jobId);

  /// Decline the offer with id [jobId]. Same failure contract as
  /// [acceptJobRequest]; the UI may differentiate the snackbar copy but
  /// the typed exception set is identical.
  Future<void> declineJobRequest(int jobId);
}

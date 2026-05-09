import '../entities/booking_detail.dart';

/// Repository contract for the orchestrator screen's hydration source.
///
/// Throws (in priority order):
///   * [BookingDetailNotFound] — 404, the booking id is unknown.
///   * [BookingDetailNotParticipant] — 403 `not_a_participant`.
///   * [BookingDetailOfflineNoCache] — `SocketException` + no cached row.
///   * [BookingDetailNetworkFailure] — other transport errors.
///   * [BookingDetailServerFailure] — 5xx responses.
///   * [UnknownBookingDetailFailure] — anything else, with a diagnostic
///     message.
///
/// On `SocketException` with a usable cache row, returns the cached
/// entity silently — the offline-first contract for crash recovery and
/// flaky-network UX.
abstract interface class IBookingDetailRepository {
  Future<BookingDetail> getBookingDetail(int bookingId);
}

import '../entities/review.dart';

/// Abstract contract for fetching + submitting a booking's review.
///
/// Throws subclasses of `ReviewFailure` on errors — never `HttpFailure`,
/// never `SocketException`. Implementations live in the data layer and
/// are responsible for translating wire-level exceptions into the
/// sealed typed failures the presentation layer consumes.
abstract interface class IReviewRepository {
  /// `GET /api/bookings/<bookingId>/review/`.
  ///
  /// Returns the existing review snapshot (which may have a `null`
  /// `review` field if not yet submitted) plus the predefined tag
  /// vocabulary.
  ///
  /// Throws:
  /// - [ReviewBookingNotFound] for 404.
  /// - [ReviewUnauthorized] for 401.
  /// - [ReviewNetworkFailure] for transport errors.
  /// - [ReviewServerFailure] for 5xx.
  /// - [UnknownReviewFailure] for anything else.
  Future<BookingReviewSnapshot> getSnapshot(int bookingId);

  /// `POST /api/bookings/<bookingId>/review/`.
  ///
  /// Returns the freshly-created [Review] on success. The caller is
  /// expected to invalidate the snapshot provider so the UI flips to
  /// the recap body.
  ///
  /// Throws:
  /// - [ReviewAlreadySubmitted] for 409.
  /// - [ReviewNotEligible] for 400 + `review_not_eligible`.
  /// - [ReviewValidationFailure] for 400 + `validation_error`.
  /// - [ReviewBookingNotFound] for 404.
  /// - [ReviewUnauthorized] for 401.
  /// - [ReviewNetworkFailure] for transport errors.
  /// - [ReviewServerFailure] for 5xx.
  /// - [UnknownReviewFailure] for anything else.
  Future<Review> submit({
    required int bookingId,
    required int rating,
    required List<String> tagKeys,
    required String text,
  });
}

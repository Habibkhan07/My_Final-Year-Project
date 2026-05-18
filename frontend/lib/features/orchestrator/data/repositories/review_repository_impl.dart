import 'dart:io' show SocketException;

import '../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/review.dart';
import '../../domain/failures/review_failure.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';
import '../mappers/review_mapper.dart';

/// Concrete repository — owns the wire-failure → typed-failure mapping
/// for the review feature.
///
/// No local caching. Reviews are infrequent, single-shot writes; an
/// offline-first cache layer adds complexity without proportional UX
/// payoff. If the network is down, the user gets a typed
/// [ReviewNetworkFailure] and can retry — the same as Uber's rating
/// flow.
///
/// The full error-mapping switch lives in [_mapHttpFailure] so a new
/// backend error code is a one-line addition here, never a touch on
/// the UI layer.
class ReviewRepositoryImpl implements IReviewRepository {
  final IReviewRemoteDataSource _remote;

  ReviewRepositoryImpl({required IReviewRemoteDataSource remote})
    : _remote = remote;

  @override
  Future<BookingReviewSnapshot> getSnapshot(int bookingId) async {
    try {
      final model = await _remote.fetchSnapshot(bookingId);
      return ReviewMapper.snapshotToDomain(model);
    } on SocketException {
      throw const ReviewNetworkFailure();
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on ReviewFailure {
      rethrow;
    } catch (e) {
      throw UnknownReviewFailure(e.toString());
    }
  }

  @override
  Future<Review> submit({
    required int bookingId,
    required int rating,
    required List<String> tagKeys,
    required String text,
  }) async {
    try {
      final model = await _remote.submitReview(
        bookingId: bookingId,
        rating: rating,
        tagKeys: tagKeys,
        text: text,
      );
      return ReviewMapper.toDomain(model);
    } on SocketException {
      throw const ReviewNetworkFailure();
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on ReviewFailure {
      rethrow;
    } catch (e) {
      throw UnknownReviewFailure(e.toString());
    }
  }

  /// Code-first matching: branch on the backend's typed error code
  /// (`review_already_submitted`, `review_not_eligible`, …) before
  /// falling back to status-code matching. Reasons:
  ///
  /// * The backend's error envelope makes `code` the stable contract;
  ///   `statusCode` is a coincidence of HTTP semantics that could
  ///   change if a future endpoint chooses a different status for the
  ///   same logical error.
  /// * `validation_error` arrives as 400 and is shape-rich (field
  ///   map). We need the field map for [ReviewValidationFailure] —
  ///   matching by status alone would lose it.
  ReviewFailure _mapHttpFailure(HttpFailure e) {
    switch (e.code) {
      case 'review_already_submitted':
        return const ReviewAlreadySubmitted();
      case 'review_not_eligible':
        // The errors map is `{"booking_status": ["CONFIRMED"]}` — pull
        // the first element so the UI can render "Wait until the
        // technician marks the job complete" vs a generic message.
        final raw = e.errors['booking_status'];
        String? status;
        if (raw is List && raw.isNotEmpty) {
          status = raw.first?.toString();
        } else if (raw is String) {
          status = raw;
        }
        return ReviewNotEligible(currentBookingStatus: status);
      case 'booking_not_found':
        return const ReviewBookingNotFound();
      case 'validation_error':
        return ReviewValidationFailure(fieldErrors: e.errors);
    }
    // Code didn't match — fall back to status code.
    if (e.statusCode == 401) return const ReviewUnauthorized();
    if (e.statusCode == 404) return const ReviewBookingNotFound();
    if (e.statusCode >= 500) return const ReviewServerFailure();
    return UnknownReviewFailure(e.message);
  }
}

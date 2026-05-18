import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';

/// Customer-submitted review of a technician, post-booking-completion.
///
/// Maps to `technicians.models.Review` on the backend. The fields here
/// mirror the wire contract from `GET /api/bookings/<id>/review/` (the
/// `review` sub-object) and `POST /api/bookings/<id>/review/` (response
/// shape after a 201).
///
/// `reviewerName` is composed server-side as "First L." — never the
/// full last name (privacy + protects against tech-side targeted
/// follow-up). The frontend renders it verbatim.
@freezed
abstract class Review with _$Review {
  const factory Review({
    required int id,
    required int rating, // 1-5 inclusive
    required List<String> tags,
    required String text,
    required DateTime createdAt,
    required String reviewerName,
  }) = _Review;
}

/// One predefined tag chip — `{key, label}` per the backend's
/// `technicians.constants.review_tags.PredefinedTag` TypedDict.
///
/// The `key` is the stable identifier persisted in `Review.tags`.
/// The `label` is the user-facing copy and may change between
/// releases without a data migration. The frontend only ever sends
/// the key back to the server on submit.
@freezed
abstract class PredefinedTag with _$PredefinedTag {
  const factory PredefinedTag({
    required String key,
    required String label,
  }) = _PredefinedTag;
}

/// Server-returned tag vocabulary, bucketed by polarity. The UI
/// renders the `positive` bucket when the user's selected rating is
/// ≥ 4, and the `constructive` bucket when it's ≤ 3. Both buckets are
/// always returned by the GET endpoint so the UI can swap chip sets
/// client-side without a second round-trip.
@freezed
abstract class PredefinedTagBuckets with _$PredefinedTagBuckets {
  const factory PredefinedTagBuckets({
    required List<PredefinedTag> positive,
    required List<PredefinedTag> constructive,
  }) = _PredefinedTagBuckets;
}

/// Wrapped GET response — either the existing review (if the customer
/// has already submitted) or `null` plus the predefined-tag dictionary
/// to render the form against.
///
/// The presence/absence of [review] is the single source of truth for
/// the UI's form-vs-recap switch — never derived from booking status,
/// always read from this entity.
@freezed
abstract class BookingReviewSnapshot with _$BookingReviewSnapshot {
  const factory BookingReviewSnapshot({
    required Review? review,
    required PredefinedTagBuckets predefinedTags,
  }) = _BookingReviewSnapshot;
}

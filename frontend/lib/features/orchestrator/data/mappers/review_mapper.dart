import '../../domain/entities/review.dart';
import '../models/review_model.dart';

/// Pure-function transformations from wire models to domain entities.
///
/// Why a separate mapper class instead of `model.toEntity()` methods:
/// the data layer's models are the wire contract (subject to backend
/// schema drift), while the domain entities are the stable in-app
/// shape. Keeping the conversion in a dedicated function pins the
/// drift surface to one file — schema changes only break this mapper,
/// never the widgets.
///
/// Defensive postures:
/// - `DateTime.parse` on `created_at` — the server-side serializer
///   emits ISO-8601 UTC. A malformed string would throw `FormatException`
///   here; we let it propagate to the repository's catch-all which
///   wraps it as [UnknownReviewFailure]. Better a typed failure than
///   a silently null DateTime.
/// - `List.unmodifiable` on `tags` — the domain entity is immutable;
///   the model's list is from `jsonDecode` and would otherwise be
///   mutable.
class ReviewMapper {
  const ReviewMapper._();

  static Review toDomain(ReviewModel model) {
    return Review(
      id: model.id,
      rating: model.rating,
      tags: List.unmodifiable(model.tags),
      text: model.text,
      createdAt: DateTime.parse(model.createdAt).toUtc(),
      reviewerName: model.reviewerName,
    );
  }

  static PredefinedTag _tagToDomain(PredefinedTagModel m) =>
      PredefinedTag(key: m.key, label: m.label);

  static PredefinedTagBuckets bucketsToDomain(PredefinedTagBucketsModel m) {
    return PredefinedTagBuckets(
      positive: List.unmodifiable(m.positive.map(_tagToDomain)),
      constructive: List.unmodifiable(m.constructive.map(_tagToDomain)),
    );
  }

  static BookingReviewSnapshot snapshotToDomain(BookingReviewSnapshotModel m) {
    return BookingReviewSnapshot(
      review: m.review == null ? null : toDomain(m.review!),
      predefinedTags: bucketsToDomain(m.predefinedTags),
    );
  }
}

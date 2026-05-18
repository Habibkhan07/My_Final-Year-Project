import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_model.freezed.dart';
part 'review_model.g.dart';

/// Wire model for `Review` rows returned by
/// `GET /api/bookings/<id>/review/` (inside the `review` sub-object)
/// and `POST /api/bookings/<id>/review/` (as the body of the 201).
///
/// Field names follow the backend's JSON shape verbatim — `created_at`
/// not `createdAt`, etc. The mapper converts to the domain
/// [Review] entity which uses Dart-idiomatic camelCase + typed
/// `DateTime`.
@freezed
abstract class ReviewModel with _$ReviewModel {
  const factory ReviewModel({
    required int id,
    required int rating,
    @Default(<String>[]) List<String> tags,
    @Default('') String text,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'reviewer_name') required String reviewerName,
  }) = _ReviewModel;

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);
}

/// Wire model for a single predefined tag — `{key, label}` per
/// `_PredefinedTagSerializer` on the backend.
@freezed
abstract class PredefinedTagModel with _$PredefinedTagModel {
  const factory PredefinedTagModel({
    required String key,
    required String label,
  }) = _PredefinedTagModel;

  factory PredefinedTagModel.fromJson(Map<String, dynamic> json) =>
      _$PredefinedTagModelFromJson(json);
}

/// Wire model for the `predefined_tags` sub-object on the GET response.
@freezed
abstract class PredefinedTagBucketsModel with _$PredefinedTagBucketsModel {
  const factory PredefinedTagBucketsModel({
    @Default(<PredefinedTagModel>[]) List<PredefinedTagModel> positive,
    @Default(<PredefinedTagModel>[]) List<PredefinedTagModel> constructive,
  }) = _PredefinedTagBucketsModel;

  factory PredefinedTagBucketsModel.fromJson(Map<String, dynamic> json) =>
      _$PredefinedTagBucketsModelFromJson(json);
}

/// Wire model for the full `GET /api/bookings/<id>/review/` response.
@freezed
abstract class BookingReviewSnapshotModel with _$BookingReviewSnapshotModel {
  const factory BookingReviewSnapshotModel({
    ReviewModel? review,
    @JsonKey(name: 'predefined_tags')
    required PredefinedTagBucketsModel predefinedTags,
  }) = _BookingReviewSnapshotModel;

  factory BookingReviewSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$BookingReviewSnapshotModelFromJson(json);
}

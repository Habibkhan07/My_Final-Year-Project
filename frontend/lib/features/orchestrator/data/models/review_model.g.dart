// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => _ReviewModel(
  id: (json['id'] as num).toInt(),
  rating: (json['rating'] as num).toInt(),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  text: json['text'] as String? ?? '',
  createdAt: json['created_at'] as String,
  reviewerName: json['reviewer_name'] as String,
);

Map<String, dynamic> _$ReviewModelToJson(_ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rating': instance.rating,
      'tags': instance.tags,
      'text': instance.text,
      'created_at': instance.createdAt,
      'reviewer_name': instance.reviewerName,
    };

_PredefinedTagModel _$PredefinedTagModelFromJson(Map<String, dynamic> json) =>
    _PredefinedTagModel(
      key: json['key'] as String,
      label: json['label'] as String,
    );

Map<String, dynamic> _$PredefinedTagModelToJson(_PredefinedTagModel instance) =>
    <String, dynamic>{'key': instance.key, 'label': instance.label};

_PredefinedTagBucketsModel _$PredefinedTagBucketsModelFromJson(
  Map<String, dynamic> json,
) => _PredefinedTagBucketsModel(
  positive:
      (json['positive'] as List<dynamic>?)
          ?.map((e) => PredefinedTagModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PredefinedTagModel>[],
  constructive:
      (json['constructive'] as List<dynamic>?)
          ?.map((e) => PredefinedTagModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PredefinedTagModel>[],
);

Map<String, dynamic> _$PredefinedTagBucketsModelToJson(
  _PredefinedTagBucketsModel instance,
) => <String, dynamic>{
  'positive': instance.positive,
  'constructive': instance.constructive,
};

_BookingReviewSnapshotModel _$BookingReviewSnapshotModelFromJson(
  Map<String, dynamic> json,
) => _BookingReviewSnapshotModel(
  review: json['review'] == null
      ? null
      : ReviewModel.fromJson(json['review'] as Map<String, dynamic>),
  predefinedTags: PredefinedTagBucketsModel.fromJson(
    json['predefined_tags'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$BookingReviewSnapshotModelToJson(
  _BookingReviewSnapshotModel instance,
) => <String, dynamic>{
  'review': instance.review,
  'predefined_tags': instance.predefinedTags,
};

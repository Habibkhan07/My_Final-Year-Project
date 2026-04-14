// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TechnicianModel _$TechnicianModelFromJson(Map<String, dynamic> json) =>
    _TechnicianModel(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String,
      primaryCategory: json['primary_category'] as String,
      city: json['city'] as String,
      profilePicture: json['profile_picture'] as String?,
      ratingAverage: (json['rating_average'] as num).toDouble(),
      reviewCount: (json['review_count'] as num).toInt(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      bayesianScore: (json['bayesian_score'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool,
      uiRatingText: json['ui_rating_text'] as String,
      primaryPrice: json['primary_price'] as String,
      priceContext: json['price_context'] as String,
      promoTag: json['promo_tag'] as String?,
      uiSubtitleText: json['ui_subtitle_text'] as String?,
    );

Map<String, dynamic> _$TechnicianModelToJson(_TechnicianModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'primary_category': instance.primaryCategory,
      'city': instance.city,
      'profile_picture': instance.profilePicture,
      'rating_average': instance.ratingAverage,
      'review_count': instance.reviewCount,
      'distance_km': instance.distanceKm,
      'bayesian_score': instance.bayesianScore,
      'is_active': instance.isActive,
      'ui_rating_text': instance.uiRatingText,
      'primary_price': instance.primaryPrice,
      'price_context': instance.priceContext,
      'promo_tag': instance.promoTag,
      'ui_subtitle_text': instance.uiSubtitleText,
    };

_DiscoveryResultModel _$DiscoveryResultModelFromJson(
  Map<String, dynamic> json,
) => _DiscoveryResultModel(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  uiPromoBannerText: json['ui_promo_banner_text'] as String?,
  resolvedServiceId: (json['resolved_service_id'] as num?)?.toInt(),
  resolvedSubServiceId: (json['resolved_sub_service_id'] as num?)?.toInt(),
  results: (json['results'] as List<dynamic>)
      .map((e) => TechnicianModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DiscoveryResultModelToJson(
  _DiscoveryResultModel instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'ui_promo_banner_text': instance.uiPromoBannerText,
  'resolved_service_id': instance.resolvedServiceId,
  'resolved_sub_service_id': instance.resolvedSubServiceId,
  'results': instance.results,
};

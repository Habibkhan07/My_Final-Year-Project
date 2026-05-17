// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TechnicianSkillModel _$TechnicianSkillModelFromJson(
  Map<String, dynamic> json,
) => _TechnicianSkillModel(
  name: json['name'] as String,
  iconName: json['icon_name'] as String?,
  serviceId: (json['service_id'] as num).toInt(),
  subServiceId: (json['sub_service_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$TechnicianSkillModelToJson(
  _TechnicianSkillModel instance,
) => <String, dynamic>{
  'name': instance.name,
  'icon_name': instance.iconName,
  'service_id': instance.serviceId,
  'sub_service_id': instance.subServiceId,
};

_TechnicianReviewModel _$TechnicianReviewModelFromJson(
  Map<String, dynamic> json,
) => _TechnicianReviewModel(
  reviewerName: json['reviewer_name'] as String,
  rating: (json['rating'] as num).toInt(),
  text: json['text'] as String,
);

Map<String, dynamic> _$TechnicianReviewModelToJson(
  _TechnicianReviewModel instance,
) => <String, dynamic>{
  'reviewer_name': instance.reviewerName,
  'rating': instance.rating,
  'text': instance.text,
};

_TechnicianProfileModel _$TechnicianProfileModelFromJson(
  Map<String, dynamic> json,
) => _TechnicianProfileModel(
  id: (json['id'] as num).toInt(),
  fullName: json['full_name'] as String,
  city: json['city'] as String,
  profilePicture: json['profile_picture'] as String?,
  ratingAverage: (json['rating_average'] as num).toDouble(),
  reviewCount: (json['review_count'] as num).toInt(),
  distanceKm: (json['distance_km'] as num?)?.toDouble(),
  bayesianScore: (json['bayesian_score'] as num?)?.toDouble(),
  isActive: json['is_active'] as bool,
  uiRatingText: json['ui_rating_text'] as String,
  primaryPrice: json['primary_price'] as String,
  primaryPriceRaw: json['primary_price_raw'] as String,
  priceContext: json['price_context'] as String,
  promoTag: json['promo_tag'] as String?,
  skills: (json['skills'] as List<dynamic>)
      .map((e) => TechnicianSkillModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  recentReviews: (json['recent_reviews'] as List<dynamic>)
      .map((e) => TechnicianReviewModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TechnicianProfileModelToJson(
  _TechnicianProfileModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.fullName,
  'city': instance.city,
  'profile_picture': instance.profilePicture,
  'rating_average': instance.ratingAverage,
  'review_count': instance.reviewCount,
  'distance_km': instance.distanceKm,
  'bayesian_score': instance.bayesianScore,
  'is_active': instance.isActive,
  'ui_rating_text': instance.uiRatingText,
  'primary_price': instance.primaryPrice,
  'primary_price_raw': instance.primaryPriceRaw,
  'price_context': instance.priceContext,
  'promo_tag': instance.promoTag,
  'skills': instance.skills,
  'recent_reviews': instance.recentReviews,
};

_AvailabilitySlotModel _$AvailabilitySlotModelFromJson(
  Map<String, dynamic> json,
) => _AvailabilitySlotModel(
  timeString: json['time_string'] as String,
  isoStart: json['iso_start'] as String,
  isoEnd: json['iso_end'] as String,
  period: json['period'] as String,
);

Map<String, dynamic> _$AvailabilitySlotModelToJson(
  _AvailabilitySlotModel instance,
) => <String, dynamic>{
  'time_string': instance.timeString,
  'iso_start': instance.isoStart,
  'iso_end': instance.isoEnd,
  'period': instance.period,
};

_InstantBookingRequestModel _$InstantBookingRequestModelFromJson(
  Map<String, dynamic> json,
) => _InstantBookingRequestModel(
  technicianId: (json['technician_id'] as num).toInt(),
  addressId: (json['address_id'] as num).toInt(),
  serviceId: (json['service_id'] as num).toInt(),
  subServiceId: (json['sub_service_id'] as num?)?.toInt(),
  promotionId: (json['promotion_id'] as num?)?.toInt(),
  scheduledStart: json['scheduled_start'] as String,
  scheduledEnd: json['scheduled_end'] as String,
);

Map<String, dynamic> _$InstantBookingRequestModelToJson(
  _InstantBookingRequestModel instance,
) => <String, dynamic>{
  'technician_id': instance.technicianId,
  'address_id': instance.addressId,
  'service_id': instance.serviceId,
  'sub_service_id': ?instance.subServiceId,
  'promotion_id': ?instance.promotionId,
  'scheduled_start': instance.scheduledStart,
  'scheduled_end': instance.scheduledEnd,
};

_InstantBookingResponseModel _$InstantBookingResponseModelFromJson(
  Map<String, dynamic> json,
) => _InstantBookingResponseModel(
  bookingId: (json['booking_id'] as num).toInt(),
);

Map<String, dynamic> _$InstantBookingResponseModelToJson(
  _InstantBookingResponseModel instance,
) => <String, dynamic>{'booking_id': instance.bookingId};

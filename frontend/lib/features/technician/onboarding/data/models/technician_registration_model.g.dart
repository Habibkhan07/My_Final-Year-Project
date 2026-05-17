// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_registration_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TechnicianRegistrationModel _$TechnicianRegistrationModelFromJson(
  Map<String, dynamic> json,
) => _TechnicianRegistrationModel(
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  city: json['city'] as String,
  cnicNumber: json['cnic_number'] as String,
  profilePictureUuid: json['profile_picture_uuid'] as String,
  cnicPictureUuid: json['cnic_picture_uuid'] as String,
  categoryLicenses: (json['category_licenses'] as List<dynamic>)
      .map((e) => CategoryLicenseInputModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  skills: (json['skills'] as List<dynamic>)
      .map((e) => SkillInputModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  baseLatitude: (json['base_latitude'] as num?)?.toDouble(),
  baseLongitude: (json['base_longitude'] as num?)?.toDouble(),
  maxTravelRadiusKm: (json['max_travel_radius_km'] as num?)?.toInt(),
  workAddressLabel: json['work_address_label'] as String?,
);

Map<String, dynamic> _$TechnicianRegistrationModelToJson(
  _TechnicianRegistrationModel instance,
) => <String, dynamic>{
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'city': instance.city,
  'cnic_number': instance.cnicNumber,
  'profile_picture_uuid': instance.profilePictureUuid,
  'cnic_picture_uuid': instance.cnicPictureUuid,
  'category_licenses': instance.categoryLicenses,
  'skills': instance.skills,
  'base_latitude': instance.baseLatitude,
  'base_longitude': instance.baseLongitude,
  'max_travel_radius_km': instance.maxTravelRadiusKm,
  'work_address_label': instance.workAddressLabel,
};

_CategoryLicenseInputModel _$CategoryLicenseInputModelFromJson(
  Map<String, dynamic> json,
) => _CategoryLicenseInputModel(
  serviceId: (json['service_id'] as num).toInt(),
  mediaUuid: json['media_uuid'] as String,
);

Map<String, dynamic> _$CategoryLicenseInputModelToJson(
  _CategoryLicenseInputModel instance,
) => <String, dynamic>{
  'service_id': instance.serviceId,
  'media_uuid': instance.mediaUuid,
};

_SkillInputModel _$SkillInputModelFromJson(Map<String, dynamic> json) =>
    _SkillInputModel(subServiceId: (json['sub_service_id'] as num).toInt());

Map<String, dynamic> _$SkillInputModelToJson(_SkillInputModel instance) =>
    <String, dynamic>{'sub_service_id': instance.subServiceId};

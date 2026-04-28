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
  experienceYears: (json['experience_years'] as num).toInt(),
  bio: json['bio'] as String,
  profilePictureUuid: json['profile_picture_uuid'] as String,
  cnicPictureUuid: json['cnic_picture_uuid'] as String,
  categoryLicenses: (json['category_licenses'] as List<dynamic>)
      .map((e) => CategoryLicenseInputModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  skills: (json['skills'] as List<dynamic>)
      .map((e) => SkillInputModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TechnicianRegistrationModelToJson(
  _TechnicianRegistrationModel instance,
) => <String, dynamic>{
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'city': instance.city,
  'cnic_number': instance.cnicNumber,
  'experience_years': instance.experienceYears,
  'bio': instance.bio,
  'profile_picture_uuid': instance.profilePictureUuid,
  'cnic_picture_uuid': instance.cnicPictureUuid,
  'category_licenses': instance.categoryLicenses,
  'skills': instance.skills,
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
    _SkillInputModel(
      subServiceId: (json['sub_service_id'] as num).toInt(),
      yearsOfExperience: (json['years_of_experience'] as num).toInt(),
      laborRate: json['labor_rate'] as String?,
    );

Map<String, dynamic> _$SkillInputModelToJson(_SkillInputModel instance) =>
    <String, dynamic>{
      'sub_service_id': instance.subServiceId,
      'years_of_experience': instance.yearsOfExperience,
      'labor_rate': instance.laborRate,
    };

import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_registration_model.freezed.dart';
part 'technician_registration_model.g.dart';

/// [TechnicianRegistrationModel] is the final submission payload.
/// SENT TO: POST /api/technicians/onboarding/finalize/
@freezed
abstract class TechnicianRegistrationModel with _$TechnicianRegistrationModel {
  const factory TechnicianRegistrationModel({
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    required String city,
    @JsonKey(name: 'cnic_number') required String cnicNumber,
    @JsonKey(name: 'experience_years') required int experienceYears,
    required String bio,
    @JsonKey(name: 'profile_picture_uuid') required String profilePictureUuid,
    @JsonKey(name: 'cnic_picture_uuid') required String cnicPictureUuid,
    @JsonKey(name: 'category_licenses')
    required List<CategoryLicenseInputModel> categoryLicenses,
    required List<SkillInputModel> skills,
  }) = _TechnicianRegistrationModel;

  factory TechnicianRegistrationModel.fromJson(Map<String, dynamic> json) =>
      _$TechnicianRegistrationModelFromJson(json);
}

/// [CategoryLicenseInputModel] maps to CategoryLicenseInputSerializer in Django.
@freezed
abstract class CategoryLicenseInputModel with _$CategoryLicenseInputModel {
  const factory CategoryLicenseInputModel({
    @JsonKey(name: 'service_id') required int serviceId,
    @JsonKey(name: 'media_uuid') required String mediaUuid,
  }) = _CategoryLicenseInputModel;

  factory CategoryLicenseInputModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryLicenseInputModelFromJson(json);
}

/// [SkillInputModel] represents the technician's selected skills and labor rate.
@freezed
abstract class SkillInputModel with _$SkillInputModel {
  const factory SkillInputModel({
    @JsonKey(name: 'sub_service_id') required int subServiceId,
    @JsonKey(name: 'years_of_experience') required int yearsOfExperience,
    @JsonKey(name: 'labor_rate') String? laborRate,
  }) = _SkillInputModel;

  factory SkillInputModel.fromJson(Map<String, dynamic> json) =>
      _$SkillInputModelFromJson(json);
}

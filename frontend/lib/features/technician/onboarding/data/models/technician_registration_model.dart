// feature/technician/onboarding/data/models/technician_registration_model.dart

class TechnicianRegistrationModel {
  final String firstName;
  final String lastName;
  final String city;
  final String cnicNumber;
  final int experienceYears;
  final String bio;
  final String profilePictureUuid;
  final String cnicPictureUuid;
  final List<SkillInputModel> skills;

  TechnicianRegistrationModel({
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.cnicNumber,
    required this.experienceYears,
    required this.bio,
    required this.profilePictureUuid,
    required this.cnicPictureUuid,
    required this.skills,
  });

  // Converts the Dart Object into JSON for the API request
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName, //
      'last_name': lastName, //
      'city': city, //
      'cnic_number': cnicNumber, // Matches your Regex validation
      'experience_years': experienceYears,
      'bio': bio,
      'profile_picture_uuid': profilePictureUuid, // The UUID from Phase 1
      'cnic_picture_uuid': cnicPictureUuid, // The UUID from Phase 1
      'skills': skills.map((x) => x.toJson()).toList(), // Nested serialization
    };
  }
}

class SkillInputModel {
  final int subServiceId;
  final int yearsOfExperience;
  final String? licenseMediaUuid;

  SkillInputModel({
    required this.subServiceId,
    required this.yearsOfExperience,
    this.licenseMediaUuid,
  });

  Map<String, dynamic> toJson() {
    return {
      'sub_service_id': subServiceId, //
      'years_of_experience': yearsOfExperience, //
      'license_media_uuid': licenseMediaUuid, // Optional UUID
    };
  }
}

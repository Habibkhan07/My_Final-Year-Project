import 'package:flutter_test/flutter_test.dart';
// Import your model
import 'package:frontend/features/technician/onboarding/data/models/technician_registration_model.dart';

void main() {
  group('TechnicianRegistrationModel Serialization', () {
    test('SUCCESS: Should produce correct JSON structure for Django', () {
      // 1. Arrange: Create a model with all fields
      final model = TechnicianRegistrationModel(
        firstName: "Ahmed",
        lastName: "Khan",
        city: "Lahore",
        cnicNumber: "35202-1234567-1",
        experienceYears: 10,
        bio: "Expert electrician with 10 years experience.",
        profilePictureUuid: "uuid-profile-001",
        cnicPictureUuid: "uuid-cnic-002",
        skills: [
          SkillInputModel(
            subServiceId: 5,
            yearsOfExperience: 10,
            licenseMediaUuid: "uuid-license-999",
          ),
          SkillInputModel(
            subServiceId: 12,
            yearsOfExperience: 5,
            licenseMediaUuid: null, // Test optional license
          ),
        ],
      );

      // 2. Act: Convert to JSON
      final json = model.toJson();

      // 3. Assert: Verify every key matches serializers.py
      expect(json['first_name'], "Ahmed");
      expect(json['last_name'], "Khan");
      expect(json['city'], "Lahore");
      expect(json['cnic_number'], "35202-1234567-1");
      expect(json['experience_years'], 10);
      expect(json['bio'], contains("Expert electrician"));
      expect(json['profile_picture_uuid'], "uuid-profile-001");
      expect(json['cnic_picture_uuid'], "uuid-cnic-002");

      // Verify nested skills list
      expect(json['skills'], isA<List>());
      expect(json['skills'].length, 2);

      // Verify individual skill keys match SkillInputSerializer
      final firstSkill = json['skills'][0];
      expect(firstSkill['sub_service_id'], 5);
      expect(firstSkill['years_of_experience'], 10);
      expect(firstSkill['license_media_uuid'], "uuid-license-999");

      final secondSkill = json['skills'][1];
      expect(secondSkill['license_media_uuid'], isNull);
    });
  });

  group('SkillInputModel Edge Cases', () {
    test('Should handle null license_media_uuid in toJson', () {
      final skill = SkillInputModel(
        subServiceId: 1,
        yearsOfExperience: 2,
        licenseMediaUuid: null,
      );

      final json = skill.toJson();

      expect(json.containsKey('license_media_uuid'), true);
      expect(json['license_media_uuid'], isNull);
    });
  });
}

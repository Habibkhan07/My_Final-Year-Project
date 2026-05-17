import '../entities/technician_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../entities/skill_selection_entity.dart';
import 'package:image_picker/image_picker.dart'; // ADD THIS IMPORT
import '../entities/category_license_entity.dart';

abstract class TechnicianRepository {
  Future<List<ServiceEntity>> getOnboardingMetadata();

  // Uploads a file and returns a unique UUID from the server
  Future<String> uploadMedia(XFile file, String token);

  // Phase 2: submit the full registration form. Wizard fields after
  // the 2026-05-17 refactor — ``bio`` / ``experience_years`` are
  // gone; work-location is captured in-wizard now.
  Future<TechnicianEntity> finalizeRegistration({
    required String token,
    required String firstName,
    required String lastName,
    required String city,
    required String cnicNumber,
    required String profilePictureUuid,
    required String cnicPictureUuid,
    required List<SkillSelectionEntity> skills,
    required List<CategoryLicenseEntity> categoryLicenses,
    double? baseLatitude,
    double? baseLongitude,
    int? maxTravelRadiusKm,
    String? workAddressLabel,
  });
}

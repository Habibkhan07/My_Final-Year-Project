import 'dart:io';
import '../entities/technician_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../entities/skill_selection_entity.dart';

abstract class TechnicianRepository {
  Future<List<ServiceEntity>> getOnboardingMetadata();

  // Uploads a file and returns a unique UUID from the server
  Future<String> uploadMedia(File file, String token);

  // Sends the final registration data and returns the updated profile
  // Phase 2: Submit the full registration form
  Future<TechnicianEntity> finalizeRegistration({
    required String token,
    required String firstName,
    required String lastName,
    required String city,
    required String cnicNumber,
    required int experienceYears,
    required String bio,
    required String profilePictureUuid,
    required String cnicPictureUuid,
    required List<SkillSelectionEntity>
    skills, // Change from List<Map>    skills, // Changed from List<int> // Simplified for the Use Case
  });
}

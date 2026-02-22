/*import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/onboarding/data/data_sources/technician_onboarding_remote_datasource.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/upload_media_usecase.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/register_technician_usecase.dart';
import 'package:frontend/features/technician/onboarding/data/repositories/technician_onboarding_repository_impl.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/skill_selection_entity.dart';
// IMPORTANT: Import your new failures and core errors
import 'package:frontend/features/technician/onboarding/domain/failures/technician_failure.dart';
import 'package:frontend/core/common/errors/http_failure.dart';

void main() {
  // CONFIGURATION: Using your 4 verified tokens
  final List<String> testTokens = [
    "2a40f02dab12e7ee15026ab2543eaeda2336ec29",
    "d5ad018778072caccfceb10270ae0080879abd6c",
    "1639efd262b925a10585ae333243fb8177d2ddb9",
    "f505356a146cd505bb79b41174b975209d8cde3b",
  ];

  final String primaryToken = testTokens.first;

  late TechnicianOnboardingRemoteDataSource dataSource;
  late TechnicianRepositoryImpl repository;
  late GetOnboardingMetadataUseCase getMetadataUseCase;
  late UploadMediaUseCase uploadMediaUseCase;
  late RegisterTechnicianUseCase registerUseCase;

  setUp(() {
    dataSource = TechnicianOnboardingRemoteDataSource();
    repository = TechnicianRepositoryImpl(dataSource);
    getMetadataUseCase = GetOnboardingMetadataUseCase(repository);
    uploadMediaUseCase = UploadMediaUseCase(repository);
    registerUseCase = RegisterTechnicianUseCase(repository);
  });

  group('Technician Onboarding - Clean Architecture Full Suite', () {
    // --- GROUP 1: METADATA ---
    test('SUCCESS: Should fetch service tree with sub-services', () async {
      final services = await getMetadataUseCase.execute();
      expect(services, isNotEmpty);
      expect(services.first.subServices, isNotEmpty);
      print("✓ Metadata fetched: ${services.length} categories found.");
    });

    // --- GROUP 2: MEDIA UPLOAD ---
    group('Use Case: UploadMedia', () {
      test('SUCCESS: Should stage image and return valid UUID', () async {
        final file = File('test/assets/test_profile.jpg');
        if (!await file.exists()) {
          print(
            "! Skipping Image Test: File not found at test/assets/test_profile.jpg",
          );
          return;
        }

        final uuid = await uploadMediaUseCase.execute(file, primaryToken);
        expect(uuid, isNotNull);
        expect(uuid.length, greaterThan(20));
        print("✓ Media staged successfully. UUID: $uuid");
      });

      test('FAILURE: Should throw HttpFailure on bad token', () async {
        final file = File('test/assets/test_profile.jpg');
        // The DataSource throws HttpFailure directly for Uploads
        expect(
          () => uploadMediaUseCase.execute(file, "invalid_token"),
          throwsA(isA<OnboardingServerFailure>()),
        );
      });
    });

    // --- GROUP 3: REGISTRATION (FULL LIFECYCLE) ---
    group('Use Case: RegisterTechnician', () {
      // 1. HAPPY PATH + DUPLICATE HANDLING
      test('SUCCESS: Register technician per token (Handles Duplicates)', () async {
        final services = await getMetadataUseCase.execute();
        final validSubServiceId = services.first.subServices.first.id;
        final testImage = File('test/assets/test_profile.jpg');

        for (String token in testTokens) {
          try {
            // Phase 1: Upload Media
            final pUuid = await uploadMediaUseCase.execute(testImage, token);
            final cUuid = await uploadMediaUseCase.execute(testImage, token);

            // Phase 2: Finalize
            final result = await registerUseCase.execute(
              token: token,
              firstName: "Tech",
              lastName: "User_${token.substring(0, 4)}",
              city: "LHR",
              // Unique CNIC per token
              cnicNumber:
                  "35202-${(1000000 + testTokens.indexOf(token)).toString()}-1",
              experienceYears: 3,
              bio: "Automated Clean Arch test.",
              profilePictureUuid: pUuid,
              cnicPictureUuid: cUuid,
              skills: [
                SkillSelectionEntity(
                  subServiceId: validSubServiceId,
                  yearsOfExperience: 3,
                ),
              ],
            );

            expect(result.profileId, isNotNull);
            print(
              "✓ Token ${token.substring(0, 5)}... Registered. ID: ${result.profileId}",
            );
          } on DuplicateTechnician catch (_) {
            // NEW: We catch the specific Domain Exception!
            print(
              "! Token ${token.substring(0, 5)}... already has a profile. Skipping...",
            );
          } catch (e) {
            // Fail on any other error
            fail("Unexpected error for token $token: $e");
          }
        }
      });

      // 2. EDGE CASE: INVALID INPUT (400)
      test('EDGE CASE: Backend CNIC Validation Failure', () async {
        expect(
          () => registerUseCase.execute(
            token: primaryToken,
            firstName: "Fail",
            lastName: "Test",
            city: "LHR",
            cnicNumber: "123", // INVALID FORMAT
            experienceYears: 1,
            bio: "Short bio",
            profilePictureUuid: "00000000-0000-0000-0000-000000000000",
            cnicPictureUuid: "00000000-0000-0000-0000-000000000000",
            skills: [],
          ),
          // NEW: Checks for the specific Domain Class
          throwsA(isA<InvalidOnboardingInput>()),
        );
      });

      // 3. EDGE CASE: EXPIRED UUID (404)
      test('EDGE CASE: Invalid/Expired Media UUID', () async {
        expect(
          () => registerUseCase.execute(
            token: primaryToken,
            firstName: "Ahmed",
            lastName: "Khan",
            city: "LHR",
            cnicNumber: "35202-9999999-9",
            experienceYears: 5,
            bio: "Test bio",
            // These UUIDs don't exist in DB -> 404
            profilePictureUuid: "00000000-0000-0000-0000-000000000000",
            cnicPictureUuid: "00000000-0000-0000-0000-000000000000",
            skills: [],
          ),
          // NEW: Checks for the specific Domain Class
          throwsA(isA<OnboardingSessionExpired>()),
        );
      });
    });
  });
}
*/

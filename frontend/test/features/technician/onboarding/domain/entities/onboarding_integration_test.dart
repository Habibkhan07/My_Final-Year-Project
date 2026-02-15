import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/onboarding/data/data_sources/technician_onboarding_remote_datasource.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/upload_media_usecase.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/register_technician_usecase.dart';
import 'package:frontend/features/technician/onboarding/data/repositories/technician_onboarding_repository_impl.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/skill_selection_entity.dart';

void main() {
  // CONFIGURATION: Using your 4 verified tokens
  final List<String> testTokens = [
    "2a40f02dab12e7ee15026ab2543eaeda2336ec29",
    "d5ad018778072caccfceb10270ae0080879abd6c",
    "1639efd262b925a10585ae333243fb8177d2ddb9",
    "f505356a146cd505bb79b41174b975209d8cde3b",
  ];

  // Use the first token for general utility tests
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

  group('Technician Onboarding - Full Lifecycle & Multi-Token Suite', () {
    // --- GROUP 1: METADATA FETCHING (PREVIOUS TEST RESTORED) ---
    group('Use Case: GetOnboardingMetadata', () {
      test('SUCCESS: Should fetch service tree with sub-services', () async {
        final services = await getMetadataUseCase.execute();
        expect(services, isNotEmpty);
        expect(services.first.subServices, isNotEmpty);
        print("✓ Metadata fetched: ${services.length} categories found.");
      });
    });

    // --- GROUP 2: MEDIA UPLOAD (PREVIOUS TESTS RESTORED) ---
    group('Use Case: UploadMedia', () {
      test('SUCCESS: Should stage image and return valid UUID', () async {
        final file = File('test/assets/test_profile.jpg');
        if (!await file.exists()) return;

        final uuid = await uploadMediaUseCase.execute(file, primaryToken);
        expect(uuid, isNotNull);
        expect(uuid.length, greaterThan(20));
        print("✓ Media staged successfully. UUID: $uuid");
      });

      test('FAILURE: Should throw error on invalid/missing token', () async {
        final file = File('test/assets/test_profile.jpg');
        expect(
          () => uploadMediaUseCase.execute(file, "invalid_token"),
          throwsA(contains("401")),
        );
      });
    });

    // --- GROUP 3: REGISTRATION (TARGETED TOKENS & EDGE CASES) ---
    group('Use Case: RegisterTechnician', () {
      test('SUCCESS: Register one technician per provided token (Looping)', () async {
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
              cnicNumber:
                  "35202-${(1000000 + testTokens.indexOf(token)).toString()}-1",
              experienceYears: 3,
              bio: "Automated test profile.",
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
          } catch (e) {
            if (e.toString().contains("1062") ||
                e.toString().contains("Duplicate")) {
              print(
                "! Token ${token.substring(0, 5)}... already has a profile. Skipping...",
              );
            } else {
              rethrow;
            }
          }
        }
      });

      test('EDGE CASE: Backend CNIC Validation Failure (RESTORED)', () async {
        expect(
          () => registerUseCase.execute(
            token: primaryToken,
            firstName: "Fail",
            lastName: "Test",
            city: "LHR",
            cnicNumber: "123-456", // Triggering Django regex
            experienceYears: 1,
            bio: "Short bio",
            profilePictureUuid: "00000000-0000-0000-0000-000000000000",
            cnicPictureUuid: "00000000-0000-0000-0000-000000000000",
            skills: [],
          ),
          throwsA(contains("400")),
        );
      });

      test('EDGE CASE: Invalid/Expired Media UUID (RESTORED)', () async {
        expect(
          () => registerUseCase.execute(
            token: primaryToken,
            firstName: "Ahmed",
            lastName: "Khan",
            city: "LHR",
            cnicNumber: "35202-1234567-1",
            experienceYears: 5,
            bio: "Test bio",
            profilePictureUuid: "00000000-0000-0000-0000-000000000000",
            cnicPictureUuid: "00000000-0000-0000-0000-000000000000",
            skills: [],
          ),
          throwsA(contains("One or more image UUIDs are invalid")), //
        );
      });
    });
  });
}

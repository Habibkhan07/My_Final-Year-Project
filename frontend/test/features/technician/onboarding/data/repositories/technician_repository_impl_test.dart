import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Import architecture layers
import 'package:frontend/features/technician/onboarding/data/data_sources/technician_onboarding_remote_datasource.dart';
import 'package:frontend/features/technician/onboarding/data/models/service_model.dart';
import 'package:frontend/features/technician/onboarding/data/models/technician_registration_model.dart';
import 'package:frontend/features/technician/onboarding/data/repositories/technician_onboarding_repository_impl.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/service_entity.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/skill_selection_entity.dart';

// Mocking the Data Source to isolate the Repository
class MockRemoteDataSource extends Mock
    implements TechnicianOnboardingRemoteDataSource {}

void main() {
  late TechnicianRepositoryImpl repository;
  late MockRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockRemoteDataSource();
    repository = TechnicianRepositoryImpl(mockDataSource);

    // Registering fallback for Mocktail to handle custom models in 'any()' calls
    registerFallbackValue(
      TechnicianRegistrationModel(
        firstName: '',
        lastName: '',
        city: '',
        cnicNumber: '',
        experienceYears: 0,
        bio: '',
        profilePictureUuid: '',
        cnicPictureUuid: '',
        skills: [],
      ),
    );
  });

  group('getOnboardingMetadata', () {
    final tServiceModels = [
      ServiceModel(
        id: 1,
        name: 'Plumbing',
        subServices: [
          SubServiceModel(id: 101, name: 'Leak Repair', basePrice: 1500.0),
        ],
      ),
    ];

    test(
      'SUCCESS: Should map ServiceModels to ServiceEntities correctly',
      () async {
        // Arrange
        when(
          () => mockDataSource.getOnboardingMetadata(),
        ).thenAnswer((_) async => tServiceModels);

        // Act
        final result = await repository.getOnboardingMetadata();

        // Assert
        expect(result, isA<List<ServiceEntity>>());
        expect(result[0].name, 'Plumbing');
        expect(
          result[0].subServices[0].basePrice,
          "1500.0",
        ); // Double to String conversion
      },
    );

    test('EDGE CASE: Network Failure (SocketException)', () async {
      when(
        () => mockDataSource.getOnboardingMetadata(),
      ).thenThrow(const SocketException("No connection"));

      expect(
        () => repository.getOnboardingMetadata(),
        throwsA("No internet connection. Please check your network."),
      );
    });
  });

  group('finalizeRegistration', () {
    const tToken = 'test_token';

    // Updated to use SkillSelectionEntity
    final tSkills = [
      const SkillSelectionEntity(
        subServiceId: 101,
        yearsOfExperience: 3,
        licenseMediaUuid: 'uuid-license-123',
      ),
    ];

    test(
      'SUCCESS: Should correctly map Entities to Models and return TechnicianEntity',
      () async {
        // Arrange: Mock backend response
        when(
          () => mockDataSource.finalizeRegistration(any(), any()),
        ).thenAnswer(
          (_) async => {
            'profile_id': 55,
            'status': 'Pending Approval',
            'joined_date': '2025-02-14',
          },
        );

        // Act
        final result = await repository.finalizeRegistration(
          token: tToken,
          firstName: 'John',
          lastName: 'Doe',
          city: 'Lahore',
          cnicNumber: '12345-1234567-1',
          experienceYears: 5,
          bio: 'Expert',
          profilePictureUuid: 'uuid-p',
          cnicPictureUuid: 'uuid-c',
          skills: tSkills, // Passing Entity list
        );

        // Assert: Verify mapping from Entity to Model inside Repository
        final captured =
            verify(
                  () =>
                      mockDataSource.finalizeRegistration(captureAny(), tToken),
                ).captured.first
                as TechnicianRegistrationModel;

        expect(captured.skills[0].subServiceId, 101);
        expect(captured.skills[0].yearsOfExperience, 3);
        expect(captured.skills[0].licenseMediaUuid, 'uuid-license-123');
        expect(result.profileId, 55);
        expect(result.fullName, "John Doe"); // Verify name concatenation
      },
    );

    test('EDGE CASE: Django Validation Error (uuid_error)', () async {
      when(
        () => mockDataSource.finalizeRegistration(any(), any()),
      ).thenThrow("400: One or more image UUIDs are invalid or expired.");

      expect(
        () => repository.finalizeRegistration(
          token: tToken,
          firstName: 'A',
          lastName: 'B',
          city: 'C',
          cnicNumber: '11111-1111111-1',
          experienceYears: 1,
          bio: 'X',
          profilePictureUuid: 'invalid',
          cnicPictureUuid: 'valid',
          skills: [],
        ),
        throwsA("400: One or more image UUIDs are invalid or expired."),
      );
    });

    test('EDGE CASE: Server Crash (FormatException)', () async {
      when(
        () => mockDataSource.finalizeRegistration(any(), any()),
      ).thenThrow(const FormatException());

      expect(
        () => repository.finalizeRegistration(
          token: tToken,
          firstName: 'A',
          lastName: 'B',
          city: 'C',
          cnicNumber: '11111-1111111-1',
          experienceYears: 1,
          bio: 'X',
          profilePictureUuid: 'P',
          cnicPictureUuid: 'C',
          skills: [],
        ),
        throwsA("Bad response from server. Please contact support."),
      );
    });
  });
}

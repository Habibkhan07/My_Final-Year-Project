import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/onboarding/data/data_sources/onboarding_local_data_source.dart';
import 'package:frontend/features/technician/onboarding/data/data_sources/technician_onboarding_remote_datasource.dart';
import 'package:frontend/features/technician/onboarding/data/models/technician_registration_model.dart';
import 'package:frontend/features/technician/onboarding/data/repositories/technician_onboarding_repository_impl.dart';
import 'package:frontend/features/technician/onboarding/domain/failures/technician_failure.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/technician_entity.dart';

class MockRemoteDataSource extends Mock
    implements TechnicianOnboardingRemoteDataSource {}

class MockLocalDataSource extends Mock implements OnboardingLocalDataSource {}

class FakeTechnicianRegistrationModel extends Fake
    implements TechnicianRegistrationModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTechnicianRegistrationModel());
  });

  late TechnicianRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    repository = TechnicianRepositoryImpl(
      mockRemoteDataSource,
      mockLocalDataSource,
    );
  });

  group('TechnicianRepositoryImpl Error Propagation Pipeline', () {
    const tToken = 'test-token';
    const tFirstName = 'Ali';
    const tLastName = 'Raza';

    // Helper to call finalizeRegistration with dummy data
    Future<TechnicianEntity> callFinalize() => repository.finalizeRegistration(
      token: tToken,
      firstName: tFirstName,
      lastName: tLastName,
      city: 'LHR',
      cnicNumber: '12345',
      experienceYears: 5,
      bio: 'bio',
      profilePictureUuid: 'uuid1',
      cnicPictureUuid: 'uuid2',
      skills: [],
      categoryLicenses: [],
    );

    test(
      'should save boolean to local storage and return Entity on successful finalize',
      () async {
        // Arrange
        final tResponse = {
          'profile_id': 42,
          'status': 'PENDING',
          'joined_date': '2023-01-01',
        };

        when(
          () => mockRemoteDataSource.finalizeRegistration(any(), tToken),
        ).thenAnswer((_) async => tResponse);
        when(
          () => mockLocalDataSource.saveOnboardingComplete(true),
        ).thenAnswer((_) async => Future.value());

        // Act
        final result = await callFinalize();

        // Assert
        expect(result.profileId, 42);
        expect(result.status, 'PENDING');
        expect(result.fullName, '$tFirstName $tLastName');

        // Strict verification of Side Effect (Tier 2 Local Storage)
        verify(
          () => mockLocalDataSource.saveOnboardingComplete(true),
        ).called(1);
      },
    );

    test('should throw OnboardingUnauthorized on 401', () async {
      when(
        () => mockRemoteDataSource.finalizeRegistration(any(), any()),
      ).thenThrow(
        HttpFailure(
          statusCode: 401,
          code: 'unauthorized',
          message: 'Token invalid',
          errors: {},
        ),
      );

      expect(() => callFinalize(), throwsA(isA<OnboardingUnauthorized>()));
    });

    test(
      'should throw InvalidOnboardingInput on 400 validation error',
      () async {
        final tErrors = {
          'cnic': ['Invalid format'],
        };
        when(
          () => mockRemoteDataSource.finalizeRegistration(any(), any()),
        ).thenThrow(
          HttpFailure(
            statusCode: 400,
            code: 'validation_error',
            message: 'Bad input',
            errors: tErrors,
          ),
        );

        expect(
          () => callFinalize(),
          throwsA(
            isA<InvalidOnboardingInput>().having(
              (e) => e.errors,
              'errors',
              tErrors,
            ),
          ),
        );
      },
    );

    test(
      'should throw OnboardingSessionExpired on 404 (Expired UUIDs)',
      () async {
        when(
          () => mockRemoteDataSource.finalizeRegistration(any(), any()),
        ).thenThrow(
          HttpFailure(
            statusCode: 404,
            code: 'not_found',
            message: 'UUID expired',
            errors: {},
          ),
        );

        expect(() => callFinalize(), throwsA(isA<OnboardingSessionExpired>()));
      },
    );

    test('should throw DuplicateTechnician on 409 resource conflict', () async {
      when(
        () => mockRemoteDataSource.finalizeRegistration(any(), any()),
      ).thenThrow(
        HttpFailure(
          statusCode: 409,
          code: 'resource_conflict',
          message: 'CNIC exists',
          errors: {},
        ),
      );

      expect(() => callFinalize(), throwsA(isA<DuplicateTechnician>()));
    });

    test(
      'should throw DuplicateApplicationFailure(applicationStatus=PENDING) '
      'on 409 duplicate_application with PENDING wire status',
      () async {
        when(
          () => mockRemoteDataSource.finalizeRegistration(any(), any()),
        ).thenThrow(
          HttpFailure(
            statusCode: 409,
            code: 'duplicate_application',
            message: 'You already have an active technician application.',
            errors: {
              'application_status': ['PENDING'],
            },
          ),
        );

        await expectLater(
          callFinalize(),
          throwsA(isA<DuplicateApplicationFailure>().having(
            (e) => e.applicationStatus,
            'applicationStatus',
            'PENDING',
          )),
        );
      },
    );

    test(
      'should throw DuplicateApplicationFailure(applicationStatus=APPROVED) '
      'on 409 duplicate_application with APPROVED wire status',
      () async {
        when(
          () => mockRemoteDataSource.finalizeRegistration(any(), any()),
        ).thenThrow(
          HttpFailure(
            statusCode: 409,
            code: 'duplicate_application',
            message: 'You are already an approved technician.',
            errors: {
              'application_status': ['APPROVED'],
            },
          ),
        );

        await expectLater(
          callFinalize(),
          throwsA(isA<DuplicateApplicationFailure>().having(
            (e) => e.applicationStatus,
            'applicationStatus',
            'APPROVED',
          )),
        );
      },
    );

    test(
      'should throw DuplicateApplicationFailure(applicationStatus=null) '
      'when errors envelope is malformed/empty',
      () async {
        // Defensive parsing — if the backend ever ships the code without
        // the structured ``application_status`` payload, the failure
        // should still construct cleanly with a null status. The screen
        // falls back to the generic message and a default CTA.
        when(
          () => mockRemoteDataSource.finalizeRegistration(any(), any()),
        ).thenThrow(
          HttpFailure(
            statusCode: 409,
            code: 'duplicate_application',
            message: 'You already applied.',
            errors: {},
          ),
        );

        await expectLater(
          callFinalize(),
          throwsA(isA<DuplicateApplicationFailure>().having(
            (e) => e.applicationStatus,
            'applicationStatus',
            isNull,
          )),
        );
      },
    );

    test(
      'should throw OnboardingNetworkFailure on SocketException (No Internet)',
      () async {
        when(
          () => mockRemoteDataSource.finalizeRegistration(any(), any()),
        ).thenThrow(const SocketException('Failed host lookup'));

        expect(() => callFinalize(), throwsA(isA<OnboardingNetworkFailure>()));
      },
    );

    test(
      'should throw OnboardingParsingFailure on FormatException (HTML returned instead of JSON)',
      () async {
        when(
          () => mockRemoteDataSource.finalizeRegistration(any(), any()),
        ).thenThrow(const FormatException('Unexpected character'));

        expect(() => callFinalize(), throwsA(isA<OnboardingParsingFailure>()));
      },
    );
  });
}

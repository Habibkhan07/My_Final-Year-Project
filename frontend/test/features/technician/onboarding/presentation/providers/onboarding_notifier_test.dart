import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/common/domain/entities/user_entity.dart';
import 'package:frontend/features/auth/domain/use_cases/request_otp_use_case.dart';
import 'package:frontend/features/auth/domain/use_cases/verify_otp_use_case.dart';
import 'package:frontend/features/auth/domain/use_cases/complete_signup_use_case.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/service_entity.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/technician_entity.dart';
import 'package:frontend/features/technician/onboarding/domain/failures/technician_failure.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/register_technician_usecase.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_state.dart';

class MockGetOnboardingMetadataUseCase extends Mock
    implements GetOnboardingMetadataUseCase {}

class MockRegisterTechnicianUseCase extends Mock
    implements RegisterTechnicianUseCase {}

class MockRequestOtpUseCase extends Mock implements RequestOtpUseCase {}

class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class MockCompleteSignupUseCase extends Mock implements CompleteSignupUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserEntity extends Fake implements UserEntity {}

// We need a dummy listener to observe state changes
class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AsyncLoading<OnboardingState>());
    registerFallbackValue(FakeUserEntity());
  });

  late ProviderContainer container;
  late MockGetOnboardingMetadataUseCase mockGetOnboardingMetadataUseCase;
  late MockRegisterTechnicianUseCase mockRegisterTechnicianUseCase;

  const tUser = UserEntity(
    phone: '+923001234567',
    token: 'valid-token',
    nameRequired: false,
    firstName: 'OriginalFirst',
    lastName: 'OriginalLast',
  );

  const tServices = [
    ServiceEntity(
      id: 1,
      name: 'AC Repair',
      subServices: [
        SubServiceEntity(
          id: 10,
          name: 'Wash',
          basePrice: '1000',
          maxPrice: '2000',
        ),
      ],
    ),
  ];

  setUp(() {
    mockGetOnboardingMetadataUseCase = MockGetOnboardingMetadataUseCase();
    mockRegisterTechnicianUseCase = MockRegisterTechnicianUseCase();

    // The notifier calls this on build
    when(
      () => mockGetOnboardingMetadataUseCase.execute(),
    ).thenAnswer((_) async => tServices);

    container = ProviderContainer(
      overrides: [
        getOnboardingMetadataUseCaseProvider.overrideWithValue(
          mockGetOnboardingMetadataUseCase,
        ),
        registerTechnicianUseCaseProvider.overrideWithValue(
          mockRegisterTechnicianUseCase,
        ),
        authenticatedUserProvider.overrideWithValue(tUser),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('OnboardingNotifier', () {
    test(
      'build() initializes with auth user details and fetched services',
      () async {
        final state = await container.read(onboardingProvider.future);
        expect(state.firstName, 'OriginalFirst');
        expect(state.lastName, 'OriginalLast');
        expect(state.services, tServices);
        verify(() => mockGetOnboardingMetadataUseCase.execute()).called(1);
      },
    );

    test('updatePersonalInfo mutates state synchronously', () async {
      await container.read(onboardingProvider.future);
      final listener = Listener<AsyncValue<OnboardingState>>();
      container.listen(
        onboardingProvider,
        listener.call,
        fireImmediately: false,
      );

      container
          .read(onboardingProvider.notifier)
          .updatePersonalInfo(
            firstName: 'NewFirst',
            city: 'LHR',
          );

      final finalState = container.read(onboardingProvider).requireValue;
      expect(finalState.firstName, 'NewFirst');
      expect(finalState.city, 'LHR');
      verifyNever(
        () => listener.call(
          any(),
          any(that: isA<AsyncLoading<OnboardingState>>()),
        ),
      );
    });

    test('toggleSkill adds and removes skill synchronously', () async {
      await container.read(onboardingProvider.future);

      container.read(onboardingProvider.notifier).toggleSkill(10);
      var state = container.read(onboardingProvider).requireValue;
      expect(state.selectedSkills.length, 1);
      expect(state.selectedSkills.first.subServiceId, 10);

      container.read(onboardingProvider.notifier).toggleSkill(10);
      state = container.read(onboardingProvider).requireValue;
      expect(state.selectedSkills.isEmpty, true);
    });

    test(
      'finalize() success flow updates Auth names and emits Data in submissionStatus',
      () async {
        // Create a fresh container that runs the REAL AuthNotifier but with mocked UseCases
        final mockVerify = MockVerifyOtpUseCase();
        final mockAuthRepo = MockAuthRepository();

        when(() => mockAuthRepo.getCachedUser()).thenAnswer((_) async => null);
        when(
          () => mockAuthRepo.persistUser(any()),
        ).thenAnswer((_) async => Future.value());
        when(
          () => mockVerify.execute(any(), any()),
        ).thenAnswer((_) async => tUser);

        final customContainer = ProviderContainer(
          overrides: [
            getOnboardingMetadataUseCaseProvider.overrideWithValue(
              mockGetOnboardingMetadataUseCase,
            ),
            registerTechnicianUseCaseProvider.overrideWithValue(
              mockRegisterTechnicianUseCase,
            ),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            verifyOtpUseCaseProvider.overrideWithValue(mockVerify),
            requestOtpUseCaseProvider.overrideWithValue(
              MockRequestOtpUseCase(),
            ),
            completeSignupUseCaseProvider.overrideWithValue(
              MockCompleteSignupUseCase(),
            ),
          ],
        );

        // Wait for auth to build
        await customContainer.read(authProvider.future);

        // Seed AuthNotifier so authenticatedUserProvider yields a user with token
        await customContainer
            .read(authProvider.notifier)
            .verifyOtp('+923001234567', '123456');

        await customContainer.read(onboardingProvider.future);

        customContainer
            .read(onboardingProvider.notifier)
            .updatePersonalInfo(
              firstName: 'FinalFirst',
              lastName: 'FinalLast',
              cnic: '12345',
            );

        customContainer.read(onboardingProvider.notifier).state = AsyncData(
          customContainer
              .read(onboardingProvider)
              .requireValue
              .copyWith(profilePictureUuid: 'uuid1', cnicPictureUuid: 'uuid2'),
        );

        final tTechEntity = const TechnicianEntity(
          profileId: 1,
          status: 'PENDING',
          fullName: 'FinalFirst FinalLast',
          joinedDate: '2023-01-01',
        );

        when(
          () => mockRegisterTechnicianUseCase.execute(
            token: any(named: 'token'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            profilePictureUuid: any(named: 'profilePictureUuid'),
            city: any(named: 'city'),
            cnicNumber: any(named: 'cnicNumber'),
            cnicPictureUuid: any(named: 'cnicPictureUuid'),
            categoryLicenses: any(named: 'categoryLicenses'),
            skills: any(named: 'skills'),
            baseLatitude: any(named: 'baseLatitude'),
            baseLongitude: any(named: 'baseLongitude'),
            maxTravelRadiusKm: any(named: 'maxTravelRadiusKm'),
            workAddressLabel: any(named: 'workAddressLabel'),
          ),
        ).thenAnswer((_) async => tTechEntity);

        // Act
        await customContainer.read(onboardingProvider.notifier).finalize();

        // Wait for microtasks and rebuilds to resolve so authState actually updates
        await customContainer.read(onboardingProvider.future);

        // Assert submissionStatus contains the data
        final state = customContainer.read(onboardingProvider).requireValue;
        expect(state.submissionStatus, isA<AsyncData<TechnicianEntity?>>());
        expect(state.submissionStatus.value, tTechEntity);

        // SQA Verification: Did it ping the real AuthNotifier to sync the new names?
        final authUser = customContainer.read(authProvider).value?.user;
        expect(authUser?.firstName, 'FinalFirst');
        expect(authUser?.lastName, 'FinalLast');

        customContainer.dispose();
      },
    );

    test('finalize() handles Missing Token securely', () async {
      // Overriding authenticatedUserProvider with null directly
      // allows us to simulate unauthenticated state trivially.
      final noUserContainer = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(
            mockGetOnboardingMetadataUseCase,
          ),
          authenticatedUserProvider.overrideWithValue(null),
        ],
      );
      await noUserContainer.read(onboardingProvider.future);

      await noUserContainer.read(onboardingProvider.notifier).finalize();

      final state = noUserContainer.read(onboardingProvider).requireValue;
      expect(state.submissionStatus, isA<AsyncError<TechnicianEntity?>>());
      expect(state.submissionStatus.error, isA<OnboardingUnauthorized>());

      noUserContainer.dispose();
    });
  });
}

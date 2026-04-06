import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/common/domain/entities/user_entity.dart';
import 'package:frontend/features/auth/domain/failures/auth_failure.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/use_cases/request_otp_use_case.dart';
import 'package:frontend/features/auth/domain/use_cases/verify_otp_use_case.dart';
import 'package:frontend/features/auth/domain/use_cases/complete_signup_use_case.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/auth_state.dart';
import 'package:frontend/features/auth/presentation/providers/dependency_injection.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockRequestOtpUseCase extends Mock implements RequestOtpUseCase {}
class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}
class MockCompleteSignupUseCase extends Mock implements CompleteSignupUseCase {}
class FakeUserEntity extends Fake implements UserEntity {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AsyncLoading<AuthState>());
    registerFallbackValue(FakeUserEntity());
  });

  late ProviderContainer container;
  late MockAuthRepository mockRepo;
  late MockRequestOtpUseCase mockRequestOtp;
  late MockVerifyOtpUseCase mockVerifyOtp;
  late MockCompleteSignupUseCase mockCompleteSignup;

  const tPhone = '+923001234567';
  const tOtp = '123456';
  const tToken = 'abc123token';

  setUp(() {
    mockRepo = MockAuthRepository();
    mockRequestOtp = MockRequestOtpUseCase();
    mockVerifyOtp = MockVerifyOtpUseCase();
    mockCompleteSignup = MockCompleteSignupUseCase();

    // build() calls getCachedUser — return null by default (no prior session)
    when(() => mockRepo.getCachedUser()).thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        requestOtpUseCaseProvider.overrideWithValue(mockRequestOtp),
        verifyOtpUseCaseProvider.overrideWithValue(mockVerifyOtp),
        completeSignupUseCaseProvider.overrideWithValue(mockCompleteSignup),
      ],
    );
  });

  tearDown(() => container.dispose());

  // ---------------------------------------------------------------------------
  // build / initial state
  // ---------------------------------------------------------------------------

  group('build', () {
    test('initial state is AsyncData(AuthState()) when no cached session', () async {
      await container.read(authProvider.future);
      expect(container.read(authProvider), const AsyncData(AuthState()));
    });

    test('initial state contains cached user when session exists', () async {
      const cachedUser = UserEntity(phone: tPhone, token: tToken, nameRequired: false);
      final mockRepoWithUser = MockAuthRepository();
      when(() => mockRepoWithUser.getCachedUser()).thenAnswer((_) async => cachedUser);

      final c = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockRepoWithUser),
      ]);
      addTearDown(c.dispose);

      await c.read(authProvider.future);
      expect(c.read(authProvider).value?.user?.phone, tPhone);
    });
  });

  // ---------------------------------------------------------------------------
  // requestOtp
  // ---------------------------------------------------------------------------

  group('requestOtp', () {
    test('emits AsyncLoading then AsyncData with successMessage on success', () async {
      await container.read(authProvider.future);
      when(() => mockRequestOtp.execute(tPhone)).thenAnswer((_) async => 'OTP Sent');

      final listener = Listener<AsyncValue<AuthState>>();
      container.listen(authProvider, listener.call, fireImmediately: false);

      final future = container.read(authProvider.notifier).requestOtp(tPhone);

      verify(() => listener.call(
        const AsyncData(AuthState()),
        any(that: isA<AsyncLoading<AuthState>>()),
      )).called(1);

      await future;

      verify(() => listener.call(
        any(that: isA<AsyncLoading<AuthState>>()),
        const AsyncData(AuthState(successMessage: 'OTP Sent')),
      )).called(1);

      expect(container.read(authProvider),
          const AsyncData(AuthState(successMessage: 'OTP Sent')));
    });

    test('emits AsyncError with InvalidInput on SMS delivery failure', () async {
      await container.read(authProvider.future);
      when(() => mockRequestOtp.execute(tPhone)).thenThrow(
        const InvalidInput('Failed to send OTP via SMS: test error', {}),
      );

      await container.read(authProvider.notifier).requestOtp(tPhone);

      final state = container.read(authProvider);
      expect(state, isA<AsyncError<AuthState>>());
      expect(state.error, isA<InvalidInput>());
      expect((state.error as InvalidInput).message, contains('Failed to send OTP'));
    });

    test('emits AsyncError with InvalidInput on phone validation failure', () async {
      await container.read(authProvider.future);
      final errors = {'phone': ['Enter a valid Pakistani mobile number.']};
      when(() => mockRequestOtp.execute(tPhone)).thenThrow(
        InvalidInput('Invalid input data.', errors),
      );

      await container.read(authProvider.notifier).requestOtp(tPhone);

      final state = container.read(authProvider);
      expect(state.error, isA<InvalidInput>());
      expect((state.error as InvalidInput).errors['phone']?.first,
          'Enter a valid Pakistani mobile number.');
    });
  });

  // ---------------------------------------------------------------------------
  // verifyOtp
  // ---------------------------------------------------------------------------

  group('verifyOtp', () {
    const tUser = UserEntity(
      phone: tPhone,
      token: tToken,
      isTechnician: false,
      nameRequired: true,
    );

    test('emits AsyncData with user on success', () async {
      await container.read(authProvider.future);
      when(() => mockVerifyOtp.execute(tPhone, tOtp)).thenAnswer((_) async => tUser);

      await container.read(authProvider.notifier).verifyOtp(tPhone, tOtp);

      final state = container.read(authProvider);
      expect(state.value?.user?.phone, tPhone);
      expect(state.value?.user?.token, tToken);
    });

    test('emits AsyncError with InvalidInput on wrong OTP — message and field errors both set', () async {
      await container.read(authProvider.future);
      final errors = {'otp': ['Invalid OTP.']};
      // Fixed: InvalidInput now takes (message, errors) — was single-arg before
      when(() => mockVerifyOtp.execute(tPhone, tOtp)).thenThrow(
        InvalidInput('Invalid OTP.', errors),
      );

      await container.read(authProvider.notifier).verifyOtp(tPhone, tOtp);

      final state = container.read(authProvider);
      expect(state, isA<AsyncError<AuthState>>());
      final failure = state.error as InvalidInput;
      expect(failure.message, 'Invalid OTP.');
      expect(failure.errors, errors);
    });

    test('emits AsyncError with InvalidInput when OTP has expired', () async {
      await container.read(authProvider.future);
      when(() => mockVerifyOtp.execute(tPhone, tOtp)).thenThrow(
        const InvalidInput(
          'OTP has expired. Please request a new one.',
          {'otp': ['OTP has expired. Please request a new one.']},
        ),
      );

      await container.read(authProvider.notifier).verifyOtp(tPhone, tOtp);

      final state = container.read(authProvider);
      expect((state.error as InvalidInput).message, contains('expired'));
    });
  });

  // ---------------------------------------------------------------------------
  // completeSignup
  // ---------------------------------------------------------------------------

  group('completeSignup', () {
    const tUserWithToken = UserEntity(
      phone: tPhone,
      token: tToken,
      nameRequired: true,
    );

    ProviderContainer makeContainerWithUser() {
      final mockRepoWithUser = MockAuthRepository();
      when(() => mockRepoWithUser.getCachedUser())
          .thenAnswer((_) async => tUserWithToken);
      when(() => mockRepoWithUser.persistUser(any())).thenAnswer((_) async {});

      return ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockRepoWithUser),
        completeSignupUseCaseProvider.overrideWithValue(mockCompleteSignup),
      ]);
    }

    test('emits AsyncData with updated user and successMessage on success', () async {
      final c = makeContainerWithUser();
      addTearDown(c.dispose);
      await c.read(authProvider.future);

      when(() => mockCompleteSignup.execute('Ali', 'Raza', tToken))
          .thenAnswer((_) async => 'Profile updated successfully.');

      await c.read(authProvider.notifier).completeSignup('Ali', 'Raza');

      final state = c.read(authProvider);
      expect(state.value?.successMessage, 'Profile updated successfully.');
      expect(state.value?.user?.nameRequired, false);
    });

    test('emits AsyncError with Unauthorized when token is missing', () async {
      // Container with no cached user → token will be null
      await container.read(authProvider.future);

      await container.read(authProvider.notifier).completeSignup('Ali', 'Raza');

      expect(container.read(authProvider).error, isA<Unauthorized>());
    });
  });

  // ---------------------------------------------------------------------------
  // updateProfileNames
  // ---------------------------------------------------------------------------

  group('updateProfileNames', () {
    test('mutates user synchronously — never emits AsyncLoading', () async {
      const initialUser = UserEntity(
        phone: tPhone,
        token: tToken,
        nameRequired: true,
      );
      final mockRepoWithUser = MockAuthRepository();
      when(() => mockRepoWithUser.getCachedUser()).thenAnswer((_) async => initialUser);
      when(() => mockRepoWithUser.persistUser(any())).thenAnswer((_) async {});

      final c = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockRepoWithUser),
      ]);
      addTearDown(c.dispose);
      await c.read(authProvider.future);

      final listener = Listener<AsyncValue<AuthState>>();
      c.listen(authProvider, listener.call, fireImmediately: false);

      c.read(authProvider.notifier).updateProfileNames('Ali', 'Raza');
      await Future.delayed(Duration.zero);

      final finalState = c.read(authProvider);
      expect(finalState, isA<AsyncData<AuthState>>());
      expect(finalState.value?.user?.firstName, 'Ali');
      expect(finalState.value?.user?.lastName, 'Raza');
      expect(finalState.value?.user?.nameRequired, false);

      // Must never transition through AsyncLoading
      verifyNever(() => listener.call(
        any(), any(that: isA<AsyncLoading<AuthState>>()),
      ));
    });
  });

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------

  group('logout', () {
    test('clears state to AsyncData(AuthState()) and calls repository.logout', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      await container.read(authProvider.future);

      await container.read(authProvider.notifier).logout();

      expect(container.read(authProvider), const AsyncData(AuthState()));
      verify(() => mockRepo.logout()).called(1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/data/models/user_model.dart';
import 'package:frontend/core/common/domain/entities/user_entity.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:frontend/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/features/auth/domain/failures/auth_failure.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemote;
  late MockAuthLocalDataSource mockLocal;

  setUpAll(() {
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockLocal = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(mockRemote, mockLocal);
  });

  const tPhone = '+923001234567';
  const tOtp = '123456';
  const tToken = 'abc123token';

  // ---------------------------------------------------------------------------
  // requestOtp
  // ---------------------------------------------------------------------------

  group('requestOtp', () {
    test('returns success message on 200', () async {
      when(
        () => mockRemote.requestOtp(tPhone),
      ).thenAnswer((_) async => 'OTP Sent');

      final result = await repository.requestOtp(tPhone);

      expect(result, 'OTP Sent');
      verify(() => mockRemote.requestOtp(tPhone)).called(1);
    });

    test(
      'throws InvalidInput with field errors for phone validation failure',
      () {
        final errors = {
          'phone': ['Enter a valid Pakistani mobile number.'],
        };
        when(() => mockRemote.requestOtp(any())).thenThrow(
          HttpFailure(
            statusCode: 400,
            code: 'validation_error',
            message: 'Invalid input data.',
            errors: errors,
          ),
        );

        expect(
          () => repository.requestOtp(tPhone),
          throwsA(
            isA<InvalidInput>()
                .having((e) => e.errors, 'errors', errors)
                .having((e) => e.message, 'message', 'Invalid input data.'),
          ),
        );
      },
    );

    // Covers Twilio SMS delivery failure — errors map is empty, human
    // message lives at the top level. Regression: old InvalidInput(errors)
    // dropped this message, showing "Invalid phone number." toast instead.
    test(
      'throws InvalidInput preserving top-level message when errors is empty '
      '(Twilio SMS failure)',
      () {
        when(() => mockRemote.requestOtp(any())).thenThrow(
          HttpFailure(
            statusCode: 400,
            code: 'validation_error',
            message: 'Failed to send OTP via SMS: test error',
            errors: {},
          ),
        );

        expect(
          () => repository.requestOtp(tPhone),
          throwsA(
            isA<InvalidInput>()
                .having(
                  (e) => e.message,
                  'message',
                  'Failed to send OTP via SMS: test error',
                )
                .having((e) => e.errors, 'errors', isEmpty),
          ),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // verifyOtp
  // ---------------------------------------------------------------------------

  group('verifyOtp', () {
    const tUserId = 42;
    const tModel = UserModel(
      id: tUserId,
      phone: tPhone,
      token: tToken,
      isTechnician: false,
      nameRequired: true,
    );

    test(
      'returns UserEntity and saves token + user to local storage on success',
      () async {
        when(
          () => mockRemote.verifyOtp(tPhone, tOtp),
        ).thenAnswer((_) async => tModel);
        when(() => mockLocal.saveToken(tToken)).thenAnswer((_) async {});
        when(() => mockLocal.saveUser(any())).thenAnswer((_) async {});

        final result = await repository.verifyOtp(tPhone, tOtp);

        expect(result.phone, tPhone);
        expect(result.token, tToken);
        expect(result.nameRequired, true);
        // ``id`` from the wire flows through to the cached entity — required
        // so the orchestrator's ``currentAuthUserIdProvider`` override has a
        // non-null value to feed the realtime recipient filter (flag #19).
        expect(result.id, tUserId);
        verify(() => mockLocal.saveToken(tToken)).called(1);
        verify(() => mockLocal.saveUser(any())).called(1);
      },
    );

    test('UserModel.fromJson reads user_id from the verify-otp wire payload', () {
      // Pin the wire field name (``user_id``) so a backend rename surfaces here
      // as a test failure, not as a silently-null id on the device. Wire field
      // is named per /api/accounts/verify-otp/ — see flag #19 / B1.
      final json = <String, dynamic>{
        'user_id': 7,
        'token': 'abc',
        'is_technician': false,
        'name_required': false,
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 7);
      expect(model.toEntity().id, 7);
    });

    test('UserModel.fromJson tolerates missing user_id (legacy cache)', () {
      // Pre-flag-#19 backends did not return user_id. The model must accept
      // this gracefully — null id keeps the recipient filter dormant rather
      // than crashing the parse.
      final json = <String, dynamic>{
        'token': 'abc',
        'is_technician': false,
        'name_required': false,
      };

      final model = UserModel.fromJson(json);

      expect(model.id, isNull);
    });

    test(
      'throws InvalidInput with both message and field error for wrong OTP',
      () {
        final errors = {
          'otp': ['Invalid OTP.'],
        };
        when(() => mockRemote.verifyOtp(any(), any())).thenThrow(
          HttpFailure(
            statusCode: 400,
            code: 'validation_error',
            message: 'Invalid OTP.',
            errors: errors,
          ),
        );

        expect(
          () => repository.verifyOtp(tPhone, tOtp),
          throwsA(
            isA<InvalidInput>()
                .having((e) => e.message, 'message', 'Invalid OTP.')
                .having((e) => e.errors, 'errors', errors),
          ),
        );
      },
    );

    test('throws InvalidInput with expired message when OTP has expired', () {
      final errors = {
        'otp': ['OTP has expired. Please request a new one.'],
      };
      when(() => mockRemote.verifyOtp(any(), any())).thenThrow(
        HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'OTP has expired. Please request a new one.',
          errors: errors,
        ),
      );

      expect(
        () => repository.verifyOtp(tPhone, tOtp),
        throwsA(
          isA<InvalidInput>().having(
            (e) => e.message,
            'message',
            contains('expired'),
          ),
        ),
      );
    });

    test(
      'throws InvalidInput with no-record message when OTP was never requested',
      () {
        final errors = {
          'otp': ['No OTP found for this number. Please request a new one.'],
        };
        when(() => mockRemote.verifyOtp(any(), any())).thenThrow(
          HttpFailure(
            statusCode: 400,
            code: 'validation_error',
            message: 'No OTP found for this number. Please request a new one.',
            errors: errors,
          ),
        );

        expect(
          () => repository.verifyOtp(tPhone, tOtp),
          throwsA(
            isA<InvalidInput>().having(
              (e) => e.message,
              'message',
              contains('No OTP found'),
            ),
          ),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // completeSignup
  // ---------------------------------------------------------------------------

  group('completeSignup', () {
    test('returns success message on 200', () async {
      when(
        () => mockRemote.completeSignup(any(), any(), any()),
      ).thenAnswer((_) async => 'Profile updated successfully.');

      final result = await repository.completeSignup('Ali', 'Raza', tToken);

      expect(result, 'Profile updated successfully.');
    });

    test('throws Unauthorized when token is missing or invalid', () {
      when(() => mockRemote.completeSignup(any(), any(), any())).thenThrow(
        HttpFailure(
          statusCode: 401,
          code: 'unauthorized',
          message: 'Invalid token',
          errors: {},
        ),
      );

      expect(
        () => repository.completeSignup('Ali', 'Raza', tToken),
        throwsA(
          isA<Unauthorized>().having(
            (e) => e.message,
            'message',
            'Invalid token',
          ),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getCachedUser
  // ---------------------------------------------------------------------------

  group('getCachedUser', () {
    const tEntity = UserEntity(phone: tPhone, token: tToken);

    test(
      'returns user with injected token when both user and token are cached',
      () async {
        when(() => mockLocal.getUser()).thenAnswer((_) async => tEntity);
        when(() => mockLocal.getToken()).thenAnswer((_) async => tToken);

        final result = await repository.getCachedUser();

        expect(result?.phone, tPhone);
        expect(result?.token, tToken);
      },
    );

    test(
      'returns null when token is missing — prevents stale session',
      () async {
        when(() => mockLocal.getUser()).thenAnswer((_) async => tEntity);
        when(() => mockLocal.getToken()).thenAnswer((_) async => null);

        expect(await repository.getCachedUser(), isNull);
      },
    );

    test('returns null when user is not cached', () async {
      when(() => mockLocal.getUser()).thenAnswer((_) async => null);
      when(() => mockLocal.getToken()).thenAnswer((_) async => tToken);

      expect(await repository.getCachedUser(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------

  group('logout', () {
    test('without cached token: just clears local storage', () async {
      // No token in secure storage → skip the remote round-trip entirely.
      when(() => mockLocal.getToken()).thenAnswer((_) async => null);
      when(() => mockLocal.clearAll()).thenAnswer((_) async {});

      await repository.logout();

      verifyNever(() => mockRemote.logout(any()));
      verify(() => mockLocal.clearAll()).called(1);
    });

    test('with cached token: posts to /logout/ THEN clears local', () async {
      when(() => mockLocal.getToken()).thenAnswer((_) async => tToken);
      when(() => mockRemote.logout(any())).thenAnswer((_) async {});
      when(() => mockLocal.clearAll()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockRemote.logout(tToken)).called(1);
      verify(() => mockLocal.clearAll()).called(1);
    });

    test(
      'remote logout failure does NOT block the local clear',
      () async {
        // Offline / 401 / dead network — local clear must still happen
        // so the user always lands at /login (server-side token will be
        // reaped on next sync or by future cleanup jobs).
        when(() => mockLocal.getToken()).thenAnswer((_) async => tToken);
        when(() => mockRemote.logout(any())).thenThrow(
          const HttpFailure(
            statusCode: 401,
            code: 'unauthorized',
            message: 'Unauthorized.',
          ),
        );
        when(() => mockLocal.clearAll()).thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockLocal.clearAll()).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // _guard — full error pipeline
  // ---------------------------------------------------------------------------

  group('_guard error pipeline', () {
    test('throws UserAlreadyExists on resource_conflict (409)', () {
      when(() => mockRemote.requestOtp(any())).thenThrow(
        HttpFailure(
          statusCode: 409,
          code: 'resource_conflict',
          message: 'User already exists',
          errors: {},
        ),
      );

      expect(
        () => repository.requestOtp(tPhone),
        throwsA(
          isA<UserAlreadyExists>().having(
            (e) => e.message,
            'message',
            'User already exists',
          ),
        ),
      );
    });

    test('throws ResourcesExpired on not_found (404)', () {
      when(() => mockRemote.requestOtp(any())).thenThrow(
        HttpFailure(
          statusCode: 404,
          code: 'not_found',
          message: 'Resource not found',
          errors: {},
        ),
      );

      expect(
        () => repository.requestOtp(tPhone),
        throwsA(isA<ResourcesExpired>()),
      );
    });

    test('throws Unauthorized on unauthorized (401)', () {
      when(() => mockRemote.completeSignup(any(), any(), any())).thenThrow(
        HttpFailure(
          statusCode: 401,
          code: 'unauthorized',
          message: 'Invalid token',
          errors: {},
        ),
      );

      expect(
        () => repository.completeSignup('Ali', 'Raza', tToken),
        throwsA(isA<Unauthorized>()),
      );
    });

    test('throws ServerError for unknown codes', () {
      when(() => mockRemote.requestOtp(any())).thenThrow(
        HttpFailure(
          statusCode: 500,
          code: 'server_error',
          message: 'Database exploded',
          errors: {},
        ),
      );

      expect(
        () => repository.requestOtp(tPhone),
        throwsA(
          isA<ServerError>().having(
            (e) => e.message,
            'message',
            'Database exploded',
          ),
        ),
      );
    });

    test('wraps non-HttpFailure exceptions in ServerError', () {
      when(
        () => mockRemote.requestOtp(any()),
      ).thenThrow(StateError('Unexpected'));

      expect(() => repository.requestOtp(tPhone), throwsA(isA<ServerError>()));
    });
  });
}

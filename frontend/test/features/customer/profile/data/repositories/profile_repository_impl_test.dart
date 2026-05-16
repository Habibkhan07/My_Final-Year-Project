import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/profile/data/data_sources/profile_local_data_source.dart';
import 'package:frontend/features/customer/profile/data/data_sources/profile_remote_data_source.dart';
import 'package:frontend/features/customer/profile/data/models/customer_profile_model.dart';
import 'package:frontend/features/customer/profile/data/repositories/profile_repository_impl.dart';
import 'package:frontend/features/customer/profile/domain/failures/profile_failure.dart';

class _MockRemote extends Mock implements ProfileRemoteDataSource {}

class _MockLocal extends Mock implements ProfileLocalDataSource {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late ProfileRepositoryImpl repo;
  late _MockRemote remote;
  late _MockLocal local;
  late _MockSecureStorage secureStorage;

  const tToken = 'tok_123';
  const tModel = CustomerProfileModel(
    id: 17,
    phone: '+923001234567',
    isTechnician: false,
    firstName: 'Ali',
    lastName: 'Raza',
  );

  setUpAll(() {
    registerFallbackValue(tModel);
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    secureStorage = _MockSecureStorage();
    repo = ProfileRepositoryImpl(
      remote: remote,
      local: local,
      secureStorage: secureStorage,
    );

    // Default: token is present and the cache write succeeds.
    when(() => secureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => tToken);
    when(() => local.cacheProfile(any())).thenAnswer((_) async {});
  });

  // -------------------------------------------------------------------------
  // getMe
  // -------------------------------------------------------------------------

  group('getMe', () {
    test('returns entity and caches on remote success', () async {
      when(() => remote.getMe(tToken)).thenAnswer((_) async => tModel);

      final result = await repo.getMe();

      expect(result.id, 17);
      expect(result.firstName, 'Ali');
      expect(result.lastName, 'Raza');
      verify(() => local.cacheProfile(tModel)).called(1);
    });

    test('falls back to cache on SocketException', () async {
      when(() => remote.getMe(tToken)).thenThrow(const SocketException('offline'));
      when(() => local.getCachedProfile()).thenReturn(tModel);

      final result = await repo.getMe();

      expect(result.firstName, 'Ali');
      // Cache was NOT re-written on the offline path — only successful
      // remote responses refresh the cache.
      verifyNever(() => local.cacheProfile(any()));
    });

    test('throws NetworkFailure when offline and cache empty', () async {
      when(() => remote.getMe(tToken)).thenThrow(const SocketException('offline'));
      when(() => local.getCachedProfile()).thenReturn(null);

      expect(repo.getMe(), throwsA(isA<ProfileNetworkFailure>()));
    });

    test('throws UnauthorizedFailure on token missing', () async {
      when(() => secureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      expect(repo.getMe(), throwsA(isA<ProfileUnauthorizedFailure>()));
      verifyNever(() => remote.getMe(any()));
    });

    test('maps 401 HttpFailure to UnauthorizedFailure', () async {
      when(() => remote.getMe(tToken)).thenThrow(
        const HttpFailure(
          statusCode: 401,
          code: 'unauthorized',
          message: 'Unauthorized.',
        ),
      );

      expect(repo.getMe(), throwsA(isA<ProfileUnauthorizedFailure>()));
    });

    test('maps 400 HttpFailure to ServerFailure carrying errors map', () async {
      when(() => remote.getMe(tToken)).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Invalid input data.',
          errors: {'first_name': ['This field may not be blank.']},
        ),
      );

      try {
        await repo.getMe();
        fail('expected throw');
      } on ProfileServerFailure catch (e) {
        expect(e.message, 'Invalid input data.');
        expect(e.errors['first_name'], isA<List<dynamic>>());
      }
    });
  });

  // -------------------------------------------------------------------------
  // updateMe
  // -------------------------------------------------------------------------

  group('updateMe', () {
    const tUpdated = CustomerProfileModel(
      id: 17,
      phone: '+923001234567',
      isTechnician: false,
      firstName: 'Hamza',
      lastName: 'Khan',
    );

    test('returns post-update entity and refreshes cache', () async {
      when(() => remote.updateMe(
            token: tToken,
            firstName: 'Hamza',
            lastName: 'Khan',
          )).thenAnswer((_) async => tUpdated);

      final result =
          await repo.updateMe(firstName: 'Hamza', lastName: 'Khan');

      expect(result.firstName, 'Hamza');
      expect(result.lastName, 'Khan');
      verify(() => local.cacheProfile(tUpdated)).called(1);
    });

    test('maps 400 ServerFailure carries field errors for the FE', () async {
      when(() => remote.updateMe(
            token: any(named: 'token'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Invalid input data.',
          errors: {'last_name': ['This field may not be blank.']},
        ),
      );

      try {
        await repo.updateMe(firstName: 'Hamza', lastName: '');
        fail('expected throw');
      } on ProfileServerFailure catch (e) {
        expect(e.errors['last_name'], isA<List<dynamic>>());
      }
    });

    test('SocketException on mutation surfaces NetworkFailure', () async {
      when(() => remote.updateMe(
            token: any(named: 'token'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
          )).thenThrow(const SocketException('offline'));

      expect(
        repo.updateMe(firstName: 'X', lastName: 'Y'),
        throwsA(isA<ProfileNetworkFailure>()),
      );
      // Mutations are NOT write-through — cache stays untouched.
      verifyNever(() => local.cacheProfile(any()));
    });
  });
}

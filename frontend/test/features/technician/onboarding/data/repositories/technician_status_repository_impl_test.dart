import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/onboarding/data/data_sources/technician_status_remote_data_source.dart';
import 'package:frontend/features/technician/onboarding/data/models/technician_status_model.dart';
import 'package:frontend/features/technician/onboarding/data/repositories/technician_status_repository_impl.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/technician_status.dart';
import 'package:frontend/features/technician/onboarding/domain/failures/tech_status_failure.dart';

class MockRemoteDataSource extends Mock implements TechnicianStatusRemoteDataSource {}

void main() {
  late TechnicianStatusRepositoryImpl repository;
  late MockRemoteDataSource remote;

  setUp(() {
    remote = MockRemoteDataSource();
    repository = TechnicianStatusRepositoryImpl(remote);
  });

  group('TechnicianStatusRepositoryImpl.getMyStatus — happy paths', () {
    test('NoProfile wire model → TechnicianStatusNoProfile entity', () async {
      when(() => remote.getMyStatus()).thenAnswer(
        (_) async => const TechnicianStatusModel(
          hasProfile: false,
          status: null,
          rejectionReason: null,
        ),
      );

      final result = await repository.getMyStatus();
      expect(result, isA<TechnicianStatusNoProfile>());
    });

    test('Rejected wire model → TechnicianStatusRejected entity with reason', () async {
      when(() => remote.getMyStatus()).thenAnswer(
        (_) async => const TechnicianStatusModel(
          hasProfile: true,
          status: 'REJECTED',
          rejectionReason: 'Document blurry.',
        ),
      );

      final result = await repository.getMyStatus();
      expect(result, isA<TechnicianStatusRejected>());
      expect((result as TechnicianStatusRejected).reason, 'Document blurry.');
    });
  });

  group('TechnicianStatusRepositoryImpl.getMyStatus — error pipeline', () {
    test('HttpFailure(401) → TechStatusUnauthorized', () async {
      when(() => remote.getMyStatus()).thenThrow(
        HttpFailure(statusCode: 401, code: 'not_authenticated', message: 'gone'),
      );

      await expectLater(
        repository.getMyStatus(),
        throwsA(isA<TechStatusUnauthorized>()),
      );
    });

    test('HttpFailure with code=not_authenticated (non-401 status) → TechStatusUnauthorized', () async {
      // Some misconfigured proxies return 403 with the DRF code. The repo
      // matches on either the status or the code so the router still
      // routes through Unauthorized.
      when(() => remote.getMyStatus()).thenThrow(
        HttpFailure(statusCode: 403, code: 'not_authenticated', message: 'gone'),
      );

      await expectLater(
        repository.getMyStatus(),
        throwsA(isA<TechStatusUnauthorized>()),
      );
    });

    test('HttpFailure(500) → TechStatusServerFailure carrying the wire message', () async {
      when(() => remote.getMyStatus()).thenThrow(
        HttpFailure(statusCode: 500, code: 'server_error', message: 'boom'),
      );

      await expectLater(
        repository.getMyStatus(),
        throwsA(isA<TechStatusServerFailure>()
            .having((e) => e.message, 'message', 'boom')),
      );
    });

    test('SocketException → TechStatusNetworkFailure', () async {
      when(() => remote.getMyStatus()).thenThrow(const SocketException('no net'));

      await expectLater(
        repository.getMyStatus(),
        throwsA(isA<TechStatusNetworkFailure>()),
      );
    });

    test('FormatException → TechStatusServerFailure', () async {
      // Server returned HTML instead of JSON — the data source might let
      // a FormatException escape if the success-path body is malformed.
      when(() => remote.getMyStatus()).thenThrow(const FormatException('bad json'));

      await expectLater(
        repository.getMyStatus(),
        throwsA(isA<TechStatusServerFailure>()),
      );
    });
  });
}

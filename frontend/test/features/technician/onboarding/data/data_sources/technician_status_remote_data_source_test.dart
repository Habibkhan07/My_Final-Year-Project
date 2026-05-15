import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:frontend/features/technician/onboarding/data/data_sources/technician_status_remote_data_source.dart';
import 'package:frontend/features/technician/onboarding/data/models/technician_status_model.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late TechnicianStatusRemoteDataSource dataSource;
  late MockHttpClient client;
  late MockAuthLocalDataSource authLocalDataSource;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    client = MockHttpClient();
    authLocalDataSource = MockAuthLocalDataSource();
    dataSource = TechnicianStatusRemoteDataSource(
      authLocalDataSource,
      client: client,
    );
  });

  group('TechnicianStatusRemoteDataSource.getMyStatus', () {
    test('throws 401 HttpFailure when token is null, without hitting the network', () async {
      when(() => authLocalDataSource.getToken()).thenAnswer((_) async => null);

      await expectLater(
        dataSource.getMyStatus(),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.code, 'code', 'not_authenticated')),
      );

      verifyNever(() => client.get(any(), headers: any(named: 'headers')));
    });

    test('throws 401 HttpFailure when token is empty string', () async {
      when(() => authLocalDataSource.getToken()).thenAnswer((_) async => '');

      await expectLater(
        dataSource.getMyStatus(),
        throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'not_authenticated')),
      );

      verifyNever(() => client.get(any(), headers: any(named: 'headers')));
    });

    test('returns parsed model on 200 OK', () async {
      when(() => authLocalDataSource.getToken()).thenAnswer((_) async => 'tok');
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'has_profile': true,
            'status': 'PENDING',
            'status_display': 'Pending Approval',
            'rejection_reason': null,
            'submitted_at': null,
          }),
          200,
        ),
      );

      final result = await dataSource.getMyStatus();

      expect(result, isA<TechnicianStatusModel>());
      expect(result.status, 'PENDING');
    });

    test('sends the Token auth header', () async {
      when(() => authLocalDataSource.getToken()).thenAnswer((_) async => 'tok_42');
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'has_profile': false}),
          200,
        ),
      );

      await dataSource.getMyStatus();

      final captured = verify(
        () => client.get(any(), headers: captureAny(named: 'headers')),
      ).captured.single as Map<String, String>;
      expect(captured['Authorization'], 'Token tok_42');
    });

    test('throws HttpFailure(401, not_authenticated) on a 401 envelope response', () async {
      when(() => authLocalDataSource.getToken()).thenAnswer((_) async => 'tok');
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'status': 401,
            'code': 'not_authenticated',
            'message': 'Invalid token.',
            'errors': {},
          }),
          401,
        ),
      );

      await expectLater(
        dataSource.getMyStatus(),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.code, 'code', 'not_authenticated')),
      );
    });

    test('throws HttpFailure(500, server_error) when response body is not JSON', () async {
      when(() => authLocalDataSource.getToken()).thenAnswer((_) async => 'tok');
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response('<html>500 Server Error</html>', 500),
      );

      await expectLater(
        dataSource.getMyStatus(),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.code, 'code', 'server_error')),
      );
    });

    test('throws SocketException when the request exceeds the 10s timeout', () async {
      when(() => authLocalDataSource.getToken()).thenAnswer((_) async => 'tok');
      // Return a future that never completes. The DS internally caps it
      // at 10s via `.timeout(...)` — fake-async fast-forwards past it.
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) => Completer<http.Response>().future,
      );

      await expectLater(
        dataSource.getMyStatus().timeout(
          // Test-side hard cap so an actual hang here surfaces as a test
          // failure rather than the suite timeout. The DS's own 10s
          // timeout fires first in the happy path.
          const Duration(seconds: 12),
        ),
        throwsA(isA<SocketException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}

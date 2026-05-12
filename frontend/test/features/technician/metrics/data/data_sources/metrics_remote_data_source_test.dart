import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:frontend/features/technician/metrics/data/data_sources/metrics_remote_data_source.dart';
import 'package:frontend/features/technician/metrics/data/models/technician_metrics_model.dart';

class _MockHttpClient extends Mock implements http.Client {}
class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MetricsRemoteDataSource dataSource;
  late _MockHttpClient mockClient;
  late _MockAuthLocalDataSource mockAuth;

  setUp(() {
    mockClient = _MockHttpClient();
    mockAuth = _MockAuthLocalDataSource();
    dataSource = MetricsRemoteDataSource(
      client: mockClient,
      authLocalDataSource: mockAuth,
    );
    registerFallbackValue(Uri());
  });

  final happyBody = jsonEncode({
    'jobs_completed_today': 2,
    'cash_collected_today': 3500.0,
    'commission_deducted_today': 700.0,
    'jobs_completed_this_week': 8,
    'cash_collected_this_week': 15000.0,
  });

  group('getMetrics', () {
    test('200 → parses into TechnicianMetricsModel', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 'tok');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(happyBody, 200));

      final result = await dataSource.getMetrics();

      expect(result, isA<TechnicianMetricsModel>());
      expect(result.jobsCompletedToday, 2);
      expect(result.cashCollectedToday, 3500.0);
      expect(result.commissionDeductedToday, 700.0);
      expect(result.jobsCompletedThisWeek, 8);
      expect(result.cashCollectedThisWeek, 15000.0);
    });

    test('sends Authorization header when token present', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 'abc');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(happyBody, 200));

      await dataSource.getMetrics();

      final captured = verify(
        () => mockClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      expect(captured.last, containsPair('Authorization', 'Token abc'));
    });

    test('401 → throws HttpFailure with permission_denied code', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => null);
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({'code': 'permission_denied', 'message': 'No'}),
                401,
              ));

      await expectLater(
        dataSource.getMetrics(),
        throwsA(
          isA<HttpFailure>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.code, 'code', 'permission_denied'),
        ),
      );
    });

    test('500 → throws HttpFailure server_error', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('boom', 500));

      await expectLater(
        dataSource.getMetrics(),
        throwsA(isA<HttpFailure>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('SocketException propagates to repository layer', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('offline'));

      await expectLater(dataSource.getMetrics(), throwsA(isA<SocketException>()));
    });
  });
}

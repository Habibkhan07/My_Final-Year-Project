import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:frontend/features/technician/metrics/data/data_sources/metrics_remote_data_source.dart';
import 'package:frontend/features/technician/metrics/data/models/technician_metrics_model.dart';
import 'package:frontend/features/technician/metrics/domain/entities/technician_metrics_entity.dart';

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

  final weekBody = jsonEncode({
    'period': 'week',
    'total_jobs': 8,
    'total_cash': 15000.0,
    'buckets': [
      {'label': 'Mon', 'jobs': 2, 'cash': 4500.0},
      {'label': 'Tue', 'jobs': 1, 'cash': 2000.0},
      {'label': 'Wed', 'jobs': 0, 'cash': 0.0},
      {'label': 'Thu', 'jobs': 3, 'cash': 5500.0},
      {'label': 'Fri', 'jobs': 2, 'cash': 3000.0},
      {'label': 'Sat', 'jobs': 0, 'cash': 0.0},
      {'label': 'Sun', 'jobs': 0, 'cash': 0.0},
    ],
  });

  group('getMetrics', () {
    test('200 → parses into TechnicianMetricsModel with buckets', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 'tok');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(weekBody, 200));

      final result = await dataSource.getMetrics(MetricsPeriod.week);

      expect(result, isA<TechnicianMetricsModel>());
      expect(result.period, 'week');
      expect(result.totalJobs, 8);
      expect(result.totalCash, 15000.0);
      expect(result.buckets.length, 7);
      expect(result.buckets.first.label, 'Mon');
      expect(result.buckets.first.cash, 4500.0);
    });

    test('appends ?period= to the URL', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(weekBody, 200));

      await dataSource.getMetrics(MetricsPeriod.month);

      final captured = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters['period'], 'month');
    });

    test('sends Authorization header when token present', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 'abc');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(weekBody, 200));

      await dataSource.getMetrics(MetricsPeriod.week);

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
        dataSource.getMetrics(MetricsPeriod.week),
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
        dataSource.getMetrics(MetricsPeriod.week),
        throwsA(isA<HttpFailure>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('SocketException propagates to repository layer', () async {
      when(() => mockAuth.getToken()).thenAnswer((_) async => 't');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('offline'));

      await expectLater(
        dataSource.getMetrics(MetricsPeriod.week),
        throwsA(isA<SocketException>()),
      );
    });
  });
}

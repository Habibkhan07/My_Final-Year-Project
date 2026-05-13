import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/metrics/data/data_sources/metrics_remote_data_source.dart';
import 'package:frontend/features/technician/metrics/data/models/technician_metrics_model.dart';
import 'package:frontend/features/technician/metrics/data/repositories/metrics_repository_impl.dart';
import 'package:frontend/features/technician/metrics/domain/entities/technician_metrics_entity.dart';
import 'package:frontend/features/technician/metrics/domain/failures/metrics_failure.dart';

class _MockRemoteDataSource extends Mock implements IMetricsRemoteDataSource {}

const _happyModel = TechnicianMetricsModel(
  period: 'week',
  totalJobs: 8,
  totalCash: 15000.0,
  buckets: [
    MetricsBucketModel(label: 'Mon', jobs: 2, cash: 4500.0),
    MetricsBucketModel(label: 'Tue', jobs: 1, cash: 2000.0),
  ],
);

void main() {
  late MetricsRepositoryImpl repo;
  late _MockRemoteDataSource mockRemote;

  setUpAll(() {
    registerFallbackValue(MetricsPeriod.week);
  });

  setUp(() {
    mockRemote = _MockRemoteDataSource();
    repo = MetricsRepositoryImpl(remoteDataSource: mockRemote);
  });

  test('happy path → TechnicianMetricsEntity with correct values', () async {
    when(() => mockRemote.getMetrics(MetricsPeriod.week))
        .thenAnswer((_) async => _happyModel);

    final entity = await repo.getMetrics(MetricsPeriod.week);

    expect(entity.period, MetricsPeriod.week);
    expect(entity.totalJobs, 8);
    expect(entity.totalCash, 15000.0);
    expect(entity.buckets.length, 2);
    expect(entity.buckets.first.label, 'Mon');
    expect(entity.buckets.first.cash, 4500.0);
  });

  test('HttpFailure 401 → MetricsPermissionFailure', () async {
    when(() => mockRemote.getMetrics(any())).thenThrow(
      const HttpFailure(statusCode: 401, code: 'permission_denied', message: 'No'),
    );

    await expectLater(
      repo.getMetrics(MetricsPeriod.week),
      throwsA(isA<MetricsPermissionFailure>()),
    );
  });

  test('HttpFailure 403 → MetricsPermissionFailure', () async {
    when(() => mockRemote.getMetrics(any())).thenThrow(
      const HttpFailure(statusCode: 403, code: 'forbidden', message: 'No'),
    );

    await expectLater(
      repo.getMetrics(MetricsPeriod.week),
      throwsA(isA<MetricsPermissionFailure>()),
    );
  });

  test('HttpFailure 500 → MetricsServerFailure', () async {
    when(() => mockRemote.getMetrics(any())).thenThrow(
      const HttpFailure(statusCode: 500, code: 'server_error', message: 'oops'),
    );

    await expectLater(
      repo.getMetrics(MetricsPeriod.week),
      throwsA(isA<MetricsServerFailure>()),
    );
  });

  test('SocketException → MetricsNetworkFailure', () async {
    when(() => mockRemote.getMetrics(any()))
        .thenThrow(const SocketException('offline'));

    await expectLater(
      repo.getMetrics(MetricsPeriod.week),
      throwsA(isA<MetricsNetworkFailure>()),
    );
  });

  test('FormatException → MetricsServerFailure', () async {
    when(() => mockRemote.getMetrics(any()))
        .thenThrow(const FormatException('bad json'));

    await expectLater(
      repo.getMetrics(MetricsPeriod.week),
      throwsA(isA<MetricsServerFailure>()),
    );
  });
}

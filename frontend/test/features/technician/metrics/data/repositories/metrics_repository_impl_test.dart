import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/metrics/data/data_sources/metrics_remote_data_source.dart';
import 'package:frontend/features/technician/metrics/data/models/technician_metrics_model.dart';
import 'package:frontend/features/technician/metrics/data/repositories/metrics_repository_impl.dart';
import 'package:frontend/features/technician/metrics/domain/failures/metrics_failure.dart';

class _MockRemoteDataSource extends Mock implements IMetricsRemoteDataSource {}

const _happyModel = TechnicianMetricsModel(
  jobsCompletedToday: 2,
  cashCollectedToday: 3500.0,
  commissionDeductedToday: 700.0,
  jobsCompletedThisWeek: 8,
  cashCollectedThisWeek: 15000.0,
);

void main() {
  late MetricsRepositoryImpl repo;
  late _MockRemoteDataSource mockRemote;

  setUp(() {
    mockRemote = _MockRemoteDataSource();
    repo = MetricsRepositoryImpl(remoteDataSource: mockRemote);
  });

  test('happy path → TechnicianMetricsEntity with correct values', () async {
    when(() => mockRemote.getMetrics()).thenAnswer((_) async => _happyModel);

    final entity = await repo.getMetrics();

    expect(entity.jobsCompletedToday, 2);
    expect(entity.cashCollectedToday, 3500.0);
    expect(entity.commissionDeductedToday, 700.0);
    expect(entity.jobsCompletedThisWeek, 8);
    expect(entity.cashCollectedThisWeek, 15000.0);
  });

  test('HttpFailure 401 → MetricsPermissionFailure', () async {
    when(() => mockRemote.getMetrics()).thenThrow(
      const HttpFailure(statusCode: 401, code: 'permission_denied', message: 'No'),
    );

    await expectLater(repo.getMetrics(), throwsA(isA<MetricsPermissionFailure>()));
  });

  test('HttpFailure 403 → MetricsPermissionFailure', () async {
    when(() => mockRemote.getMetrics()).thenThrow(
      const HttpFailure(statusCode: 403, code: 'forbidden', message: 'No'),
    );

    await expectLater(repo.getMetrics(), throwsA(isA<MetricsPermissionFailure>()));
  });

  test('HttpFailure 500 → MetricsServerFailure', () async {
    when(() => mockRemote.getMetrics()).thenThrow(
      const HttpFailure(statusCode: 500, code: 'server_error', message: 'oops'),
    );

    await expectLater(repo.getMetrics(), throwsA(isA<MetricsServerFailure>()));
  });

  test('SocketException → MetricsNetworkFailure', () async {
    when(() => mockRemote.getMetrics())
        .thenThrow(const SocketException('offline'));

    await expectLater(repo.getMetrics(), throwsA(isA<MetricsNetworkFailure>()));
  });

  test('FormatException → MetricsServerFailure', () async {
    when(() => mockRemote.getMetrics())
        .thenThrow(const FormatException('bad json'));

    await expectLater(repo.getMetrics(), throwsA(isA<MetricsServerFailure>()));
  });
}

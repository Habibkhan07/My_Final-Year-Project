import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/dashboard/data/data_sources/technician_dashboard_local_data_source.dart';
import 'package:frontend/features/technician/dashboard/data/data_sources/technician_dashboard_remote_data_source.dart';
import 'package:frontend/features/technician/dashboard/data/models/technician_dashboard_model.dart';
import 'package:frontend/features/technician/dashboard/data/repositories/technician_dashboard_repository_impl.dart';
import 'package:frontend/features/technician/dashboard/domain/failures/technician_dashboard_failure.dart';

class MockRemoteDataSource extends Mock
    implements ITechnicianDashboardRemoteDataSource {}

class MockLocalDataSource extends Mock
    implements TechnicianDashboardLocalDataSource {}

class FakeTechnicianDashboardModel extends Fake
    implements TechnicianDashboardModel {}

void main() {
  late TechnicianDashboardRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(FakeTechnicianDashboardModel());
  });

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    repository = TechnicianDashboardRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  const tDashboardModel = TechnicianDashboardModel(
    walletBalance: 1200.0,
    isOnline: true,
    profilePicture: 'https://example.com/pic.jpg',
    upNextJob: null,
    laterTodayJobs: [],
    metrics: DashboardMetricsModel(
      jobsCompletedToday: 5,
      cashCollectedToday: 5000.0,
    ),
  );

  final tDashboardEntity = tDashboardModel.toEntity();

  group('getDashboard', () {
    test(
      'should return remote data and cache it when remote call is successful',
      () async {
        when(
          () => mockRemoteDataSource.getDashboard(),
        ).thenAnswer((_) async => tDashboardModel);
        when(
          () => mockLocalDataSource.cacheDashboard(any()),
        ).thenAnswer((_) async => {});

        final result = await repository.getDashboard();

        verify(() => mockRemoteDataSource.getDashboard());
        verify(() => mockLocalDataSource.cacheDashboard(tDashboardModel));
        expect(result, equals(tDashboardEntity));
      },
    );

    test(
      'should throw DashboardNetworkFailure on SocketException EVEN IF cache exists '
      '(financial-truth fields walletBalance/cashCollectedToday must not be '
      'served from cache — see repository docstring)',
      () async {
        when(
          () => mockRemoteDataSource.getDashboard(),
        ).thenThrow(const SocketException('No Internet'));
        when(
          () => mockLocalDataSource.getCachedDashboard(),
        ).thenAnswer((_) async => tDashboardModel);

        expect(
          () => repository.getDashboard(),
          throwsA(isA<DashboardNetworkFailure>()),
        );
      },
    );

    test(
      'should throw DashboardNetworkFailure when remote fails and cache is empty',
      () async {
        when(
          () => mockRemoteDataSource.getDashboard(),
        ).thenThrow(const SocketException('No Internet'));
        when(
          () => mockLocalDataSource.getCachedDashboard(),
        ).thenAnswer((_) async => null);

        final call = repository.getDashboard();

        expect(() => call, throwsA(isA<DashboardNetworkFailure>()));
      },
    );

    test(
      'should throw DashboardPermissionFailure when remote returns 403',
      () async {
        when(() => mockRemoteDataSource.getDashboard()).thenThrow(
          const HttpFailure(
            statusCode: 403,
            code: 'permission_denied',
            message: 'Forbidden',
          ),
        );

        final call = repository.getDashboard();

        expect(() => call, throwsA(isA<DashboardPermissionFailure>()));
      },
    );

    test(
      'should throw DashboardServerFailure when remote returns other HttpFailure',
      () async {
        when(() => mockRemoteDataSource.getDashboard()).thenThrow(
          const HttpFailure(
            statusCode: 500,
            code: 'server_error',
            message: 'Server error',
          ),
        );

        final call = repository.getDashboard();

        expect(() => call, throwsA(isA<DashboardServerFailure>()));
      },
    );
  });
}

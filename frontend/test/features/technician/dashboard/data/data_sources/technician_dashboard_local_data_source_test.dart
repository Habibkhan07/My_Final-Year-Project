import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/technician/dashboard/data/data_sources/technician_dashboard_local_data_source.dart';
import 'package:frontend/features/technician/dashboard/data/models/technician_dashboard_model.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late TechnicianDashboardLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    dataSource = TechnicianDashboardLocalDataSourceImpl(mockSharedPreferences);
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

  group('cacheDashboard', () {
    test('should call SharedPreferences to cache the data', () async {
      when(() => mockSharedPreferences.setString(any(), any()))
          .thenAnswer((_) async => true);

      await dataSource.cacheDashboard(tDashboardModel);

      final expectedJsonString = jsonEncode(tDashboardModel.toJson());
      verify(() => mockSharedPreferences.setString(
            'CACHED_TECHNICIAN_DASHBOARD',
            expectedJsonString,
          )).called(1);
    });
  });

  group('getCachedDashboard', () {
    test('should return TechnicianDashboardModel from SharedPreferences when it is in cache',
        () async {
      final jsonString = jsonEncode(tDashboardModel.toJson());
      when(() => mockSharedPreferences.getString(any())).thenReturn(jsonString);

      final result = await dataSource.getCachedDashboard();

      verify(() => mockSharedPreferences.getString('CACHED_TECHNICIAN_DASHBOARD'));
      expect(result, equals(tDashboardModel));
    });
  });
}

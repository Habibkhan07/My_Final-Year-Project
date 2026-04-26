import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/dashboard/data/data_sources/technician_dashboard_remote_data_source.dart';
import 'package:frontend/features/technician/dashboard/data/models/technician_dashboard_model.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late TechnicianDashboardRemoteDataSource dataSource;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = TechnicianDashboardRemoteDataSource(client: mockHttpClient);
    registerFallbackValue(Uri());
  });

  final tDashboardJson = {
    'wallet_balance': 1200.0,
    'is_online': true,
    'profile_picture': 'https://example.com/pic.jpg',
    'up_next_job': null,
    'later_today_jobs': [],
    'metrics': {
      'jobs_completed_today': 5,
      'cash_collected_today': 5000.0,
    },
  };

  group('getDashboard', () {
    test('should perform a GET request on the correct URL', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(tDashboardJson), 200),
      );

      await dataSource.getDashboard();

      verify(() => mockHttpClient.get(
            Uri.parse('http://127.0.0.1:8000/api/technicians/dashboard/'),
          )).called(1);
    });

    test('should return TechnicianDashboardModel when the response code is 200', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(tDashboardJson), 200),
      );

      final result = await dataSource.getDashboard();

      expect(result, isA<TechnicianDashboardModel>());
      expect(result.walletBalance, 1200.0);
    });

    test('should throw HttpFailure when the response code is 404', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode({'message': 'Not Found'}), 404),
      );

      final call = dataSource.getDashboard();

      expect(() => call, throwsA(isA<HttpFailure>()));
    });
  });
}

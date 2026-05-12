import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/dashboard/data/models/technician_dashboard_model.dart';
import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';

void main() {
  final tScheduledTime = DateTime(2026, 4, 26, 10, 0);

  final tUpNextJobModel = UpNextJobModel(
    jobId: 1,
    serviceTitle: 'AC Repair',
    customerName: 'Hamayon Khan',
    customerPhone: '+923001234567',
    scheduledTime: tScheduledTime,
    addressText: 'Street 1, Islamabad',
    lat: 33.6844,
    lng: 73.0479,
  );

  final tLaterTodayJobModel = LaterTodayJobModel(
    jobId: 2,
    serviceTitle: 'Electrician',
    scheduledTime: tScheduledTime.add(const Duration(hours: 4)),
    addressText: 'Street 2, Islamabad',
  );

  final tDashboardModel = TechnicianDashboardModel(
    walletBalance: 1200.0,
    isOnline: true,
    profilePicture: 'https://example.com/pic.jpg',
    upNextJob: tUpNextJobModel,
    laterTodayJobs: [tLaterTodayJobModel],
  );

  final tDashboardJson = {
    'wallet_balance': 1200.0,
    'is_online': true,
    'profile_picture': 'https://example.com/pic.jpg',
    'up_next_job': {
      'job_id': 1,
      'service_title': 'AC Repair',
      'customer_name': 'Hamayon Khan',
      'customer_phone': '+923001234567',
      'scheduled_time': tScheduledTime.toIso8601String(),
      'address_text': 'Street 1, Islamabad',
      'lat': 33.6844,
      'lng': 73.0479,
    },
    'later_today_jobs': [
      {
        'job_id': 2,
        'service_title': 'Electrician',
        'scheduled_time': tScheduledTime
            .add(const Duration(hours: 4))
            .toIso8601String(),
        'address_text': 'Street 2, Islamabad',
      },
    ],
  };

  group('fromJson', () {
    test('should return a valid model when JSON is provided', () {
      final result = TechnicianDashboardModel.fromJson(tDashboardJson);
      expect(result.walletBalance, 1200.0);
      expect(result.upNextJob?.serviceTitle, 'AC Repair');
      expect(result.upNextJob?.customerPhone, '+923001234567');
      expect(result.laterTodayJobs.length, 1);
    });

    test('should parse null customer_phone for legacy users', () {
      final json = Map<String, dynamic>.from(tDashboardJson);
      json['up_next_job'] = {
        ...Map<String, dynamic>.from(tDashboardJson['up_next_job'] as Map),
        'customer_phone': null,
      };
      final result = TechnicianDashboardModel.fromJson(json);
      expect(result.upNextJob?.customerPhone, isNull);
    });

    test('should handle null up_next_job', () {
      final json = Map<String, dynamic>.from(tDashboardJson);
      json['up_next_job'] = null;

      final result = TechnicianDashboardModel.fromJson(json);
      expect(result.upNextJob, isNull);
    });
  });

  group('toEntity', () {
    test('should map model to domain entity correctly', () {
      final result = tDashboardModel.toEntity();

      expect(result, isA<TechnicianDashboardEntity>());
      expect(result.walletBalance, 1200.0);
      expect(result.upNextJob, isA<UpNextJobEntity>());
      expect(result.upNextJob?.serviceTitle, 'AC Repair');
      expect(result.laterTodayJobs.first.serviceTitle, 'Electrician');
    });

    test('should handle null upNextJob in toEntity', () {
      final model = TechnicianDashboardModel(
        walletBalance: 1200.0,
        isOnline: true,
        profilePicture: null,
        upNextJob: null,
        laterTodayJobs: [],
      );

      final result = model.toEntity();
      expect(result.upNextJob, isNull);
    });
  });
}

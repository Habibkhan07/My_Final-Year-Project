import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';

void main() {
  group('TechnicianDashboardEntity', () {
    test('should support equality comparison', () {
      final entity1 = TechnicianDashboardEntity(
        walletBalance: 500.0,
        isOnline: true,
        profilePicture: 'url',
        upNextJob: null,
        laterTodayJobs: [],
      );

      final entity2 = TechnicianDashboardEntity(
        walletBalance: 500.0,
        isOnline: true,
        profilePicture: 'url',
        upNextJob: null,
        laterTodayJobs: [],
      );

      expect(entity1, equals(entity2));
    });

    test('should have nested equality for jobs', () {
      final tTime = DateTime(2026, 4, 26);
      final job1 = LaterTodayJobEntity(
        jobId: 1,
        serviceTitle: 'A',
        scheduledTime: tTime,
        addressText: 'Addr',
      );
      final job2 = LaterTodayJobEntity(
        jobId: 1,
        serviceTitle: 'A',
        scheduledTime: tTime,
        addressText: 'Addr',
      );

      expect(job1, equals(job2));
    });
  });
}

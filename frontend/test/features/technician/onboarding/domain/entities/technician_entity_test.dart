import 'package:flutter_test/flutter_test.dart';
// Import your entity
import 'package:frontend/features/technician/onboarding/domain/entities/technician_entity.dart';

void main() {
  group('TechnicianEntity (Domain Layer)', () {
    const tEntity1 = TechnicianEntity(
      profileId: 1,
      status: 'Pending',
      fullName: 'John Doe',
      joinedDate: '2025-02-14',
      experienceYears: 5,
    );

    const tEntity2 = TechnicianEntity(
      profileId: 1,
      status: 'Pending',
      fullName: 'John Doe',
      joinedDate: '2025-02-14',
      experienceYears: 5,
    );

    const tEntityDifferent = TechnicianEntity(
      profileId: 2,
      status: 'Approved',
      fullName: 'Jane Smith',
      joinedDate: '2025-01-01',
      experienceYears: 10,
    );

    test('VALUE EQUALITY: Should be equal when properties match', () {
      // Even though tEntity1 and tEntity2 are different instances in memory,
      // Equatable makes them equal based on their data
      expect(tEntity1, equals(tEntity2));
    });

    test('VALUE EQUALITY: Should NOT be equal when properties differ', () {
      expect(tEntity1, isNot(equals(tEntityDifferent)));
    });

    group('copyWith', () {
      test('Should return a NEW instance with updated status', () {
        // Act: Update only the status
        final result = tEntity1.copyWith(status: 'Approved');

        // Assert: New value is updated, others remain the same
        expect(result.status, 'Approved');
        expect(result.profileId, tEntity1.profileId);
        expect(result.fullName, tEntity1.fullName);
        expect(result.joinedDate, tEntity1.joinedDate);
        expect(result, isNot(equals(tEntity1)));
      });

      test('Should return a NEW instance with updated experienceYears', () {
        // Act: Update only experience
        final result = tEntity1.copyWith(experienceYears: 6);

        // Assert
        expect(result.experienceYears, 6);
        expect(result.status, tEntity1.status);
        expect(result.profileId, tEntity1.profileId);
      });

      test('Should return identical values if no arguments provided', () {
        // Act
        final result = tEntity1.copyWith();

        // Assert: Values should be the same
        expect(result, equals(tEntity1));
      });
    });

    test('PROPS: Should contain all fields in the props list', () {
      // This ensures that Equatable is checking EVERY field
      expect(tEntity1.props, [
        tEntity1.profileId,
        tEntity1.status,
        tEntity1.fullName,
        tEntity1.joinedDate,
        tEntity1.experienceYears,
      ]);
    });
  });
}

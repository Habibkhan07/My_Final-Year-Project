import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/onboarding/data/models/technician_status_model.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/technician_status.dart';

void main() {
  group('TechnicianStatusModel.fromJson', () {
    test('no-profile wire shape parses to hasProfile=false, all-null fields', () {
      final model = TechnicianStatusModel.fromJson({
        'has_profile': false,
        'status': null,
        'status_display': null,
        'rejection_reason': null,
        'submitted_at': null,
      });

      expect(model.hasProfile, isFalse);
      expect(model.status, isNull);
      expect(model.rejectionReason, isNull);
    });

    test('pending wire shape parses to hasProfile=true, status=PENDING, reason=null', () {
      final model = TechnicianStatusModel.fromJson({
        'has_profile': true,
        'status': 'PENDING',
        'status_display': 'Pending Approval',
        'rejection_reason': null,
        'submitted_at': null,
      });

      expect(model.hasProfile, isTrue);
      expect(model.status, 'PENDING');
      expect(model.rejectionReason, isNull);
    });

    test('approved wire shape parses to status=APPROVED, reason=null', () {
      final model = TechnicianStatusModel.fromJson({
        'has_profile': true,
        'status': 'APPROVED',
        'status_display': 'Approved',
        'rejection_reason': null,
        'submitted_at': null,
      });

      expect(model.status, 'APPROVED');
      expect(model.rejectionReason, isNull);
    });

    test('rejected wire shape carries the rejection reason', () {
      final model = TechnicianStatusModel.fromJson({
        'has_profile': true,
        'status': 'REJECTED',
        'status_display': 'Rejected',
        'rejection_reason': 'CNIC image was illegible.',
        'submitted_at': null,
      });

      expect(model.status, 'REJECTED');
      expect(model.rejectionReason, 'CNIC image was illegible.');
    });

    test('missing has_profile defaults to false (defensive)', () {
      final model = TechnicianStatusModel.fromJson({
        'status': 'PENDING',
      });

      expect(model.hasProfile, isFalse);
    });
  });

  group('TechnicianStatusModel.toEntity', () {
    test('hasProfile=false maps to TechnicianStatusNoProfile', () {
      const model = TechnicianStatusModel(
        hasProfile: false,
        status: null,
        rejectionReason: null,
      );

      expect(model.toEntity(), isA<TechnicianStatusNoProfile>());
    });

    test('PENDING wire string maps to TechnicianStatusPending', () {
      const model = TechnicianStatusModel(
        hasProfile: true,
        status: 'PENDING',
        rejectionReason: null,
      );

      expect(model.toEntity(), isA<TechnicianStatusPending>());
    });

    test('APPROVED wire string maps to TechnicianStatusApproved', () {
      const model = TechnicianStatusModel(
        hasProfile: true,
        status: 'APPROVED',
        rejectionReason: null,
      );

      expect(model.toEntity(), isA<TechnicianStatusApproved>());
    });

    test('REJECTED wire string maps to TechnicianStatusRejected with the reason', () {
      const model = TechnicianStatusModel(
        hasProfile: true,
        status: 'REJECTED',
        rejectionReason: 'Try again with a clearer photo.',
      );

      final entity = model.toEntity();
      expect(entity, isA<TechnicianStatusRejected>());
      expect(
        (entity as TechnicianStatusRejected).reason,
        'Try again with a clearer photo.',
      );
    });

    test('unknown wire status maps to NoProfile (safe-by-default)', () {
      // If the backend ships a new state ahead of the Flutter build, the
      // router defaults to the customer surface rather than mis-granting
      // tech access. Pinning this contract in a test so a future code
      // change cannot silently flip the fallback.
      const model = TechnicianStatusModel(
        hasProfile: true,
        status: 'SUSPENDED',
        rejectionReason: null,
      );

      expect(model.toEntity(), isA<TechnicianStatusNoProfile>());
    });
  });
}

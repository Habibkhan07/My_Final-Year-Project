import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/features/technician/incoming_job_requests/data/mappers/job_new_request_mapper.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/entities/booking_type.dart';

/// Builds a `job_new_request` `SystemEventEntity` for mapper tests.
SystemEventEntity _event({
  DateTime? timestamp,
  Map<String, dynamic>? payloadOverrides,
  Map<String, dynamic>? payloadRemovals,
}) {
  final base = <String, dynamic>{
    'job_id': 99482,
    'service_name': 'AC Deep Wash',
    'booking_type': 'FIXED_GIG',
    'scheduled_start_iso': '2026-04-08T05:00:00Z',
    'payout': '1200',
    'payout_context': 'Fixed-price gig — full payout',
    'expires_in_seconds': 60,
  };
  if (payloadOverrides != null) base.addAll(payloadOverrides);
  if (payloadRemovals != null) {
    for (final k in payloadRemovals.keys) {
      base.remove(k);
    }
  }
  return SystemEventEntity.fromComponents(
    id: 'evt-1',
    rawType: 'job_new_request',
    targetRoleStr: 'technician',
    timestamp: timestamp ?? DateTime.utc(2026, 4, 27, 20, 14, 42),
    payload: base,
  );
}

void main() {
  group('JobNewRequestMapper.fromSystemEvent', () {
    test('fresh event → typed entity with parsed payout, UTC scheduledStart, '
        'envelope-anchored expiresAt', () {
      final ts = DateTime.utc(2026, 4, 27, 20, 14, 42);
      final entity = JobNewRequestMapper.fromSystemEvent(_event(timestamp: ts));

      expect(entity, isNotNull);
      expect(entity!.jobId, 99482);
      expect(entity.serviceName, 'AC Deep Wash');
      expect(entity.bookingType, BookingType.fixedGig);
      expect(entity.payoutRupees, 1200);
      expect(entity.payoutContext, 'Fixed-price gig — full payout');
      expect(entity.scheduledStart, DateTime.utc(2026, 4, 8, 5, 0, 0));
      // Anchored on envelope timestamp, NOT receipt time. Critical for SLA
      // alignment with the server's Celery timeout task.
      expect(entity.expiresAt, ts.add(const Duration(seconds: 60)));
    });

    test('§2.5 replay (null booking_type) → defaults to BookingType.laborGig',
        () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadRemovals: const {'booking_type': null}),
      );

      expect(entity, isNotNull);
      expect(entity!.bookingType, BookingType.laborGig);
    });

    test('§2.5 replay (null payout_context) → entity carries null', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadRemovals: const {'payout_context': null}),
      );

      expect(entity, isNotNull);
      expect(entity!.payoutContext, isNull);
    });

    test('unknown booking_type string → defaults to laborGig (no throw)', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'booking_type': 'MYSTERY_GIG'}),
      );

      expect(entity, isNotNull);
      expect(entity!.bookingType, BookingType.laborGig);
    });

    test('inspection wire string → BookingType.inspection', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'booking_type': 'INSPECTION'}),
      );

      expect(entity, isNotNull);
      expect(entity!.bookingType, BookingType.inspection);
    });

    test('non-numeric payout → returns null (mapper logs, no throw)', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'payout': 'twelve hundred'}),
      );

      expect(entity, isNull);
    });

    test('unparseable scheduled_start_iso → returns null', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'scheduled_start_iso': 'not-a-date'}),
      );

      expect(entity, isNull);
    });

    test('missing required job_id → returns null (no throw)', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadRemovals: const {'job_id': null}),
      );

      expect(entity, isNull);
    });
  });
}

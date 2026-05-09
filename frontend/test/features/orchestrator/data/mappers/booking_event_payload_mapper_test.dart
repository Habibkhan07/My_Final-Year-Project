// Tests for `BookingEventPayloadMapper`.
//
// Regression vectors:
//   * extractJobId must accept int / num / numeric-string and return
//     null for anything else (defensive: a malformed event must not
//     crash the listener — the event is dropped and the screen stays
//     on its current data).
//   * extractChildBookingId must EARLY-OUT when the event type is not
//     bookingRescheduled (#B-9). A `tech_en_route` event with a
//     "child_booking_id" key by accident must not nav-replace the user.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/domain/entities/event_urgency.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_type.dart';
import 'package:frontend/core/realtime/domain/entities/target_role.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_event_payload_mapper.dart';

SystemEventEntity event({
  SystemEventType type = SystemEventType.techEnRoute,
  Map<String, dynamic> payload = const {},
}) =>
    SystemEventEntity(
      id: 'evt-${type.name}',
      rawType: type.name,
      eventType: type,
      targetRole: TargetRole.customer,
      timestamp: DateTime.utc(2026, 5, 9, 10, 0, 0),
      payload: payload,
      urgency: EventUrgency.lowUrgency,
      isCritical: false,
    );

void main() {
  group('extractJobId', () {
    test('returns int when payload.job_id is int', () {
      expect(
        BookingEventPayloadMapper.extractJobId(
          event(payload: {'job_id': 42}),
        ),
        42,
      );
    });

    test('coerces num (double) to int — JSON parsers may surface 42.0', () {
      expect(
        BookingEventPayloadMapper.extractJobId(
          event(payload: {'job_id': 42.0}),
        ),
        42,
      );
    });

    test('parses numeric string', () {
      expect(
        BookingEventPayloadMapper.extractJobId(
          event(payload: {'job_id': '42'}),
        ),
        42,
      );
    });

    test('returns null for non-numeric string', () {
      expect(
        BookingEventPayloadMapper.extractJobId(
          event(payload: {'job_id': 'not-a-number'}),
        ),
        isNull,
      );
    });

    test('returns null when key is missing', () {
      expect(
        BookingEventPayloadMapper.extractJobId(event(payload: const {})),
        isNull,
      );
    });

    test('returns null for unsupported type (bool, list, map)', () {
      expect(
        BookingEventPayloadMapper.extractJobId(
          event(payload: {'job_id': true}),
        ),
        isNull,
      );
      expect(
        BookingEventPayloadMapper.extractJobId(
          event(payload: {'job_id': [42]}),
        ),
        isNull,
      );
    });
  });

  group('extractChildBookingId', () {
    test(
        'returns child_booking_id for booking_rescheduled events',
        () {
      expect(
        BookingEventPayloadMapper.extractChildBookingId(
          event(
            type: SystemEventType.bookingRescheduled,
            payload: {'child_booking_id': 99},
          ),
        ),
        99,
      );
    });

    test(
        'EARLY-OUT: returns null when event type is not bookingRescheduled (#B-9)',
        () {
      // The contract: this helper must reject non-rescheduled events
      // even if their payload happens to contain a `child_booking_id`
      // key. A `tech_en_route` event with a stray child_booking_id
      // must NOT cause the rescheduled-notifier to pushReplacement.
      expect(
        BookingEventPayloadMapper.extractChildBookingId(
          event(
            type: SystemEventType.techEnRoute,
            payload: {'child_booking_id': 99},
          ),
        ),
        isNull,
      );
    });

    test('returns null when child_booking_id is missing', () {
      expect(
        BookingEventPayloadMapper.extractChildBookingId(
          event(
            type: SystemEventType.bookingRescheduled,
            payload: const {},
          ),
        ),
        isNull,
      );
    });

    test('coerces numeric-string child_booking_id', () {
      expect(
        BookingEventPayloadMapper.extractChildBookingId(
          event(
            type: SystemEventType.bookingRescheduled,
            payload: {'child_booking_id': '99'},
          ),
        ),
        99,
      );
    });

    test('returns null on non-numeric-string child_booking_id', () {
      expect(
        BookingEventPayloadMapper.extractChildBookingId(
          event(
            type: SystemEventType.bookingRescheduled,
            payload: {'child_booking_id': 'oops'},
          ),
        ),
        isNull,
      );
    });
  });
}

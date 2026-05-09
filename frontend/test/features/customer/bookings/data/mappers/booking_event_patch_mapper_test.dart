// Tests for BookingEventPatchMapper — the realtime list-patch
// (Option ii). Mirrors the server's status → ui table for two
// transitions:
//
//   - jobAccepted        → status=CONFIRMED  + positive tone + new headline
//   - bookingRejected    → status=REJECTED   + negative tone + reason-aware
//                          headline (technician_declined / sla_timeout)
//
// Drift between this mapper and the server's _resolve_ui_block is the
// only known cost of Option ii — these tests assert the literal copy
// the API doc commits to so a server-side change requires this file to
// be touched in lockstep.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/domain/entities/event_criticality.dart';
import 'package:frontend/core/realtime/domain/entities/event_urgency.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_type.dart';
import 'package:frontend/core/realtime/domain/entities/target_role.dart';
import 'package:frontend/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/customer/bookings/domain/entities/customer_booking.dart';

CustomerBooking _existingAwaiting({String techName = 'Ahmed Khan'}) {
  return CustomerBooking(
    id: 99482,
    status: BookingStatus.awaiting,
    service: const BookingService(name: 'AC Repair', iconName: 'ac_repair'),
    technician: BookingTechnician(
      id: 17,
      displayName: techName,
      profilePictureUrl: null,
    ),
    addressLabel: 'Home',
    scheduledStart: DateTime.utc(2026, 5, 6, 15, 0, 0),
    scheduledEnd: DateTime.utc(2026, 5, 6, 17, 0, 0),
    createdAt: DateTime.utc(2026, 5, 5, 9, 12, 0),
    price: const BookingPrice(
      amount: 2500,
      context: 'Fixed Price',
      uiLabel: 'Rs. 2,500',
    ),
    ui: BookingUi(
      badgeText: 'Awaiting tech',
      badgeTone: BookingUiTone.warning,
      headline: 'Waiting for $techName to confirm',
    ),
  );
}

SystemEventEntity _event({
  required SystemEventType type,
  required Map<String, dynamic> payload,
}) {
  // Use the wire constructor so derived fields (urgency / criticality)
  // are computed the same way they would be on real wire frames.
  final raw = switch (type) {
    SystemEventType.jobAccepted => 'job_accepted',
    SystemEventType.bookingRejected => 'booking_rejected',
    _ => 'unknown',
  };
  return SystemEventEntity(
    id: 'e-${type.name}',
    rawType: raw,
    eventType: type,
    targetRole: TargetRole.customer,
    timestamp: DateTime.utc(2026, 5, 6, 14, 0, 0),
    payload: payload,
    urgency: EventUrgency.of(type),
    isCritical: EventCriticality.isCritical(type),
  );
}

void main() {
  // ─── jobIdFromPayload ─────────────────────────────────────────────────

  group('jobIdFromPayload', () {
    test('int passes through', () {
      final id = BookingEventPatchMapper.jobIdFromPayload(
        _event(type: SystemEventType.jobAccepted, payload: {'job_id': 42}),
      );
      expect(id, 42);
    });

    test('numeric (double) coerces to int', () {
      final id = BookingEventPatchMapper.jobIdFromPayload(
        _event(type: SystemEventType.jobAccepted, payload: {'job_id': 42.0}),
      );
      expect(id, 42);
    });

    test('numeric string parses to int', () {
      final id = BookingEventPatchMapper.jobIdFromPayload(
        _event(type: SystemEventType.jobAccepted, payload: {'job_id': '42'}),
      );
      expect(id, 42);
    });

    test('non-numeric string returns null', () {
      final id = BookingEventPatchMapper.jobIdFromPayload(
        _event(
          type: SystemEventType.jobAccepted,
          payload: {'job_id': 'forty-two'},
        ),
      );
      expect(id, isNull);
    });

    test('missing key returns null', () {
      final id = BookingEventPatchMapper.jobIdFromPayload(
        _event(type: SystemEventType.jobAccepted, payload: const {}),
      );
      expect(id, isNull);
    });

    test('explicit null value returns null', () {
      final id = BookingEventPatchMapper.jobIdFromPayload(
        _event(type: SystemEventType.jobAccepted, payload: {'job_id': null}),
      );
      expect(id, isNull);
    });
  });

  // ─── applyJobAccepted ────────────────────────────────────────────────

  group('applyJobAccepted', () {
    test('flips status to confirmed, recomputes ui block + tech name', () {
      final patched = BookingEventPatchMapper.applyJobAccepted(
        _existingAwaiting(),
        _event(
          type: SystemEventType.jobAccepted,
          payload: const {
            'job_id': 99482,
            'technician_display_name': 'Ali Khan',
            'service_name': 'AC Repair',
          },
        ),
      );

      expect(patched.status, BookingStatus.confirmed);
      expect(patched.technician.displayName, 'Ali Khan');
      expect(patched.ui.badgeText, 'Confirmed');
      expect(patched.ui.badgeTone, BookingUiTone.positive);
      expect(patched.ui.headline, 'Confirmed with Ali Khan');
    });

    test('missing technician_display_name keeps existing name', () {
      final patched = BookingEventPatchMapper.applyJobAccepted(
        _existingAwaiting(techName: 'Original Name'),
        _event(
          type: SystemEventType.jobAccepted,
          payload: const {'job_id': 99482},
        ),
      );

      expect(patched.status, BookingStatus.confirmed);
      expect(patched.technician.displayName, 'Original Name');
      expect(patched.ui.headline, 'Confirmed with Original Name');
    });

    test('does not mutate non-status / non-technician fields', () {
      final original = _existingAwaiting();
      final patched = BookingEventPatchMapper.applyJobAccepted(
        original,
        _event(
          type: SystemEventType.jobAccepted,
          payload: const {
            'job_id': 99482,
            'technician_display_name': 'Same Person',
          },
        ),
      );

      // Service, address, schedule, price untouched.
      expect(patched.service, original.service);
      expect(patched.addressLabel, original.addressLabel);
      expect(patched.scheduledStart, original.scheduledStart);
      expect(patched.scheduledEnd, original.scheduledEnd);
      expect(patched.createdAt, original.createdAt);
      expect(patched.price, original.price);
    });
  });

  // ─── applyBookingRejected ────────────────────────────────────────────

  group('applyBookingRejected', () {
    test('reason=technician_declined → "Unavailable" + negative tone', () {
      final patched = BookingEventPatchMapper.applyBookingRejected(
        _existingAwaiting(techName: 'Ahmed Khan'),
        _event(
          type: SystemEventType.bookingRejected,
          payload: const {'job_id': 99482, 'reason': 'technician_declined'},
        ),
      );

      expect(patched.status, BookingStatus.rejected);
      expect(patched.ui.badgeText, 'Unavailable');
      expect(patched.ui.badgeTone, BookingUiTone.negative);
      expect(patched.ui.headline, "Ahmed Khan couldn't take this");
    });

    test(
      'reason=sla_timeout → "Timed out" + negative tone + tailored copy',
      () {
        final patched = BookingEventPatchMapper.applyBookingRejected(
          _existingAwaiting(techName: 'Ahmed Khan'),
          _event(
            type: SystemEventType.bookingRejected,
            payload: const {'job_id': 99482, 'reason': 'sla_timeout'},
          ),
        );

        expect(patched.status, BookingStatus.rejected);
        expect(patched.ui.badgeText, 'Timed out');
        expect(patched.ui.badgeTone, BookingUiTone.negative);
        expect(patched.ui.headline, "Ahmed Khan didn't respond in time");
      },
    );

    test('unknown reason → defaults to technician_declined copy', () {
      // Forward-compat: a future backend reason string must not crash
      // the mapper. The "Unavailable" copy is the safer default.
      final patched = BookingEventPatchMapper.applyBookingRejected(
        _existingAwaiting(techName: 'Ahmed Khan'),
        _event(
          type: SystemEventType.bookingRejected,
          payload: const {'job_id': 99482, 'reason': 'some_future_reason'},
        ),
      );
      expect(patched.ui.badgeText, 'Unavailable');
      expect(patched.ui.badgeTone, BookingUiTone.negative);
    });

    test('missing reason → defaults to technician_declined copy', () {
      // Legacy event with no reason field — must not crash; falls back
      // to the safer "Unavailable" copy.
      final patched = BookingEventPatchMapper.applyBookingRejected(
        _existingAwaiting(techName: 'Ahmed Khan'),
        _event(
          type: SystemEventType.bookingRejected,
          payload: const {'job_id': 99482},
        ),
      );
      expect(patched.ui.badgeText, 'Unavailable');
      expect(patched.ui.badgeTone, BookingUiTone.negative);
    });

    test('keeps existing technician — booking_rejected is the same tech', () {
      // The decline / timeout pathway is for the originally-assigned
      // tech; we should not blank or replace the technician block.
      final original = _existingAwaiting(techName: 'Ahmed Khan');
      final patched = BookingEventPatchMapper.applyBookingRejected(
        original,
        _event(
          type: SystemEventType.bookingRejected,
          payload: const {'job_id': 99482, 'reason': 'technician_declined'},
        ),
      );
      expect(patched.technician, original.technician);
    });

    test('does not mutate service / address / price / schedule', () {
      final original = _existingAwaiting();
      final patched = BookingEventPatchMapper.applyBookingRejected(
        original,
        _event(
          type: SystemEventType.bookingRejected,
          payload: const {'job_id': 99482, 'reason': 'sla_timeout'},
        ),
      );
      expect(patched.service, original.service);
      expect(patched.addressLabel, original.addressLabel);
      expect(patched.scheduledStart, original.scheduledStart);
      expect(patched.scheduledEnd, original.scheduledEnd);
      expect(patched.createdAt, original.createdAt);
      expect(patched.price, original.price);
    });
  });
}

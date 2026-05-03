import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/features/technician/incoming_job_requests/data/mappers/job_new_request_mapper.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/entities/booking_type.dart';

/// Anchor timestamp every fixture event uses unless overridden. Pinned to a
/// fixed instant so test outputs are deterministic — the freshness check
/// inside the mapper consults [_freshNow] (a few seconds inside the SLA
/// window) so events never accidentally trip the expiry filter on real
/// wall-clock days. Tests that *want* to assert on the expiry filter pass
/// their own `now`.
final _baseTs = DateTime.utc(2026, 4, 27, 20, 14, 42);
final _freshNow = _baseTs.add(const Duration(seconds: 30));

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
    'ui_location_label': 'Gulberg, Lahore',
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
    timestamp: timestamp ?? _baseTs,
    payload: base,
  );
}

void main() {
  group('JobNewRequestMapper.fromSystemEvent', () {
    test('fresh event → typed entity with parsed payout, UTC scheduledStart, '
        'envelope-anchored expiresAt, propagated locationLabel', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(timestamp: _baseTs),
        now: _freshNow,
      );

      expect(entity, isNotNull);
      expect(entity!.jobId, 99482);
      expect(entity.serviceName, 'AC Deep Wash');
      expect(entity.bookingType, BookingType.fixedGig);
      expect(entity.payoutRupees, 1200);
      expect(entity.payoutContext, 'Fixed-price gig — full payout');
      expect(entity.scheduledStart, DateTime.utc(2026, 4, 8, 5, 0, 0));
      // Anchored on envelope timestamp, NOT receipt time. Critical for SLA
      // alignment with the server's Celery timeout task.
      expect(entity.expiresAt, _baseTs.add(const Duration(seconds: 60)));
      expect(entity.locationLabel, 'Gulberg, Lahore');
    });

    test('§2.5 replay (null booking_type) → defaults to BookingType.laborGig',
        () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadRemovals: const {'booking_type': null}),
        now: _freshNow,
      );

      expect(entity, isNotNull);
      expect(entity!.bookingType, BookingType.laborGig);
    });

    test('§2.5 replay (null payout_context) → entity carries null', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadRemovals: const {'payout_context': null}),
        now: _freshNow,
      );

      expect(entity, isNotNull);
      expect(entity!.payoutContext, isNull);
    });

    test('unknown booking_type string → defaults to laborGig (no throw)', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'booking_type': 'MYSTERY_GIG'}),
        now: _freshNow,
      );

      expect(entity, isNotNull);
      expect(entity!.bookingType, BookingType.laborGig);
    });

    test('inspection wire string → BookingType.inspection', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'booking_type': 'INSPECTION'}),
        now: _freshNow,
      );

      expect(entity, isNotNull);
      expect(entity!.bookingType, BookingType.inspection);
    });

    test('null ui_location_label on wire → entity.locationLabel == null', () {
      // Backend sends null when the customer's address row has no
      // structured locality (legacy / pre-session-4 row, or address
      // detached via SET_NULL).
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'ui_location_label': null}),
        now: _freshNow,
      );

      expect(entity, isNotNull);
      expect(entity!.locationLabel, isNull);
    });

    test('§2.5 replay (ui_location_label key absent) → locationLabel null',
        () {
      // Pre-rollout EventLog rows replayed via /api/events/sync/ never had
      // ui_location_label on the wire at all. The deserializer must treat
      // the absent key as null without throwing.
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadRemovals: const {'ui_location_label': null}),
        now: _freshNow,
      );

      expect(entity, isNotNull);
      expect(entity!.locationLabel, isNull);
    });

    test('non-numeric payout → returns null (mapper logs, no throw)', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'payout': 'twelve hundred'}),
        now: _freshNow,
      );

      expect(entity, isNull);
    });

    test('unparseable scheduled_start_iso → returns null', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadOverrides: const {'scheduled_start_iso': 'not-a-date'}),
        now: _freshNow,
      );

      expect(entity, isNull);
    });

    test('missing required job_id → returns null (no throw)', () {
      final entity = JobNewRequestMapper.fromSystemEvent(
        _event(payloadRemovals: const {'job_id': null}),
        now: _freshNow,
      );

      expect(entity, isNull);
    });
  });

  group('JobNewRequestMapper.fromSystemEvent — flag #19 stale-FCM expiry', () {
    test(
      'now AT expiresAt → returns null (boundary; SLA is exclusive at the '
      'instant of expiry — same as the server-side Celery timeout)',
      () {
        // Envelope ts = _baseTs, expires_in_seconds = 60.
        // expiresAt = _baseTs + 60s. now = expiresAt → drop.
        final atExpiry = _baseTs.add(const Duration(seconds: 60));
        final entity = JobNewRequestMapper.fromSystemEvent(
          _event(timestamp: _baseTs),
          now: atExpiry,
        );

        expect(entity, isNull,
            reason: 'now == expiresAt is the boundary the SLA timer fires on');
      },
    );

    test(
      'now PAST expiresAt → returns null '
      '(stale FCM tap-intent on a long-ignored notification)',
      () {
        // Tray banner sat for 6 minutes after a 60-second SLA dispatch.
        final wayPastExpiry = _baseTs.add(const Duration(minutes: 6));
        final entity = JobNewRequestMapper.fromSystemEvent(
          _event(timestamp: _baseTs),
          now: wayPastExpiry,
        );

        expect(entity, isNull,
            reason: 'long-stale tap must not summon a sheet for a dead offer');
      },
    );

    test(
      'now JUST before expiresAt → still produces an entity '
      '(fresh by a hair — the technician still has time to swipe)',
      () {
        final justBeforeExpiry =
            _baseTs.add(const Duration(seconds: 59, milliseconds: 999));
        final entity = JobNewRequestMapper.fromSystemEvent(
          _event(timestamp: _baseTs),
          now: justBeforeExpiry,
        );

        expect(entity, isNotNull,
            reason: 'sub-second-fresh events must still reach the queue');
      },
    );

    test(
      'now defaults to DateTime.now().toUtc() when omitted '
      '(production call site shape)',
      () {
        // A LIVE envelope (timestamp ≈ wall clock now, generous SLA) must
        // still produce a typed entity when the mapper is called without
        // injecting `now` — confirms the production default does not
        // accidentally drop fresh events.
        final liveTs = DateTime.now().toUtc();
        final entity = JobNewRequestMapper.fromSystemEvent(
          _event(
            timestamp: liveTs,
            payloadOverrides: const {'expires_in_seconds': 300},
          ),
          // no `now` — exercises DateTime.now() fallback
        );

        expect(entity, isNotNull,
            reason: 'live envelope under default `now` must not be dropped');
      },
    );
  });
}

// Pins for `eyebrowTimeParts` — the helper that decides whether the card's
// eyebrow reads "ASAP", "Today · 4:30 PM", "Tomorrow · 9:00 AM", or
// "Wed, May 5 · 9:00 AM". The contract these tests defend against is the
// one that broke before: an earlier version inferred ASAP from
// `slaWindow.inSeconds <= 90` — a proxy that quietly stopped working when
// the backend's 5-minute SLA floor landed (every offer started reading as
// "scheduled" because no slaWindow was tight enough). The current helper
// reads the actual signal — `scheduledStart` relative to `now` — so the
// SLA floor change doesn't break the eyebrow.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/entities/booking_type.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/entities/job_new_request.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/widgets/incoming_job_card.dart';

JobNewRequest _request({
  required DateTime scheduledStart,
  Duration slaWindow = const Duration(minutes: 5),
}) {
  return JobNewRequest(
    jobId: 1,
    serviceName: 'AC Wash',
    bookingType: BookingType.fixedGig,
    payoutRupees: 1500,
    payoutContext: null,
    scheduledStart: scheduledStart,
    expiresAt: DateTime.now().add(slaWindow),
    slaWindow: slaWindow,
    locationLabel: null,
  );
}

void main() {
  group('eyebrowTimeParts', () {
    final now = DateTime(2026, 5, 2, 14, 30); // Saturday afternoon.

    test('scheduledStart within 30 minutes of now → ASAP (no clock)', () {
      final r = _request(scheduledStart: now.add(const Duration(minutes: 5)));
      final parts = eyebrowTimeParts(r, now: now);
      expect(parts.isAsap, isTrue);
      expect(parts.day, 'ASAP');
      expect(parts.clock, isNull);
    });

    test('scheduledStart === now → ASAP (boundary)', () {
      final r = _request(scheduledStart: now);
      final parts = eyebrowTimeParts(r, now: now);
      expect(parts.isAsap, isTrue);
    });

    test(
      'scheduledStart 31 minutes out → not ASAP (boundary, falls into Today)',
      () {
        final r = _request(
          scheduledStart: now.add(const Duration(minutes: 31)),
        );
        final parts = eyebrowTimeParts(r, now: now);
        expect(parts.isAsap, isFalse);
        expect(parts.day, 'Today');
        expect(parts.clock, isNotNull);
      },
    );

    test(
      'scheduledStart later today (well past ASAP window) → Today + clock',
      () {
        final r = _request(scheduledStart: now.add(const Duration(hours: 4)));
        final parts = eyebrowTimeParts(r, now: now);
        expect(parts.isAsap, isFalse);
        expect(parts.day, 'Today');
        // Match digits + AM/PM (intl 0.19+ uses U+202F narrow no-break space
        // between time and meridiem, intl 0.18 uses a regular space).
        expect(parts.clock, matches(RegExp(r'^6:30\s+PM$')));
      },
    );

    test('scheduledStart tomorrow morning → Tomorrow + clock', () {
      final tomorrow900 = DateTime(now.year, now.month, now.day + 1, 9, 0);
      final r = _request(scheduledStart: tomorrow900);
      final parts = eyebrowTimeParts(r, now: now);
      expect(parts.isAsap, isFalse);
      expect(parts.day, 'Tomorrow');
      expect(parts.clock, matches(RegExp(r'^9:00\s+AM$')));
    });

    test('scheduledStart a few days out → "EEE, MMM d" + clock', () {
      final laterThisWeek = DateTime(now.year, now.month, now.day + 3, 11, 15);
      final r = _request(scheduledStart: laterThisWeek);
      final parts = eyebrowTimeParts(r, now: now);
      expect(parts.isAsap, isFalse);
      expect(parts.day, 'Tue, May 5');
      expect(parts.clock, matches(RegExp(r'^11:15\s+AM$')));
    });

    test(
      'slaWindow does NOT affect the ASAP decision — only scheduledStart does',
      () {
        // The pre-pivot helper inferred ASAP from `slaWindow.inSeconds <= 90`.
        // Today the floor is 5 minutes; if anything regressed and started
        // reading slaWindow again, this test would catch it. The fixture has
        // a tight 5-minute slaWindow but a scheduledStart 4 hours out — that
        // must still read as "Today" (scheduled), not ASAP.
        final r = _request(
          scheduledStart: now.add(const Duration(hours: 4)),
          slaWindow: const Duration(minutes: 5),
        );
        final parts = eyebrowTimeParts(r, now: now);
        expect(parts.isAsap, isFalse);
        expect(parts.day, 'Today');
      },
    );
  });
}

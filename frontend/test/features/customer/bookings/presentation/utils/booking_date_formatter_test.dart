// Date formatter is pure: takes a scheduled-start, a server-anchored
// "now", a status, and returns the display string used in the booking
// card's date row.
//
// **Critical invariant**: the formatter MUST anchor on the passed-in
// `serverNow`, never call `DateTime.now()`. Device-clock skew otherwise
// mislabels imminence ("30 min ago" for a future booking on a phone
// with the wrong time set). These tests pin a fake server-now and
// assert the output deterministically across every §6.1 row.
//
// All inputs use **local** DateTimes (the formatter calls `.toLocal()`
// on both inputs, so local-DateTime tests are stable across timezones).
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/presentation/utils/booking_date_formatter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // Anchor: Tuesday 5 May 2026, 12:00 local time.
  final serverNow = DateTime(2026, 5, 5, 12, 0, 0);

  setUpAll(() async {
    await initializeDateFormatting('en_US');
  });

  String fmt(
    DateTime start, {
    BookingStatus status = BookingStatus.confirmed,
  }) => formatBookingDate(
    scheduledStart: start,
    serverNow: serverNow,
    status: status,
  );

  group('relative minutes (±60)', () {
    test('30 min ahead → "In 30 min"', () {
      expect(fmt(serverNow.add(const Duration(minutes: 30))), 'In 30 min');
    });

    test('60 min ahead → "In 60 min" (boundary)', () {
      expect(fmt(serverNow.add(const Duration(minutes: 60))), 'In 60 min');
    });

    test('30 min ago → "30 min ago"', () {
      expect(
        fmt(serverNow.subtract(const Duration(minutes: 30))),
        '30 min ago',
      );
    });

    test('exact server-now → "Now"', () {
      expect(fmt(serverNow), 'Now');
    });
  });

  group('today / tomorrow', () {
    test('Today, > 60 min ahead → "Today, 3:00 PM"', () {
      expect(fmt(DateTime(2026, 5, 5, 15, 0)), 'Today, 3:00 PM');
    });

    test('Tomorrow → "Tomorrow, 3:00 PM"', () {
      expect(fmt(DateTime(2026, 5, 6, 15, 0)), 'Tomorrow, 3:00 PM');
    });
  });

  group('weekday window (2-6 days ahead)', () {
    test('5 days ahead → weekday name + time', () {
      // 2026-05-05 is a Tuesday; +5 days lands on Sunday.
      final result = fmt(DateTime(2026, 5, 10, 15, 0));
      expect(result, contains('Sunday'));
      expect(result, contains('3:00 PM'));
    });
  });

  group('beyond week / year boundaries', () {
    test('this year, > 6 days → MMM d + time', () {
      final result = fmt(DateTime(2026, 6, 4, 15, 0));
      expect(result, contains('Jun 4'));
      expect(result, contains('3:00 PM'));
      expect(result, isNot(contains('2026')));
    });

    test('different year → includes year', () {
      final result = fmt(DateTime(2027, 6, 4, 15, 0));
      expect(result, contains('2027'));
      expect(result, contains('3:00 PM'));
    });
  });

  group('AWAITING SLA hint', () {
    test('AWAITING appends " · responding within ~15 min"', () {
      final result = fmt(
        serverNow.add(const Duration(minutes: 30)),
        status: BookingStatus.awaiting,
      );
      expect(result, 'In 30 min · responding within ~15 min');
    });

    test('non-AWAITING statuses do NOT append the SLA hint', () {
      for (final s in [
        BookingStatus.confirmed,
        BookingStatus.completed,
        BookingStatus.cancelled,
        BookingStatus.rejected,
        BookingStatus.pending,
        BookingStatus.unknown,
      ]) {
        final result = fmt(
          serverNow.add(const Duration(minutes: 30)),
          status: s,
        );
        expect(result, isNot(contains('responding within')));
      }
    });
  });

  group('server-anchored (no DateTime.now leakage)', () {
    test('formatter ignores wall-clock when serverNow is far in the past', () {
      // If the formatter were calling DateTime.now() instead of using
      // the passed serverNow, this booking (5h ahead of a fake "10
      // years ago" anchor) would format as a far-past or far-future
      // date with year. Anchoring correctly, it's "Today, 5:00 PM".
      final fakePastNow = DateTime(2016, 5, 5, 12, 0, 0);
      final result = formatBookingDate(
        scheduledStart: DateTime(2016, 5, 5, 17, 0, 0),
        serverNow: fakePastNow,
        status: BookingStatus.confirmed,
      );
      expect(result, 'Today, 5:00 PM');
    });
  });
}

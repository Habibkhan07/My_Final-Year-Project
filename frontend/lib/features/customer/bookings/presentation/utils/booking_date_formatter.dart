import 'package:intl/intl.dart';

import '../../domain/entities/booking_status.dart';

/// Smart "Today / Tomorrow / In 30 min" formatter for the booking card's
/// date row.
///
/// **Always anchor on [serverNow], never `DateTime.now()`.** Device clock
/// skew (a phone with the wrong time set) would otherwise misrepresent
/// imminence — e.g. label a freshly scheduled visit as "30 min ago"
/// because the device thinks it's an hour ahead. The list state's
/// `serverTime` field carries the server's wall clock at page assembly;
/// this is the value to pass in.
///
/// Returns a localised string. Pakistan uses 12h time; `DateFormat.jm()`
/// honors the device locale so a user with their phone in `en_US` sees
/// `3:00 PM` and a user in `de_DE` sees `15:00`.
String formatBookingDate({
  required DateTime scheduledStart,
  required DateTime serverNow,
  required BookingStatus status,
}) {
  final localStart = scheduledStart.toLocal();
  final localNow = serverNow.toLocal();
  final diffMinutes = localStart.difference(localNow).inMinutes;
  final base = _renderBase(localStart, localNow, diffMinutes);

  // AWAITING bookings get a static SLA hint appended. A live ticking
  // countdown is documented as deferred polish in §13.
  if (status == BookingStatus.awaiting) {
    return '$base · responding within ~15 min';
  }
  return base;
}

String _renderBase(DateTime start, DateTime now, int diffMinutes) {
  final timePart = DateFormat.jm().format(start);

  // 0–60 minutes either side gets the relative-minute treatment.
  if (diffMinutes >= 0 && diffMinutes <= 60) {
    if (diffMinutes == 0) return 'Now';
    return 'In $diffMinutes min';
  }
  if (diffMinutes < 0 && diffMinutes >= -60) {
    return '${diffMinutes.abs()} min ago';
  }

  final startDay = DateTime(start.year, start.month, start.day);
  final today = DateTime(now.year, now.month, now.day);
  final dayDelta = startDay.difference(today).inDays;

  if (dayDelta == 0) return 'Today, $timePart';
  if (dayDelta == 1) return 'Tomorrow, $timePart';
  if (dayDelta == -1) return 'Yesterday, $timePart';

  if (dayDelta > 1 && dayDelta <= 6) {
    return '${DateFormat.EEEE().format(start)}, $timePart';
  }

  if (start.year == now.year) {
    return '${DateFormat.MMMd().format(start)}, $timePart';
  }
  return '${DateFormat.yMMMd().format(start)}, $timePart';
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/bookings_offline_banner.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SafeArea(child: child)));

void main() {
  group('BookingsOfflineBanner', () {
    testWidgets('renders "X min ago" when cachedAt is N minutes before now',
        (tester) async {
      final serverNow = DateTime(2026, 5, 5, 12, 0, 0);
      final cachedAt = serverNow.subtract(const Duration(minutes: 8));

      await tester.pumpWidget(_wrap(BookingsOfflineBanner(
        cachedAt: cachedAt,
        serverNow: serverNow,
        onRefresh: () {},
      )));

      expect(find.textContaining('8 min ago'), findsOneWidget);
      expect(find.textContaining('Offline'), findsOneWidget);
    });

    testWidgets('renders "just now" for sub-minute deltas', (tester) async {
      final serverNow = DateTime(2026, 5, 5, 12, 0, 0);
      final cachedAt = serverNow.subtract(const Duration(seconds: 20));

      await tester.pumpWidget(_wrap(BookingsOfflineBanner(
        cachedAt: cachedAt,
        serverNow: serverNow,
        onRefresh: () {},
      )));

      expect(find.textContaining('just now'), findsOneWidget);
    });

    testWidgets('refresh button fires the callback', (tester) async {
      var fired = 0;
      final serverNow = DateTime(2026, 5, 5, 12, 0, 0);

      await tester.pumpWidget(_wrap(BookingsOfflineBanner(
        cachedAt: serverNow.subtract(const Duration(minutes: 5)),
        serverNow: serverNow,
        onRefresh: () => fired++,
      )));

      await tester.tap(find.byIcon(Icons.refresh));
      expect(fired, 1);
    });
  });
}

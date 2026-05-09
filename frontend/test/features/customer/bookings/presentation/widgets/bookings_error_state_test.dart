import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/bookings_error_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BookingsErrorState', () {
    testWidgets('.offline() variant renders the offline copy', (tester) async {
      await tester.pumpWidget(
        _wrap(BookingsErrorState.offline(onRetry: () {})),
      );
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.textContaining('Connect and try again'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('.server() variant renders the server-error copy', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(BookingsErrorState.server(onRetry: () {})));
      expect(find.text("Couldn't load your bookings"), findsOneWidget);
      expect(find.textContaining('our end'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('.unknown() variant renders the neutral copy', (tester) async {
      await tester.pumpWidget(
        _wrap(BookingsErrorState.unknown(onRetry: () {})),
      );
      expect(find.text("Couldn't load your bookings"), findsOneWidget);
      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('Retry button fires the callback', (tester) async {
      var fired = 0;
      await tester.pumpWidget(
        _wrap(BookingsErrorState.server(onRetry: () => fired++)),
      );
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(fired, 1);
    });
  });
}

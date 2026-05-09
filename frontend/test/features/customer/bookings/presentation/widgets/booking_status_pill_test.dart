import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/customer/bookings/presentation/utils/booking_tone_palette.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/booking_status_pill.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('BookingStatusPill', () {
    testWidgets('renders text in uppercase', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BookingStatusPill(
            text: 'Awaiting tech',
            tone: BookingUiTone.warning,
          ),
        ),
      );
      expect(find.text('AWAITING TECH'), findsOneWidget);
    });

    testWidgets('paints with the tone palette background', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BookingStatusPill(
            text: 'Confirmed',
            tone: BookingUiTone.positive,
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('CONFIRMED'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.color,
        BookingTonePalette.of(BookingUiTone.positive).background,
      );
    });

    testWidgets('renders for every tone without throwing', (tester) async {
      for (final tone in BookingUiTone.values) {
        await tester.pumpWidget(
          _wrap(BookingStatusPill(text: 'Status', tone: tone)),
        );
        expect(find.text('STATUS'), findsOneWidget);
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/bookings_empty_past.dart';

void main() {
  testWidgets('renders headline + body and contains NO call-to-action button',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BookingsEmptyPast())),
    );

    expect(find.text('No past bookings'), findsOneWidget);
    expect(
      find.textContaining('booking history'),
      findsAtLeastNWidgets(1),
    );
    // Past has no CTA per §7.3.
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}

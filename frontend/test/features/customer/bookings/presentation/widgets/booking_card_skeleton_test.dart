import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/booking_card_skeleton.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  testWidgets('BookingCardSkeleton mounts with a Shimmer wrapper', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BookingCardSkeleton()),
      ),
    );
    // Don't pumpAndSettle — Shimmer animates indefinitely.
    expect(find.byType(BookingCardSkeleton), findsOneWidget);
    expect(find.byType(Shimmer), findsOneWidget);
  });

  testWidgets('renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BookingCardSkeleton()),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

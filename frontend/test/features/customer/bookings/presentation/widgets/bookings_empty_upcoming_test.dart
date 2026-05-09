import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/bookings_empty_upcoming.dart';
import 'package:go_router/go_router.dart';

/// Builds a minimal GoRouter that lets the empty-state CTA navigate.
/// Tapping "Browse services" issues `context.go('/home')` — we land on
/// the sentinel route below and assert on its text.
GoRouter _router() => GoRouter(
  initialLocation: '/bookings',
  routes: [
    GoRoute(
      path: '/bookings',
      builder: (_, _) => const Scaffold(body: BookingsEmptyUpcoming()),
    ),
    GoRoute(
      path: '/home',
      builder: (_, _) =>
          const Scaffold(body: Center(child: Text('HOME-SENTINEL'))),
    ),
  ],
);

void main() {
  testWidgets('renders headline + body + Browse services CTA', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    expect(find.text('No upcoming bookings'), findsOneWidget);
    expect(find.textContaining('Browse services'), findsAtLeastNWidgets(1));
  });

  testWidgets('CTA navigates to /home', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Browse services'));
    await tester.pumpAndSettle();

    expect(find.text('HOME-SENTINEL'), findsOneWidget);
  });
}

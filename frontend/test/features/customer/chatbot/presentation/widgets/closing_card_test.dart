// Widget tests for ClosingCard.
//
// The card uses `context.pop()` from go_router on its CTA, so the
// harness wraps a tiny GoRouter so the pop has somewhere to go back
// to (`/booking`). We assert the resulting location after tap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/output_refs.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/closing_card.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/booking',
    routes: [
      GoRoute(
        path: '/booking',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('BOOKING_DETAIL_PLACEHOLDER'))),
        routes: [
          GoRoute(
            path: 'dispute-chat',
            builder: (_, _) => Scaffold(
              body: ClosingCard(refs: const OutputRefs(ticketId: 1284)),
            ),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('renders Dispute filed + Ticket #N + Back to booking', (
    tester,
  ) async {
    final router = _buildRouter();
    // Push the chat route on top of /booking.
    router.go('/booking/dispute-chat');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('Dispute filed'), findsOneWidget);
    expect(find.text('Ticket #1284'), findsOneWidget);
    expect(find.text('Back to booking'), findsOneWidget);
  });

  testWidgets('tapping Back to booking pops the chat route', (tester) async {
    final router = _buildRouter();
    router.go('/booking/dispute-chat');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pumpAndSettle();

    // Sanity: we're on the chat route.
    expect(find.text('Back to booking'), findsOneWidget);

    await tester.tap(find.text('Back to booking'));
    await tester.pumpAndSettle();

    // We're back on /booking.
    expect(find.text('BOOKING_DETAIL_PLACEHOLDER'), findsOneWidget);
    expect(find.byType(ClosingCard), findsNothing);
  });
}

// Widget tests for `BookingActionPendingSheet`.
//
// The sheet is shared by every "deferred / coming soon" action and the
// cancel-with-default-reason flow. The regression vectors:
//   * Long body must SCROLL (#B-69) — long explainer prose for sessions
//     5/6 used to overflow the screen because the column wasn't wrapped.
//   * onConfirm errors render INLINE and do NOT pop the sheet — callers
//     gate refetches on `result == true`, so a popped-on-error sheet
//     would silently produce stale data.
//   * Successful confirm pops with `true`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/sheets/booking_action_pending_sheet.dart';

void main() {
  group('BookingActionPendingSheet', () {
    testWidgets('long body content is scrollable (#B-69 regression guard)',
        (tester) async {
      // Construct a body long enough that, without scrolling, it would
      // overflow the bottom-sheet area on a small phone.
      final longBody = List.generate(40, (i) => 'Paragraph $i').join('\n\n');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BookingActionPendingSheet(
            title: 'Coming soon',
            body: longBody,
          ),
        ),
      ));

      // The sheet wraps its Column in a SingleChildScrollView so long
      // bodies don't overflow. Finding it descended from the sheet
      // proves the wrap is in place.
      final scrollableInSheet = find.descendant(
        of: find.byType(BookingActionPendingSheet),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollableInSheet, findsOneWidget);

      // Sanity: no overflow paint occurred on first build.
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders confirm + dismiss buttons when confirmLabel set',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BookingActionPendingSheet(
            title: 'Cancel booking?',
            body: 'You will need to rebook.',
            confirmLabel: 'Cancel booking',
            confirmIsDestructive: true,
            onConfirm: () async {},
          ),
        ),
      ));

      expect(find.text('Cancel booking'), findsOneWidget);
      // Dismiss copy is "Keep it" when confirm is destructive — guards
      // the disambiguation logic in `_dismissLabel`.
      expect(find.text('Keep it'), findsOneWidget);
    });

    testWidgets('renders Got it dismiss when no confirm action set',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BookingActionPendingSheet(
            title: 'Coming soon',
            body: 'Ships in session 6.',
          ),
        ),
      ));
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('HttpFailure from onConfirm renders inline error and stays open',
        (tester) async {
      Future<void> onConfirm() async {
        throw const HttpFailure(
          statusCode: 400,
          code: 'bad_amount',
          message: 'Amount mismatch',
          errors: {},
        );
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BookingActionPendingSheet(
            title: 'Confirm cash',
            body: 'Confirm Rs. 500 received.',
            confirmLabel: 'Confirm',
            onConfirm: onConfirm,
          ),
        ),
      ));

      await tester.tap(find.text('Confirm'));
      await tester.pump(); // run the future
      await tester.pump(); // settle the setState

      // Error message rendered inline — sheet stays open.
      expect(find.text('Amount mismatch'), findsOneWidget);
      // Sheet still mounted (its widget instance is still in the tree).
      expect(find.byType(BookingActionPendingSheet), findsOneWidget);
    });

    testWidgets('generic exception from onConfirm renders fallback message',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BookingActionPendingSheet(
            title: 'Confirm',
            body: '...',
            confirmLabel: 'Do it',
            onConfirm: () async => throw Exception('boom'),
          ),
        ),
      ));

      await tester.tap(find.text('Do it'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Could not complete action.'), findsOneWidget);
    });
  });
}

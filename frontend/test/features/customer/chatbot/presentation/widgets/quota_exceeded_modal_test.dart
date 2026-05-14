// Widget tests for showQuotaExceededModal.
//
// The modal is a top-level function returning a Future; we trigger it
// via a button in the test harness, then assert on the resulting
// AlertDialog.
//
// Coverage:
//   * Title + body copy is the soft-worded version (no "rate limited"
//     language).
//   * Both action buttons ("Use Help" and "OK") are present.
//   * Tapping "OK" dismisses the dialog.
//   * Tapping "Use Help" dismisses the dialog (TODO stub — will land
//     a route push when /customer/help ships; see flag #2 in plan §10.8).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/quota_exceeded_modal.dart';

Widget _harness() {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showQuotaExceededModal(context),
            child: const Text('TRIGGER'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openModal(WidgetTester tester) async {
  await tester.pumpWidget(_harness());
  await tester.tap(find.text('TRIGGER'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders soft-worded title + body + both CTAs', (tester) async {
    await _openModal(tester);

    expect(find.text('Daily limit reached'), findsOneWidget);
    expect(
      find.textContaining(
        "today's AI assistant limit",
      ),
      findsOneWidget,
    );
    expect(find.text('Use Help'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('OK dismisses the dialog', (tester) async {
    await _openModal(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Use Help dismisses the dialog (v1 stub)', (tester) async {
    await _openModal(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Use Help'));
    await tester.pumpAndSettle();

    // v1 behaviour: closes the modal and leaves the user on the
    // chatbot screen with their transcript intact. Once /customer/help
    // ships, this assertion should change to verify route push.
    expect(find.byType(AlertDialog), findsNothing);
  });
}

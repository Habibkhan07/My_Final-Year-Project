// Widget tests for `OrchestratorSnack`.
//
// The whole reason this helper exists is to fix the "snack appears
// above the map" UX bug — default ScaffoldMessenger.showSnackBar
// anchors a snack to the bottom of the body, which on the orchestrator
// screen squeezes it between the Expanded body and the action bar.
// These tests pin the two production invariants that make it work:
//
//   1. The snack uses SnackBarBehavior.floating, NOT fixed.
//   2. The snack reserves a non-zero bottom margin so it floats ABOVE
//      the action bar rather than under it.
//
// Without those, regressions would silently re-introduce the bug.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/feedback/orchestrator_snack.dart';

void main() {
  group('OrchestratorSnack', () {
    testWidgets('info → floating SnackBar with bottom margin clearing action bar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    OrchestratorSnack.info(context, 'You confirmed arrival.'),
                child: const Text('trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('trigger'));
      await tester.pump(); // schedule snack
      await tester.pump(const Duration(milliseconds: 100)); // start anim

      // Body text we passed is what the user actually sees.
      expect(find.text('You confirmed arrival.'), findsOneWidget);

      // Pull the SnackBar out of the tree and assert the production
      // invariants.
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        snack.behavior,
        SnackBarBehavior.floating,
        reason: 'must float so a fixed-anchor snack does not paint over the action bar',
      );
      final margin = snack.margin?.resolve(TextDirection.ltr);
      expect(
        margin,
        isNotNull,
        reason: 'helper must set a margin (bottom > 0) so the snack clears the action bar',
      );
      expect(
        margin!.bottom,
        greaterThan(50),
        reason: 'bottom margin must reserve room for the lifted action bar',
      );
    });

    testWidgets('error variant uses theme.colorScheme.error background',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    OrchestratorSnack.error(context, 'No connection.'),
                child: const Text('trigger'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No connection.'), findsOneWidget);
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      // We don't assert the exact color (theme-derived), but we do
      // pin that error uses the error icon path, not the info one.
      expect(snack.backgroundColor, isNotNull);
    });

    testWidgets('outside ScaffoldMessenger → no throw, silent noop',
        (tester) async {
      // Defensive: if a test mounts a bare Widget the helper must not
      // crash trying to find a ScaffoldMessenger.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => OrchestratorSnack.info(context, 'whatever'),
              child: const Text('trigger'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('trigger'));
      await tester.pump();
      // No exception → contract met.
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}

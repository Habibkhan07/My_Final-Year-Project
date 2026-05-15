import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/technician/dashboard/presentation/widgets/work_location_banner.dart';

/// Pins the work-location banner contract:
///
/// * `hasWorkLocation == false` renders the call-to-action card with the
///   "Set your work area" headline so an unset tech is nudged to fix the
///   discovery hole their profile creates.
/// * `hasWorkLocation == true` renders the quiet summary row with the
///   stored label as a re-edit affordance — never disappears once set,
///   because the tech still needs a way to update it.
/// * Either variant taps to ``/technician/work-location``.
void main() {
  Widget wrap(Widget child) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => Scaffold(body: child)),
        GoRoute(
          path: '/technician/work-location',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('picker-screen'))),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'unset renders the call-to-action with the prompt headline',
    (tester) async {
      await tester.pumpWidget(
        wrap(const WorkLocationBanner(hasWorkLocation: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set your work area'), findsOneWidget);
      expect(
        find.text("Customers can't find you until you pick a location."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'set renders the summary row with the saved label',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const WorkLocationBanner(
            hasWorkLocation: true,
            workAddressLabel: 'Gulberg, Lahore',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('YOUR WORK AREA'), findsOneWidget);
      expect(find.text('Gulberg, Lahore'), findsOneWidget);
      // Call-to-action copy should NOT appear once set.
      expect(find.text('Set your work area'), findsNothing);
    },
  );

  testWidgets(
    'set with null label falls back to "Location set"',
    (tester) async {
      await tester.pumpWidget(
        wrap(const WorkLocationBanner(hasWorkLocation: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Location set'), findsOneWidget);
    },
  );

  testWidgets(
    'tap navigates to the picker route (unset variant)',
    (tester) async {
      await tester.pumpWidget(
        wrap(const WorkLocationBanner(hasWorkLocation: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set your work area'));
      await tester.pumpAndSettle();

      expect(find.text('picker-screen'), findsOneWidget);
    },
  );

  testWidgets(
    'tap navigates to the picker route (set variant)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const WorkLocationBanner(
            hasWorkLocation: true,
            workAddressLabel: 'Gulberg, Lahore',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gulberg, Lahore'));
      await tester.pumpAndSettle();

      expect(find.text('picker-screen'), findsOneWidget);
    },
  );
}

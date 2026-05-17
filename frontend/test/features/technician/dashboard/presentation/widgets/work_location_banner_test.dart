import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/technician/dashboard/presentation/widgets/work_location_banner.dart';

/// Pins the work-location banner contract:
///
/// * `hasWorkLocation == false` renders the call-to-action card with the
///   "Set your work area" headline so an unset tech is nudged to fix the
///   discovery hole their profile creates.
/// * `hasWorkLocation == true` renders NOTHING — once the work area is
///   set, the dashboard hides the banner entirely and the tech edits via
///   Profile → Work Location. The dashboard's job is jobs + status, not
///   surfacing the same affordance twice.
/// * The unset CTA taps through to `/technician/work-location`.
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
    'set renders nothing — banner is hidden once work area exists',
    (tester) async {
      await tester.pumpWidget(
        wrap(const WorkLocationBanner(hasWorkLocation: true)),
      );
      await tester.pumpAndSettle();

      // Both halves of the prior summary tile must not appear.
      expect(find.text('YOUR WORK AREA'), findsNothing);
      expect(find.text('Location set'), findsNothing);
      // The unset CTA copy must also not bleed through.
      expect(find.text('Set your work area'), findsNothing);
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
}

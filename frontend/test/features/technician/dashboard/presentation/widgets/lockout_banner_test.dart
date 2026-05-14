import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/technician/dashboard/presentation/widgets/lockout_banner.dart';

/// Pins the lockout-banner contract:
///
/// * [LockoutBanner.isLocked] is a thin re-export of the shared rule in
///   ``core/common/wallet_lockout.dart``. The formula's boundary tests
///   live alongside the utility itself
///   (``test/core/common/wallet_lockout_test.dart``).
/// * The banner copy reads "Top up Rs. {owed} to clear the lockout"
///   verbatim — the same wording used by the wallet strip + sheet host
///   snackbar so the three lockout surfaces don't drift.
/// * Tapping the banner pushes the wallet route.
void main() {
  group('LockoutBanner.isLocked — thin re-export of shared rule', () {
    test('zero balance is NOT locked', () {
      expect(LockoutBanner.isLocked(0.0), isFalse);
    });

    test('positive balance is NOT locked', () {
      expect(LockoutBanner.isLocked(1500.0), isFalse);
    });

    test('one paisa negative IS locked', () {
      expect(LockoutBanner.isLocked(-0.01), isTrue);
    });

    test('deeply negative IS locked', () {
      expect(LockoutBanner.isLocked(-1000.0), isTrue);
    });
  });

  group('LockoutBanner widget rendering', () {
    Widget wrap(Widget child) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(body: child),
          ),
          GoRoute(
            path: '/wallet',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('wallet-screen'))),
          ),
        ],
      );
      return MaterialApp.router(routerConfig: router);
    }

    testWidgets('renders the owed amount in the body copy', (tester) async {
      await tester.pumpWidget(wrap(const LockoutBanner(walletBalance: -495.0)));
      await tester.pumpAndSettle();

      expect(find.text('Wallet locked'), findsOneWidget);
      expect(
        find.text('Top up Rs. 495 to clear the lockout.'),
        findsOneWidget,
      );
    });

    testWidgets('rounds paisa fractions UP in the copy', (tester) async {
      await tester.pumpWidget(
        wrap(const LockoutBanner(walletBalance: -100.01)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Top up Rs. 101 to clear the lockout.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping the banner pushes /wallet', (tester) async {
      await tester.pumpWidget(wrap(const LockoutBanner(walletBalance: -200.0)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wallet locked'));
      await tester.pumpAndSettle();

      expect(find.text('wallet-screen'), findsOneWidget);
    });
  });
}

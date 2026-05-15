import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/technician_status.dart';
import 'package:frontend/features/technician/onboarding/domain/failures/tech_status_failure.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/technician_status_provider.dart';
import 'package:frontend/features/technician/onboarding/presentation/screens/pending_approval_screen.dart';

import '../../../dashboard/_helpers/test_overrides.dart';

/// Wraps the screen in a ProviderScope with the [technicianStatusProvider]
/// overridden to emit [statusBuilder] and a fake auth identity. Uses
/// `GoRouter` so the screen's `context.go(...)` calls don't blow up.
Widget _wrap({
  required Future<TechnicianStatus> Function(Ref) statusBuilder,
  List<String> routeStack = const ['/technician/pending'],
}) {
  final visitedRoutes = <String>[];

  final router = GoRouter(
    initialLocation: routeStack.last,
    routes: [
      GoRoute(
        path: '/technician/pending',
        builder: (_, _) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/technician/onboarding',
        builder: (_, _) {
          visitedRoutes.add('/technician/onboarding');
          return const Scaffold(body: Text('onboarding-page'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => FakeAuthNotifier(fakeUser)),
      technicianStatusProvider.overrideWith(statusBuilder),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('PendingApprovalScreen — loading', () {
    testWidgets('renders the spinner + "Checking…" copy while status loads',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) => Completer<TechnicianStatus>().future,
      ));
      // pumpAndSettle would hang on the never-completing future; pump
      // forwards one frame past the first build.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Checking'), findsOneWidget);
    });
  });

  group('PendingApprovalScreen — pending variant', () {
    testWidgets('renders the hourglass icon + "Under Review" copy',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => const TechnicianStatusPending(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Application Under Review'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
      // Logout button is the bottom-most primary action.
      expect(find.text('Logout'), findsOneWidget);
      // Re-apply CTA must NOT show on the pending variant — backend would
      // reject with 409 duplicate_application.
      expect(find.text('Submit a new application'), findsNothing);
    });
  });

  group('PendingApprovalScreen — rejected variant', () {
    testWidgets(
      'renders the rejection reason block, re-apply CTA, and check-again link',
      (tester) async {
        await tester.pumpWidget(_wrap(
          statusBuilder: (_) async => const TechnicianStatusRejected(
            reason: 'CNIC image was illegible.',
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Application Not Approved'), findsOneWidget);
        expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
        expect(find.text('CNIC image was illegible.'), findsOneWidget);
        expect(find.text('Submit a new application'), findsOneWidget);
        expect(find.text('Check status again'), findsOneWidget);
        expect(find.text('Log out'), findsOneWidget);
      },
    );

    testWidgets('reason block is hidden when reason is null', (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => const TechnicianStatusRejected(reason: null),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Application Not Approved'), findsOneWidget);
      // No reason label.
      expect(find.text('Reason'), findsNothing);
      // The re-apply CTA stays on even without a reason — REJECTED is
      // REJECTED.
      expect(find.text('Submit a new application'), findsOneWidget);
    });

    testWidgets('reason block is hidden when reason is empty string',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => const TechnicianStatusRejected(reason: ''),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Reason'), findsNothing);
    });

    testWidgets('Submit a new application navigates to /technician/onboarding',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => const TechnicianStatusRejected(
          reason: 'try again',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit a new application'));
      await tester.pumpAndSettle();

      expect(find.text('onboarding-page'), findsOneWidget);
    });
  });

  group('PendingApprovalScreen — error variant', () {
    testWidgets('NetworkFailure renders the offline copy + Try again',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async =>
            throw const TechStatusNetworkFailure('offline'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Connection problem'), findsOneWidget);
      expect(find.textContaining("offline"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
    });

    testWidgets('Unauthorized renders the session-expired copy',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => throw const TechStatusUnauthorized(),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('session expired'), findsOneWidget);
    });

    testWidgets('Server failure falls back to the generic message',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async =>
            throw const TechStatusServerFailure('500 internal'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining("couldn't reach the server"), findsOneWidget);
    });
  });

  group('PendingApprovalScreen — transient variants', () {
    testWidgets(
      'APPROVED state shows the spinner (router will redirect away on next frame)',
      (tester) async {
        await tester.pumpWidget(_wrap(
          statusBuilder: (_) async => const TechnicianStatusApproved(),
        ));
        // Let the async build resolve, then pump one more frame for the
        // resulting tree. ``pumpAndSettle`` would deadlock on the spinner
        // animation.
        await tester.pump();
        await tester.pump();

        // Same loading shim as AsyncLoading — never render misleading
        // pending/rejected copy.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Application Not Approved'), findsNothing);
        expect(find.text('Application Under Review'), findsNothing);
      },
    );

    testWidgets(
      'NoProfile state shows the spinner (router will redirect away on next frame)',
      (tester) async {
        await tester.pumpWidget(_wrap(
          statusBuilder: (_) async => const TechnicianStatusNoProfile(),
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}

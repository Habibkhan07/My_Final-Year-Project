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

/// Wraps the screen in a ProviderScope with [technicianStatusProvider]
/// overridden + the routes the screen navigates to (`/technician/onboarding`
/// for re-apply, `/home` for the "Continue as customer" escape).
Widget _wrap({
  required Future<TechnicianStatus> Function(Ref) statusBuilder,
  List<String> routeStack = const ['/technician/pending'],
  bool justSubmitted = false,
}) {
  final router = GoRouter(
    initialLocation: routeStack.last,
    routes: [
      GoRoute(
        path: '/technician/pending',
        builder: (_, _) => PendingApprovalScreen(
          justSubmitted: justSubmitted,
        ),
      ),
      GoRoute(
        path: '/technician/onboarding',
        builder: (_, _) => const Scaffold(body: Text('onboarding-page')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('home-page')),
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
    testWidgets('renders a spinner while status loads', (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) => Completer<TechnicianStatus>().future,
      ));
      // pumpAndSettle would hang on the never-completing future; pump
      // forwards one frame past the first build.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('PendingApprovalScreen — pending variant', () {
    testWidgets('renders the hourglass hero + under-review copy',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => const TechnicianStatusPending(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Under review'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      // No CTA on Pending — pull-to-refresh owns the refresh affordance.
      expect(find.text('Refresh status'), findsNothing);
      // Re-apply CTA must NOT show on the pending variant — backend would
      // reject with 409 duplicate_application.
      expect(find.text('Submit a new application'), findsNothing);
      // Sign-out lives in the customer Profile tab now, not here.
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('AppBar back arrow exits to /home', (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => const TechnicianStatusPending(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('home-page'), findsOneWidget);
    });

    testWidgets(
      'justSubmitted=true shows the "Application sent" banner',
      (tester) async {
        await tester.pumpWidget(_wrap(
          statusBuilder: (_) async => const TechnicianStatusPending(),
          justSubmitted: true,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Application sent'), findsOneWidget);
      },
    );

    testWidgets(
      'justSubmitted=false does NOT show the banner',
      (tester) async {
        await tester.pumpWidget(_wrap(
          statusBuilder: (_) async => const TechnicianStatusPending(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Application sent'), findsNothing);
      },
    );
  });

  group('PendingApprovalScreen — rejected variant', () {
    testWidgets(
      'justSubmitted banner suppressed on rejected variant',
      (tester) async {
        // Even if the user lands via /technician/success after re-apply
        // and the new status is REJECTED, the banner is purely a
        // pending-state acknowledgement. Showing it alongside the
        // rejected hero would be tonally wrong.
        await tester.pumpWidget(_wrap(
          statusBuilder: (_) async => const TechnicianStatusRejected(
            reason: 'CNIC unreadable',
          ),
          justSubmitted: true,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Application sent'), findsNothing);
      },
    );

    testWidgets(
      'renders the rejection reason and re-apply CTA',
      (tester) async {
        await tester.pumpWidget(_wrap(
          statusBuilder: (_) async => const TechnicianStatusRejected(
            reason: 'CNIC image was illegible.',
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Not approved'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
        expect(find.text('CNIC image was illegible.'), findsOneWidget);
        expect(find.text('Submit a new application'), findsOneWidget);
        // AppBar back arrow is the single exit; no other escape CTAs.
        expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
        expect(find.text('Continue as customer'), findsNothing);
        expect(find.text('Sign out'), findsNothing);
      },
    );

    testWidgets('reason card is hidden when reason is null', (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => const TechnicianStatusRejected(reason: null),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Not approved'), findsOneWidget);
      // The re-apply CTA stays on even without a reason — REJECTED is
      // REJECTED.
      expect(find.text('Submit a new application'), findsOneWidget);
    });

    testWidgets('reason card is hidden when reason is empty string',
        (tester) async {
      await tester.pumpWidget(_wrap(
        statusBuilder: (_) async => const TechnicianStatusRejected(reason: ''),
      ));
      await tester.pumpAndSettle();

      // No reason copy rendered.
      expect(find.byType(Icon), findsWidgets); // hero icon at minimum
      expect(find.text(''), findsNothing);
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
      // AppBar back arrow is the exit; no in-body Sign-out CTA.
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
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

      expect(find.textContaining("couldn't reach the server"),
          findsOneWidget);
    });
  });

  group('PendingApprovalScreen — transient variants', () {
    testWidgets(
      'APPROVED state shows the spinner (router will redirect away on next frame)',
      (tester) async {
        await tester.pumpWidget(_wrap(
          statusBuilder: (_) async => const TechnicianStatusApproved(),
        ));
        await tester.pump();
        await tester.pump();

        // Same loading shim as AsyncLoading — never render misleading
        // pending/rejected copy.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Not approved'), findsNothing);
        expect(find.text('Under review'), findsNothing);
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

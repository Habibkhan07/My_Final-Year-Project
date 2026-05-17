import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';
import 'package:frontend/features/technician/dashboard/presentation/widgets/dashboard_header.dart';

import '../../_helpers/test_overrides.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

TechnicianDashboardEntity _entity({
  bool isOnline = true,
  double walletBalance = 1500.0,
}) => TechnicianDashboardEntity(
  walletBalance: walletBalance,
  isOnline: isOnline,
  profilePicture: null,
  upNextJob: null,
  laterTodayJobs: const [],
);

Widget buildHeader({
  required TechnicianDashboardEntity dashboard,
  bool isToggleLoading = false,
  ValueChanged<bool>? onToggle,
}) => dashboardScope(
  child: MaterialApp(
    home: Scaffold(
      body: DashboardHeader(
        dashboard: dashboard,
        isToggleLoading: isToggleLoading,
        onToggle: onToggle ?? (_) {},
      ),
    ),
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DashboardHeader', () {
    // -----------------------------------------------------------------------
    group('identity stripped from header', () {
      // Avatar and "Hi, {firstName}" moved to the Profile tab; the dashboard
      // top bar is now status-only. These finders pin that contract so a
      // future refactor doesn't accidentally restore the identity row.
      testWidgets('does not render a greeting', (tester) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity()));
        await tester.pump();
        expect(find.textContaining('Hi,'), findsNothing);
      });

      testWidgets('does not render the avatar fallback person icon', (
        tester,
      ) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity()));
        await tester.pump();
        expect(find.byIcon(Icons.person_outline), findsNothing);
      });

      testWidgets('does not render legacy "FIELD_OPS v1.0" branding', (
        tester,
      ) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity()));
        await tester.pump();
        expect(find.text('FIELD_OPS v1.0'), findsNothing);
        expect(find.text('Technician Dashboard'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    group('online/offline toggle — render', () {
      testWidgets('shows ONLINE chip when isOnline is true', (tester) async {
        await tester.pumpWidget(
          buildHeader(dashboard: _entity(isOnline: true)),
        );
        await tester.pump();
        expect(find.text('ONLINE'), findsOneWidget);
        expect(find.text('OFFLINE'), findsNothing);
      });

      testWidgets('shows OFFLINE chip when isOnline is false', (tester) async {
        await tester.pumpWidget(
          buildHeader(dashboard: _entity(isOnline: false)),
        );
        await tester.pump();
        expect(find.text('OFFLINE'), findsOneWidget);
        expect(find.text('ONLINE'), findsNothing);
      });

      testWidgets(
        'shows CircularProgressIndicator inside toggle when loading',
        (tester) async {
          await tester.pumpWidget(
            buildHeader(dashboard: _entity(), isToggleLoading: true),
          );
          await tester.pump();
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );

      testWidgets('hides progress indicator when not loading', (tester) async {
        await tester.pumpWidget(
          buildHeader(dashboard: _entity(), isToggleLoading: false),
        );
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    group('online/offline toggle — interaction', () {
      testWidgets('calls onToggle(false) when tapped while currently online', (
        tester,
      ) async {
        bool? toggledTo;
        await tester.pumpWidget(
          buildHeader(
            dashboard: _entity(isOnline: true),
            onToggle: (val) => toggledTo = val,
          ),
        );
        await tester.pump();

        await tester.tap(find.text('ONLINE'));
        expect(toggledTo, false);
      });

      testWidgets('calls onToggle(true) when tapped while currently offline', (
        tester,
      ) async {
        bool? toggledTo;
        await tester.pumpWidget(
          buildHeader(
            dashboard: _entity(isOnline: false),
            onToggle: (val) => toggledTo = val,
          ),
        );
        await tester.pump();

        await tester.tap(find.text('OFFLINE'));
        expect(toggledTo, true);
      });

      testWidgets('does not invoke onToggle when isToggleLoading is true', (
        tester,
      ) async {
        int callCount = 0;
        await tester.pumpWidget(
          buildHeader(
            dashboard: _entity(isOnline: true),
            isToggleLoading: true,
            onToggle: (_) => callCount++,
          ),
        );
        await tester.pump();

        await tester.tap(
          find.byType(CircularProgressIndicator),
          warnIfMissed: false,
        );
        expect(callCount, 0);
      });
    });

    // -----------------------------------------------------------------------
    group('wallet pill', () {
      // The wallet pill now uses the wallet icon + amount (no "Wallet:"
      // prefix). Icon + amount is the standard fintech pattern; the
      // route destination (/wallet) makes the noun self-evident.
      testWidgets('displays balance as "Rs. {amount}" without prefix', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildHeader(dashboard: _entity(walletBalance: 750)),
        );
        await tester.pump();
        expect(find.text('Rs. 750'), findsOneWidget);
        expect(find.textContaining('Wallet:'), findsNothing);
      });

      testWidgets(
        'whole-rupee balance renders without trailing ".00" (formatRs contract)',
        (tester) async {
          await tester.pumpWidget(
            buildHeader(dashboard: _entity(walletBalance: 2000.0)),
          );
          await tester.pump();
          expect(find.text('Rs. 2000'), findsOneWidget);
        },
      );

      testWidgets(
        'fractional balance shows 2dp (formatRs contract)',
        (tester) async {
          await tester.pumpWidget(
            buildHeader(dashboard: _entity(walletBalance: 1234.5)),
          );
          await tester.pump();
          expect(find.text('Rs. 1234.50'), findsOneWidget);
        },
      );

      testWidgets('renders the wallet icon as the leading affordance', (
        tester,
      ) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity()));
        await tester.pump();
        expect(
          find.byIcon(Icons.account_balance_wallet_outlined),
          findsOneWidget,
        );
      });
    });

    // -----------------------------------------------------------------------
    group('bell icon removal', () {
      testWidgets('does not render notifications bell', (tester) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity()));
        await tester.pump();
        expect(find.byIcon(Icons.notifications_outlined), findsNothing);
        expect(find.byIcon(Icons.notifications), findsNothing);
      });
    });
  });
}

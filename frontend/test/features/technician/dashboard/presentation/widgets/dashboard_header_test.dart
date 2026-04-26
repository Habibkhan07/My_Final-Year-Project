import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';
import 'package:frontend/features/technician/dashboard/presentation/widgets/dashboard_header.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

TechnicianDashboardEntity _entity({
  bool isOnline = true,
  double walletBalance = 1500.0,
  String? profilePicture,
}) =>
    TechnicianDashboardEntity(
      walletBalance: walletBalance,
      isOnline: isOnline,
      profilePicture: profilePicture,
      upNextJob: null,
      laterTodayJobs: const [],
      metrics: const DashboardMetricsEntity(
        jobsCompletedToday: 0,
        cashCollectedToday: 0,
      ),
    );

Widget buildHeader({
  required TechnicianDashboardEntity dashboard,
  bool isToggleLoading = false,
  ValueChanged<bool>? onToggle,
}) =>
    MaterialApp(
      home: Scaffold(
        body: DashboardHeader(
          dashboard: dashboard,
          isToggleLoading: isToggleLoading,
          onToggle: onToggle ?? (_) {},
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DashboardHeader', () {
    // -----------------------------------------------------------------------
    group('online/offline toggle — render', () {
      testWidgets('shows "Online" chip text when isOnline is true', (tester) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity(isOnline: true)));
        expect(find.text('Online'), findsOneWidget);
        expect(find.text('Offline'), findsNothing);
      });

      testWidgets('shows "Offline" chip text when isOnline is false', (tester) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity(isOnline: false)));
        expect(find.text('Offline'), findsOneWidget);
        expect(find.text('Online'), findsNothing);
      });

      testWidgets('shows CircularProgressIndicator inside toggle when loading',
          (tester) async {
        await tester.pumpWidget(buildHeader(
          dashboard: _entity(),
          isToggleLoading: true,
        ));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides progress indicator when not loading', (tester) async {
        await tester.pumpWidget(buildHeader(
          dashboard: _entity(),
          isToggleLoading: false,
        ));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    group('online/offline toggle — interaction', () {
      testWidgets('calls onToggle(false) when tapped while currently online',
          (tester) async {
        bool? toggledTo;
        await tester.pumpWidget(buildHeader(
          dashboard: _entity(isOnline: true),
          onToggle: (val) => toggledTo = val,
        ));

        await tester.tap(find.text('Online'));
        expect(toggledTo, false);
      });

      testWidgets('calls onToggle(true) when tapped while currently offline',
          (tester) async {
        bool? toggledTo;
        await tester.pumpWidget(buildHeader(
          dashboard: _entity(isOnline: false),
          onToggle: (val) => toggledTo = val,
        ));

        await tester.tap(find.text('Offline'));
        expect(toggledTo, true);
      });

      testWidgets('does not invoke onToggle when isToggleLoading is true',
          (tester) async {
        int callCount = 0;
        await tester.pumpWidget(buildHeader(
          dashboard: _entity(isOnline: true),
          isToggleLoading: true,
          onToggle: (_) => callCount++,
        ));

        // GestureDetector is disabled (onTap: null) when loading — tap should
        // not reach the callback.
        await tester.tap(
          find.byType(CircularProgressIndicator),
          warnIfMissed: false,
        );
        expect(callCount, 0);
      });
    });

    // -----------------------------------------------------------------------
    group('wallet badge', () {
      testWidgets('displays balance as "Rs. {amount}"', (tester) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity(walletBalance: 750)));
        expect(find.text('Rs. 750'), findsOneWidget);
      });

      testWidgets('formats integer balance without decimals', (tester) async {
        await tester.pumpWidget(
          buildHeader(dashboard: _entity(walletBalance: 2000.0)),
        );
        expect(find.text('Rs. 2000'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('avatar', () {
      testWidgets('shows fallback person_outline icon when profilePicture is null',
          (tester) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity(profilePicture: null)));
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });

      testWidgets('renders CircleAvatar (not fallback) when profilePicture is set',
          (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(buildHeader(
            dashboard: _entity(profilePicture: 'https://example.com/pic.jpg'),
          ));
          await tester.pump();

          // Fallback icon must be absent; CircleAvatar must be present.
          expect(find.byIcon(Icons.person_outline), findsNothing);
          expect(find.byType(CircleAvatar), findsOneWidget);
        });
      });
    });

    // -----------------------------------------------------------------------
    group('app title', () {
      testWidgets('renders FIELD_OPS branding text', (tester) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity()));
        expect(find.text('FIELD_OPS v1.0'), findsOneWidget);
        expect(find.text('Technician Dashboard'), findsOneWidget);
      });
    });
  });
}

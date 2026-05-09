import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';
import 'package:frontend/features/technician/dashboard/presentation/widgets/dashboard_header.dart';

import '../../_helpers/test_overrides.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

TechnicianDashboardEntity _entity({
  bool isOnline = true,
  double walletBalance = 1500.0,
  String? profilePicture,
}) => TechnicianDashboardEntity(
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
    group('greeting', () {
      testWidgets('renders "Hi, {firstName}" from authProvider', (
        tester,
      ) async {
        await tester.pumpWidget(buildHeader(dashboard: _entity()));
        await tester.pump();
        expect(find.text('Hi, Ali'), findsOneWidget);
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
      testWidgets('displays balance as "Wallet: Rs. {amount}"', (tester) async {
        await tester.pumpWidget(
          buildHeader(dashboard: _entity(walletBalance: 750)),
        );
        await tester.pump();
        expect(find.text('Wallet: Rs. 750'), findsOneWidget);
      });

      testWidgets('formats integer balance without decimals', (tester) async {
        await tester.pumpWidget(
          buildHeader(dashboard: _entity(walletBalance: 2000.0)),
        );
        await tester.pump();
        expect(find.text('Wallet: Rs. 2000'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('avatar', () {
      testWidgets(
        'shows fallback person_outline icon when profilePicture is null',
        (tester) async {
          await tester.pumpWidget(
            buildHeader(dashboard: _entity(profilePicture: null)),
          );
          await tester.pump();
          expect(find.byIcon(Icons.person_outline), findsOneWidget);
        },
      );

      testWidgets('renders no fallback icon when profilePicture is set', (
        tester,
      ) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            buildHeader(
              dashboard: _entity(profilePicture: 'https://example.com/pic.jpg'),
            ),
          );
          await tester.pump();
          // Avatar uses CachedNetworkImage in a ClipOval; the fallback icon
          // should not be rendered when an image URL is provided. The image
          // itself may not have loaded under mock — that's fine, the test
          // is about absence of fallback.
          expect(find.byIcon(Icons.person_outline), findsNothing);
        });
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

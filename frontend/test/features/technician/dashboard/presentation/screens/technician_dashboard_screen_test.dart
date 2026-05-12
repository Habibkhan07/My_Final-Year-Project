import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shimmer/shimmer.dart';

import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';
import 'package:frontend/features/technician/dashboard/domain/failures/technician_dashboard_failure.dart';
import 'package:frontend/features/technician/dashboard/presentation/notifiers/technician_dashboard_notifier.dart';
import 'package:frontend/features/technician/dashboard/presentation/providers/current_position_provider.dart';
import 'package:frontend/features/technician/dashboard/presentation/screens/technician_dashboard_screen.dart';
import 'package:frontend/features/technician/dashboard/presentation/state/technician_dashboard_state.dart';
import 'package:frontend/features/technician/metrics/domain/entities/technician_metrics_entity.dart';
import 'package:frontend/features/technician/metrics/presentation/notifiers/metrics_notifier.dart';

import '../../_helpers/test_overrides.dart';

class _MockMetricsNotifier extends MetricsNotifier {
  @override
  Future<TechnicianMetricsEntity> build() async => const TechnicianMetricsEntity(
    jobsCompletedToday: 3,
    cashCollectedToday: 4500.0,
    commissionDeductedToday: 900.0,
    jobsCompletedThisWeek: 10,
    cashCollectedThisWeek: 18000.0,
  );
}

// ---------------------------------------------------------------------------
// Mock notifier — overrides build() to return a fixed state so widget tests
// never touch the real repository or HTTP layer.
// ---------------------------------------------------------------------------

class MockTechnicianDashboardNotifier extends TechnicianDashboardNotifier {
  final AsyncValue<TechnicianDashboardState> _mockState;
  MockTechnicianDashboardNotifier(this._mockState);

  @override
  Future<TechnicianDashboardState> build() async {
    if (_mockState is AsyncData<TechnicianDashboardState>) {
      return _mockState.requireValue;
    }
    if (_mockState is AsyncError<TechnicianDashboardState>) {
      throw (_mockState as AsyncError).error;
    }
    // AsyncLoading: stall forever so the skeleton stays visible.
    return Completer<TechnicianDashboardState>().future;
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

TechnicianDashboardEntity _entity({
  bool isOnline = true,
  double walletBalance = 1500.0,
  bool includeUpNextJob = true,
}) => TechnicianDashboardEntity(
  walletBalance: walletBalance,
  isOnline: isOnline,
  profilePicture: 'https://example.com/pic.jpg',
  upNextJob: includeUpNextJob
      ? UpNextJobEntity(
          jobId: 1,
          serviceTitle: 'AC Deep Wash',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          customerName: 'Ali R.',
          customerPhone: '+923001234567',
          addressText: '14 Street, Gulberg III',
          lat: 31.5204,
          lng: 74.3587,
        )
      : null,
  laterTodayJobs: [
    LaterTodayJobEntity(
      jobId: 2,
      serviceTitle: 'Ceiling Fan Repair',
      scheduledTime: DateTime.now().add(const Duration(hours: 3)),
      addressText: 'DHA Phase 5',
    ),
  ],
);

TechnicianDashboardState _state({
  bool isOnline = true,
  double walletBalance = 1500.0,
  bool includeUpNextJob = true,
}) => TechnicianDashboardState(
  dashboard: _entity(
    isOnline: isOnline,
    walletBalance: walletBalance,
    includeUpNextJob: includeUpNextJob,
  ),
);

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget buildScreen(AsyncValue<TechnicianDashboardState> mockState) {
  // Manual ProviderScope here (rather than dashboardScope) so we can stack
  // technicianDashboardProvider on top of auth + currentPosition overrides.
  return ProviderScope(
    overrides: [
      technicianDashboardProvider.overrideWith(
        () => MockTechnicianDashboardNotifier(mockState),
      ),
      metricsProvider.overrideWith(() => _MockMetricsNotifier()),
      authProvider.overrideWith(() => FakeAuthNotifier(fakeUser)),
      currentPositionProvider.overrideWith(() => FakeCurrentPosition(null)),
    ],
    child: const MaterialApp(home: TechnicianDashboardScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TechnicianDashboardScreen', () {
    // -----------------------------------------------------------------------
    group('AsyncLoading — skeleton', () {
      testWidgets('renders Shimmer and hides job content', (tester) async {
        await tester.pumpWidget(buildScreen(const AsyncLoading()));
        await tester.pump();

        expect(find.byType(Shimmer), findsOneWidget);
        expect(find.text('AC Deep Wash'), findsNothing);
        expect(find.text('ONLINE'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    group('AsyncError — error states', () {
      testWidgets('shows network failure message and Retry button', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildScreen(
            AsyncError(const DashboardNetworkFailure(), StackTrace.empty),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('No internet connection'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('shows permission failure message', (tester) async {
        await tester.pumpWidget(
          buildScreen(
            AsyncError(const DashboardPermissionFailure(), StackTrace.empty),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('permission'), findsOneWidget);
      });

      testWidgets('shows server failure message verbatim', (tester) async {
        await tester.pumpWidget(
          buildScreen(
            AsyncError(
              const DashboardServerFailure('Backend is down.'),
              StackTrace.empty,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Backend is down.'), findsOneWidget);
      });

      testWidgets('shows parsing failure message', (tester) async {
        await tester.pumpWidget(
          buildScreen(
            AsyncError(const DashboardParsingFailure(), StackTrace.empty),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Could not read'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('AsyncData — job card', () {
      testWidgets('renders service title when upNextJob is present', (
        tester,
      ) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(buildScreen(AsyncData(_state())));
          await tester.pump();

          expect(find.text('AC Deep Wash'), findsOneWidget);
        });
      });

      testWidgets('renders customer name and address when job is present', (
        tester,
      ) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(buildScreen(AsyncData(_state())));
          await tester.pump();

          expect(find.text('Ali R.'), findsOneWidget);
          expect(find.text('14 Street, Gulberg III'), findsOneWidget);
        });
      });

      testWidgets('renders empty-state card when upNextJob is null', (
        tester,
      ) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            buildScreen(AsyncData(_state(includeUpNextJob: false))),
          );
          await tester.pump();

          expect(find.text('No upcoming jobs'), findsOneWidget);
          expect(find.text('AC Deep Wash'), findsNothing);
        });
      });
    });

    // -----------------------------------------------------------------------
    group('AsyncData — header', () {
      testWidgets('renders ONLINE toggle when isOnline is true', (
        tester,
      ) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            buildScreen(AsyncData(_state(isOnline: true))),
          );
          await tester.pump();

          expect(find.text('ONLINE'), findsOneWidget);
        });
      });

      testWidgets('renders OFFLINE toggle when isOnline is false', (
        tester,
      ) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            buildScreen(AsyncData(_state(isOnline: false))),
          );
          await tester.pump();

          expect(find.text('OFFLINE'), findsOneWidget);
        });
      });

      testWidgets('renders wallet balance with "Wallet:" label', (
        tester,
      ) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            buildScreen(AsyncData(_state(walletBalance: 1500))),
          );
          await tester.pump();

          expect(find.text('Wallet: Rs. 1500'), findsOneWidget);
        });
      });

      testWidgets(
        'renders greeting with technician firstName from auth cache',
        (tester) async {
          await mockNetworkImagesFor(() async {
            await tester.pumpWidget(buildScreen(AsyncData(_state())));
            // Two pumps: one to resolve the dashboard provider, one to resolve
            // the auth provider's async build() before the greeting renders.
            await tester.pump();
            await tester.pump();

            expect(find.text('Hi, Ali'), findsOneWidget);
          });
        },
      );
    });

    // -----------------------------------------------------------------------
    group('AsyncData — later today list', () {
      testWidgets('renders later-today job titles', (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(buildScreen(AsyncData(_state())));
          await tester.pump();

          expect(find.text('Ceiling Fan Repair'), findsOneWidget);
        });
      });
    });

    // -----------------------------------------------------------------------
    group('AsyncData — metrics row', () {
      testWidgets('renders jobs count and formatted cash from metricsProvider', (
        tester,
      ) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(buildScreen(AsyncData(_state())));
          // Two pumps: first lets the async notifier build complete, second renders.
          await tester.pump();
          await tester.pump();

          // _MockMetricsNotifier: jobsCompletedToday: 3
          expect(find.text('3'), findsWidgets);
          // cashCollectedToday: 4500 → "Rs. 4,500"
          expect(find.text('Rs. 4,500'), findsOneWidget);
          // commission: 900 → "Rs. 900"
          expect(find.text('Rs. 900'), findsOneWidget);
        });
      });
    });

    // -----------------------------------------------------------------------
    group('AsyncData — bottom navigation', () {
      testWidgets('renders all four nav tab labels', (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(buildScreen(AsyncData(_state())));
          await tester.pump();

          expect(find.text('Jobs'), findsOneWidget);
          expect(find.text('Schedule'), findsOneWidget);
          expect(find.text('Metrics'), findsOneWidget);
          expect(find.text('Profile'), findsOneWidget);
        });
      });
    });
  });
}

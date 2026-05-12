// Widget tests for `OrchestratorHeroHeader`.
//
// Contract (post-polish):
//   * Renders the status label from `ui.statusLabel`.
//   * Renders a dynamic subtitle derived from the booking's status +
//     phaseTimestamps (e.g., "Tracking live" for EN_ROUTE, "Arrived
//     just now" for ARRIVED with a recent timestamp).
//   * Does NOT render the counterparty name (BookingSummaryCard owns it).
//   * Renders "Rescheduled from #N" when parentBookingId is set.
//   * Renders "Continued on #N" (with tap-navigation) when CANCELLED +
//     childBookingId.
//   * Calls onBack / onHelp from the icon buttons.
//   * Disables the help button when onHelp is null.
//
// Migrated coverage from the deleted `header_slot_test.dart`:
//   * "Continued on #N" only on CANCELLED + childBookingId.
//   * "Rescheduled from #N" on parentBookingId.
//   * Tap on "Continued on #N" navigates.
//   * Status label renders, counterparty name does not.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/orchestrator_hero_header.dart';
import 'package:go_router/go_router.dart';

import '../../_helpers/booking_detail_fixture.dart';

BookingDetail _booking({
  String status = 'CONFIRMED',
  int? parentBookingId,
  int? childBookingId,
  int currentUserId = 7,
  String statusLabel = 'Confirmed',
  String tone = 'positive',
}) {
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(
      bookingDetailJson(
        status: status,
        parentBookingId: parentBookingId,
        childBookingId: childBookingId,
        uiOverride: {
          'status_label': statusLabel,
          'body_text': '',
          'primary_action': null,
          'secondary_actions': <Map<String, dynamic>>[],
          'show_tracking': false,
          'show_quote_card': false,
          'show_dispute_button': false,
          'tone': tone,
        },
      ),
    ),
    currentUserId: currentUserId,
  );
}

Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(
        path: '/host',
        builder: (_, _) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/booking/:job_id',
        builder: (_, state) => Scaffold(
          body: Text(
            'CHILD ${state.pathParameters['job_id']}',
            key: const ValueKey('child-screen'),
          ),
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('OrchestratorHeroHeader', () {
    testWidgets('renders the status label from ui.statusLabel', (tester) async {
      final booking = _booking();
      await tester.pumpWidget(_wrap(
        OrchestratorHeroHeader(
          booking: booking,
          onBack: () {},
          onHelp: () {},
        ),
      ));
      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('renders dynamic subtitle for EN_ROUTE ("Tracking live")', (
      tester,
    ) async {
      final booking = _booking(
        status: 'EN_ROUTE',
        statusLabel: 'On the way',
        tone: 'positive',
      );
      await tester.pumpWidget(_wrap(
        OrchestratorHeroHeader(
          booking: booking,
          onBack: () {},
          onHelp: () {},
        ),
      ));
      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('Tracking live'), findsOneWidget);
    });

    testWidgets(
      'renders booking tag "Booking #N"',
      (tester) async {
        final booking = _booking();
        await tester.pumpWidget(_wrap(
          OrchestratorHeroHeader(
            booking: booking,
            onBack: () {},
            onHelp: () {},
          ),
        ));
        expect(find.text('Booking #42'), findsOneWidget);
      },
    );

    testWidgets(
      'does NOT render counterparty name (owned by BookingSummaryCard)',
      (tester) async {
        final booking = _booking();
        await tester.pumpWidget(_wrap(
          OrchestratorHeroHeader(
            booking: booking,
            onBack: () {},
            onHelp: () {},
          ),
        ));
        expect(find.text('Ali Raza'), findsNothing);
        expect(find.text('Sara Customer'), findsNothing);
      },
    );

    testWidgets(
      'shows "Rescheduled from #N" when parentBookingId is set',
      (tester) async {
        final booking = _booking(parentBookingId: 41);
        await tester.pumpWidget(_wrap(
          OrchestratorHeroHeader(
            booking: booking,
            onBack: () {},
            onHelp: () {},
          ),
        ));
        expect(find.text('Rescheduled from #41'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "Continued on #N" only when CANCELLED + childBookingId',
      (tester) async {
        final booking = _booking(status: 'CANCELLED', childBookingId: 123);
        await tester.pumpWidget(_wrap(
          OrchestratorHeroHeader(
            booking: booking,
            onBack: () {},
            onHelp: () {},
          ),
        ));
        expect(find.text('Continued on #123'), findsOneWidget);
      },
    );

    testWidgets(
      'omits "Continued on #N" when childBookingId is null even on CANCELLED',
      (tester) async {
        final booking = _booking(status: 'CANCELLED');
        await tester.pumpWidget(_wrap(
          OrchestratorHeroHeader(
            booking: booking,
            onBack: () {},
            onHelp: () {},
          ),
        ));
        expect(find.textContaining('Continued on'), findsNothing);
      },
    );

    testWidgets(
      'omits "Continued on #N" when childBookingId set but status not CANCELLED',
      (tester) async {
        final booking = _booking(status: 'CONFIRMED', childBookingId: 123);
        await tester.pumpWidget(_wrap(
          OrchestratorHeroHeader(
            booking: booking,
            onBack: () {},
            onHelp: () {},
          ),
        ));
        expect(find.textContaining('Continued on'), findsNothing);
      },
    );

    testWidgets('tap on "Continued on #N" navigates to /booking/<child>', (
      tester,
    ) async {
      final booking = _booking(status: 'CANCELLED', childBookingId: 456);
      await tester.pumpWidget(_wrap(
        OrchestratorHeroHeader(
          booking: booking,
          onBack: () {},
          onHelp: () {},
        ),
      ));
      await tester.tap(find.text('Continued on #456'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('child-screen')), findsOneWidget);
      expect(find.text('CHILD 456'), findsOneWidget);
    });

    testWidgets('back button invokes onBack', (tester) async {
      var backCount = 0;
      final booking = _booking();
      await tester.pumpWidget(_wrap(
        OrchestratorHeroHeader(
          booking: booking,
          onBack: () => backCount++,
          onHelp: () {},
        ),
      ));
      await tester.tap(find.byTooltip('Back'));
      expect(backCount, 1);
    });

    testWidgets('help button invokes onHelp', (tester) async {
      var helpCount = 0;
      final booking = _booking();
      await tester.pumpWidget(_wrap(
        OrchestratorHeroHeader(
          booking: booking,
          onBack: () {},
          onHelp: () => helpCount++,
        ),
      ));
      await tester.tap(find.byTooltip('Help'));
      expect(helpCount, 1);
    });

    testWidgets('help button is disabled when onHelp is null', (tester) async {
      final booking = _booking();
      await tester.pumpWidget(_wrap(
        OrchestratorHeroHeader(
          booking: booking,
          onBack: () {},
          onHelp: null,
        ),
      ));
      final iconBtn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.help_outline_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(iconBtn.onPressed, isNull);
    });
  });
}

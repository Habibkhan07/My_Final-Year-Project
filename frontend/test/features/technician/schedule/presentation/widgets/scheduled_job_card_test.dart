// Tests for ScheduledJobCard — the dumb-UI seam on tech side.
//
// Server emits `ui.badgeText`, `ui.badgeTone`, `ui.headline`,
// `payout.uiLabel`, `payout.context`, `addressLabel`. The widget renders
// those verbatim and switches on `ui.badgeTone` for design tokens — never
// on raw [BookingStatus] for copy.
//
// Tests pin the contract for:
//   * Status row rendering — AWAITING / CONFIRMED / EN_ROUTE (live) /
//     COMPLETED / CANCELLED.
//   * Customer block — initials avatar fallback, customer name shown.
//   * Payout block — context + uiLabel.
//   * Address presence/absence.
//   * Tap targets — non-terminal pushes /booking/:job_id, terminal is no-op.
//   * Terminal greyscale + opacity treatment.
//   * Cancelled line-through on address.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_job.dart';
import 'package:frontend/features/technician/schedule/presentation/widgets/scheduled_job_card.dart';
import 'package:go_router/go_router.dart';

ScheduledJob _job({
  int id = 42,
  BookingStatus status = BookingStatus.confirmed,
  BookingUiTone tone = BookingUiTone.positive,
  String badgeText = 'Confirmed',
  String headline = 'Booked with Sara Ahmed',
  String? profilePictureUrl,
  String? addressLabel = 'Home — DHA Phase 5, Lahore',
  String payoutContext = 'After Rs. 405 commission',
  String payoutLabel = 'Rs. 1,620',
  String customerName = 'Sara Ahmed',
}) {
  return ScheduledJob(
    id: id,
    status: status,
    service: const ScheduledJobService(
      name: 'AC Repair',
      iconName: 'ac_repair',
    ),
    customer: ScheduledJobCustomer(
      id: 109,
      displayName: customerName,
      profilePictureUrl: profilePictureUrl,
    ),
    addressLabel: addressLabel,
    scheduledStart: DateTime(2026, 5, 6, 15, 0),
    scheduledEnd: DateTime(2026, 5, 6, 17, 0),
    createdAt: DateTime(2026, 5, 5, 9, 0),
    payout: PayoutBlock(
      amount: 1620,
      context: payoutContext,
      uiLabel: payoutLabel,
    ),
    ui: ScheduledJobUi(
      badgeText: badgeText,
      badgeTone: tone,
      headline: headline,
    ),
  );
}

GoRouter _router(Widget host, {ValueChanged<int>? onPushed}) {
  return GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(path: '/list', builder: (_, _) => Scaffold(body: host)),
      GoRoute(
        path: '/booking/:job_id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['job_id']!);
          onPushed?.call(id);
          return Scaffold(body: Center(child: Text('detail-$id')));
        },
      ),
    ],
  );
}

Widget _wrap(ScheduledJob job) {
  final card = ScheduledJobCard(
    job: job,
    serverTime: DateTime(2026, 5, 5, 12, 0),
  );
  return MaterialApp.router(routerConfig: _router(card));
}

void main() {
  group('ScheduledJobCard — status row renders', () {
    testWidgets('AWAITING — server-driven copy verbatim', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _job(
            status: BookingStatus.awaiting,
            tone: BookingUiTone.warning,
            badgeText: 'New request',
            headline: 'Tap to review — Sara Ahmed',
          ),
        ),
      );
      // Pill renders in uppercase.
      expect(find.text('NEW REQUEST'), findsOneWidget);
      expect(find.text('Tap to review — Sara Ahmed'), findsOneWidget);
    });

    testWidgets('CONFIRMED', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _job(
            status: BookingStatus.confirmed,
            tone: BookingUiTone.positive,
            badgeText: 'Confirmed',
            headline: 'Booked with Sara Ahmed',
          ),
        ),
      );
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Booked with Sara Ahmed'), findsOneWidget);
    });

    testWidgets('EN_ROUTE — live status renders pulsing dot', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _job(
            status: BookingStatus.enRoute,
            tone: BookingUiTone.info,
            badgeText: 'On the way',
            headline: "You're on the way to Sara Ahmed",
          ),
        ),
      );
      expect(find.text('ON THE WAY'), findsOneWidget);
      // The live dot is a small SizedBox(14x14) by the pill. It's hard
      // to assert by type without exposing it, so we settle for the
      // headline + badge.
      expect(find.text("You're on the way to Sara Ahmed"), findsOneWidget);
      // No exception during initial frame — _LivePulseDot's repeat()
      // is guarded against test bindings so pumpAndSettle wouldn't stall.
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('COMPLETED', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _job(
            status: BookingStatus.completed,
            tone: BookingUiTone.positive,
            badgeText: 'Completed',
            headline: 'Completed for Sara Ahmed',
          ),
        ),
      );
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Completed for Sara Ahmed'), findsOneWidget);
    });

    testWidgets('CANCELLED with neutral tone', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _job(
            status: BookingStatus.cancelled,
            tone: BookingUiTone.neutral,
            badgeText: 'Cancelled',
            headline: 'Sara Ahmed cancelled',
          ),
        ),
      );
      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('Sara Ahmed cancelled'), findsOneWidget);
    });
  });

  group('ScheduledJobCard — customer + payout blocks', () {
    testWidgets(
      'profilePictureUrl == null shows initials avatar (SA for Sara Ahmed)',
      (tester) async {
        await tester.pumpWidget(_wrap(_job(profilePictureUrl: null)));
        expect(find.text('SA'), findsOneWidget);
      },
    );

    testWidgets('payout uiLabel + context render', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _job(
            payoutContext: 'After Rs. 405 commission',
            payoutLabel: 'Rs. 1,620',
          ),
        ),
      );
      expect(find.text('After Rs. 405 commission'), findsOneWidget);
      expect(find.text('Rs. 1,620'), findsOneWidget);
    });

    testWidgets(
      'empty payout context hides the wallet icon but keeps the amount',
      (tester) async {
        await tester.pumpWidget(_wrap(_job(payoutContext: '')));
        expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
        expect(find.text('Rs. 1,620'), findsOneWidget);
      },
    );

    testWidgets('null addressLabel hides the address row', (tester) async {
      await tester.pumpWidget(_wrap(_job(addressLabel: null)));
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('non-null addressLabel renders with icon', (tester) async {
      await tester.pumpWidget(
        _wrap(_job(addressLabel: 'Home — DHA Phase 5, Lahore')),
      );
      expect(find.text('Home — DHA Phase 5, Lahore'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });
  });

  group('ScheduledJobCard — tap target', () {
    testWidgets('non-terminal status tap pushes /booking/:id', (tester) async {
      int? pushedId;
      final card = ScheduledJobCard(
        job: _job(id: 42, status: BookingStatus.confirmed),
        serverTime: DateTime(2026, 5, 5, 12, 0),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _router(card, onPushed: (id) => pushedId = id),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(pushedId, 42);
      expect(find.text('detail-42'), findsOneWidget);
    });

    testWidgets('IN_PROGRESS tap pushes /booking/:id', (tester) async {
      // Active mid-job — same nav target as Confirmed.
      int? pushedId;
      final card = ScheduledJobCard(
        job: _job(id: 99, status: BookingStatus.inProgress),
        serverTime: DateTime(2026, 5, 5, 12, 0),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _router(card, onPushed: (id) => pushedId = id),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(pushedId, 99);
    });

    testWidgets(
      'terminal status (COMPLETED) tap is no-op (no nav happens)',
      (tester) async {
        int? pushedId;
        final card = ScheduledJobCard(
          job: _job(id: 7, status: BookingStatus.completed),
          serverTime: DateTime(2026, 5, 5, 12, 0),
        );
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: _router(card, onPushed: (id) => pushedId = id),
          ),
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(pushedId, isNull);
        expect(find.text('detail-7'), findsNothing);
      },
    );

    testWidgets('terminal status (CANCELLED) tap is no-op', (tester) async {
      int? pushedId;
      final card = ScheduledJobCard(
        job: _job(id: 8, status: BookingStatus.cancelled),
        serverTime: DateTime(2026, 5, 5, 12, 0),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _router(card, onPushed: (id) => pushedId = id),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(pushedId, isNull);
    });

    testWidgets('terminal status (TECH_DECLINED) tap is no-op', (tester) async {
      int? pushedId;
      final card = ScheduledJobCard(
        job: _job(id: 9, status: BookingStatus.techDeclined),
        serverTime: DateTime(2026, 5, 5, 12, 0),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _router(card, onPushed: (id) => pushedId = id),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(pushedId, isNull);
    });
  });

  group('ScheduledJobCard — terminal visual treatment', () {
    testWidgets(
      'terminal card wraps body in 0.70 opacity + greyscale ColorFiltered',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _job(
              status: BookingStatus.completed,
              tone: BookingUiTone.positive,
              badgeText: 'Completed',
              headline: 'Completed for Sara Ahmed',
            ),
          ),
        );

        final opacities = tester
            .widgetList<Opacity>(find.byType(Opacity))
            .map((o) => o.opacity)
            .toList();
        expect(
          opacities,
          contains(0.70),
          reason: 'terminal cards must wrap in Opacity(0.70)',
        );
        expect(find.byType(ColorFiltered), findsWidgets);
      },
    );

    testWidgets(
      'non-terminal card does NOT wrap body in 0.70 opacity',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _job(
              status: BookingStatus.confirmed,
              tone: BookingUiTone.positive,
            ),
          ),
        );
        final opacities = tester
            .widgetList<Opacity>(find.byType(Opacity))
            .map((o) => o.opacity)
            .toList();
        // 0.70 specifically is the terminal-card decay; widget can still
        // contain other Opacity values from sub-widgets (e.g. Material).
        expect(opacities, isNot(contains(0.70)));
      },
    );

    testWidgets('CANCELLED — address renders with line-through decoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _job(
            status: BookingStatus.cancelled,
            tone: BookingUiTone.neutral,
            badgeText: 'Cancelled',
            headline: 'Sara Ahmed cancelled',
            addressLabel: 'Home — DHA Phase 5',
          ),
        ),
      );
      final addressText = tester.widget<Text>(
        find.text('Home — DHA Phase 5'),
      );
      expect(addressText.style?.decoration, TextDecoration.lineThrough);
    });
  });
}

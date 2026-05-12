// Widget tests for `SecondaryActionsSlot`.
//
// Contract (post item #4 — `feedback_cancel_vs_no_show.md`):
//   * Renders only *forward* secondary actions inline (style != destructive).
//   * Destructive actions (cancel / tech-cancel) are filtered out — they
//     live behind the orchestrator app-bar Help icon now (`HelpSheet`).
//   * `showDisputeButton` is no longer this slot's concern — `HelpSheet`
//     reads it directly from the booking and surfaces dispute there.
//   * When no forward actions exist the slot renders nothing (no padding
//     eating vertical space above the primary action).
//
// Regression vectors retained:
//   * Wrap.runSpacing must remain positive (#B-56).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/slots/secondary_actions_slot.dart';

import '../../../_helpers/booking_detail_fixture.dart';

BookingDetail _booking({
  bool showDispute = false,
  List<Map<String, dynamic>> secondary = const [],
}) {
  final json = bookingDetailJson(
    uiOverride: {
      'status_label': 'X',
      'body_text': '',
      'primary_action': null,
      'secondary_actions': secondary,
      'show_tracking': false,
      'show_quote_card': false,
      'show_dispute_button': showDispute,
      'tone': 'neutral',
    },
  );
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(json),
    currentUserId: 7,
  );
}

void main() {
  group('SecondaryActionsSlot', () {
    testWidgets('Wrap.runSpacing is positive (#B-56 regression guard)', (
      tester,
    ) async {
      // The bug was `runSpacing: -4`, which made adjacent rows overlap
      // visually after a reflow. Pin the contract: > 0.
      final booking = _booking(
        secondary: [
          {
            'label': 'Add upsell',
            'endpoint': '/bookings/1/quotes/',
            'method': 'POST',
            'style': 'primary',
          },
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SecondaryActionsSlot(booking: booking)),
          ),
        ),
      );

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.runSpacing, greaterThan(0));
      expect(wrap.spacing, greaterThan(0));
    });

    testWidgets('destructive actions are filtered out (move to Help)', (
      tester,
    ) async {
      // Cancel lives behind the Help icon now. Even when the server
      // emits it in secondary_actions, the slot must not render it.
      final booking = _booking(
        secondary: [
          {
            'label': 'Cancel',
            'endpoint': '/bookings/1/cancel/',
            'method': 'POST',
            'style': 'destructive',
          },
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SecondaryActionsSlot(booking: booking)),
          ),
        ),
      );
      // No Cancel button, no Wrap at all — slot short-circuits to shrink
      // because the only action was filtered out.
      expect(find.text('Cancel'), findsNothing);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets(
      'forward (non-destructive) actions render inline',
      (tester) async {
        final booking = _booking(
          secondary: [
            {
              'label': 'Add upsell',
              'endpoint': '/bookings/1/quotes/',
              'method': 'POST',
              'style': 'primary',
            },
            {
              'label': 'Cancel',
              'endpoint': '/bookings/1/cancel/',
              'method': 'POST',
              'style': 'destructive',
            },
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: SecondaryActionsSlot(booking: booking)),
            ),
          ),
        );
        // The forward action renders; the destructive one is filtered.
        expect(find.text('Add upsell'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
      },
    );

    testWidgets('reschedule is filtered out (Help owns it now)', (
      tester,
    ) async {
      // Per the same exit-vs-forward rule as Cancel: `/reschedule/` is
      // a time-change verb, not a forward step. SecondaryActionsSlot
      // filters it out; HelpSheet surfaces it.
      final booking = _booking(
        secondary: [
          {
            'label': 'Reschedule',
            'endpoint': '/bookings/1/reschedule/',
            'method': 'POST',
            'style': 'neutral',
          },
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SecondaryActionsSlot(booking: booking)),
          ),
        ),
      );
      expect(find.text('Reschedule'), findsNothing);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('dispute is NOT rendered inline (Help owns it now)', (
      tester,
    ) async {
      // `showDisputeButton: true` used to surface an "Open dispute"
      // button here. Post item #4 it lives in HelpSheet only.
      final booking = _booking(showDispute: true);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SecondaryActionsSlot(booking: booking)),
          ),
        ),
      );
      expect(find.text('Open dispute'), findsNothing);
    });

    testWidgets('renders nothing (SizedBox.shrink) when slot is empty', (
      tester,
    ) async {
      // No actions, no dispute → the slot must short-circuit so it
      // doesn't take vertical space above the primary action button.
      final booking = _booking();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SecondaryActionsSlot(booking: booking)),
          ),
        ),
      );
      // No Wrap should be in the tree under this slot.
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets(
      'request-revision action is relabelled to "Negotiate price"',
      (tester) async {
        // Post-arrival the customer + technician are face-to-face; the
        // wire's "Ask for a revision" framing is a remote-ticket
        // misnomer for this market. The slot rewrites the label to
        // "Negotiate price" — a hint that the bargain happens in
        // person with the tech standing right there. The endpoint
        // (and therefore the actual server-side action) is unchanged.
        //
        // The visibility of `/request-revision/` is now server-driven
        // (Dumb UI): the backend omits the action when every line
        // item is a fixed-price sub-service. This test pins only the
        // label rewrite; the omission is covered by the backend's
        // selector tests.
        final booking = _booking(
          secondary: [
            {
              'label': 'Ask for a revision',
              'endpoint': '/bookings/1/quotes/9/request-revision/',
              'method': 'POST',
              'style': 'neutral',
            },
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: SecondaryActionsSlot(booking: booking)),
            ),
          ),
        );
        expect(find.text('Negotiate price'), findsOneWidget);
        expect(find.text('Ask for a revision'), findsNothing);
      },
    );
  });
}

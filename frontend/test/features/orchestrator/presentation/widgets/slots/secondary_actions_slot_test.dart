// Widget tests for `SecondaryActionsSlot`.
//
// Regression vectors:
//   * Wrap.runSpacing must be POSITIVE (#B-56). It used to be -4 which
//     visually overlapped rows when the wrap reflowed (e.g. QUOTED has
//     3+ secondary actions on narrow phones).
//   * `showDisputeButton: true` must surface the "Open dispute" button
//     (#B-55).
//   * When neither secondary actions nor dispute exist, the slot must
//     render nothing (no padding eating space).
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
            'label': 'A',
            'endpoint': '/bookings/1/cancel/',
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

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.runSpacing, greaterThan(0));
      expect(wrap.spacing, greaterThan(0));
    });

    testWidgets('renders the dispute button when showDisputeButton is true', (
      tester,
    ) async {
      final booking = _booking(showDispute: true);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SecondaryActionsSlot(booking: booking)),
          ),
        ),
      );
      expect(find.text('Open dispute'), findsOneWidget);
    });

    testWidgets('omits the dispute button when showDisputeButton is false', (
      tester,
    ) async {
      final booking = _booking(showDispute: false);
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
  });
}

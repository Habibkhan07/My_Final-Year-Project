// Widget tests for `OrchestratorActionBar`.
//
// Contract:
//   * Hosts both SecondaryActionsSlot and PrimaryActionSlot.
//   * Renders nothing extraneous when neither slot has anything to
//     render (no padding eating vertical space above the screen edge).
//   * Honors MediaQuery.viewPadding.bottom — primary CTA sits clear of
//     the gesture nav region.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/orchestrator_action_bar.dart';

import '../../_helpers/booking_detail_fixture.dart';

BookingDetail _booking({
  Map<String, dynamic>? primary,
  List<Map<String, dynamic>> secondary = const [],
}) {
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(
      bookingDetailJson(
        uiOverride: {
          'status_label': 'X',
          'body_text': '',
          'primary_action': primary,
          'secondary_actions': secondary,
          'show_tracking': false,
          'show_quote_card': false,
          'show_dispute_button': false,
          'tone': 'neutral',
        },
      ),
    ),
    currentUserId: 7,
  );
}

Widget _wrap(Widget child, {double bottomPadding = 0}) {
  return ProviderScope(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          padding: EdgeInsets.only(bottom: bottomPadding),
          viewPadding: EdgeInsets.only(bottom: bottomPadding),
        ),
        child: Scaffold(body: Column(children: [const Spacer(), child])),
      ),
    ),
  );
}

void main() {
  group('OrchestratorActionBar', () {
    testWidgets('renders the primary action button', (tester) async {
      final booking = _booking(
        primary: {
          'label': 'Confirm',
          'endpoint': '/bookings/1/confirm/',
          'method': 'POST',
          'style': 'primary',
        },
      );
      await tester.pumpWidget(_wrap(OrchestratorActionBar(booking: booking)));
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets(
      'renders forward secondary actions inline (destructive filtered)',
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
        await tester.pumpWidget(_wrap(OrchestratorActionBar(booking: booking)));
        // Forward action renders; the destructive one is filtered out
        // by SecondaryActionsSlot (lives in HelpSheet now).
        expect(find.text('Add upsell'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
      },
    );

    testWidgets(
      'honors MediaQuery.viewPadding.bottom (gesture-nav inset)',
      (tester) async {
        const inset = 34.0;
        final booking = _booking(
          primary: {
            'label': 'Confirm',
            'endpoint': '/bookings/1/confirm/',
            'method': 'POST',
            'style': 'primary',
          },
        );
        await tester.pumpWidget(_wrap(
          OrchestratorActionBar(booking: booking),
          bottomPadding: inset,
        ));
        // The action bar wraps a Padding that injects the bottom inset.
        // Find it and assert the bottom padding value matches.
        final paddings = tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byType(OrchestratorActionBar),
                matching: find.byType(Padding),
              ),
            )
            .toList();
        // At least one Padding wraps the column with `bottom: inset`.
        expect(
          paddings.any((p) => p.padding.resolve(TextDirection.ltr).bottom == inset),
          isTrue,
          reason:
              'OrchestratorActionBar must inject MediaQuery.viewPadding.bottom',
        );
      },
    );
  });
}

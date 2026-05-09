// Tests for `PrimaryActionSlot`.
//
// Contract:
//   * `ui.primaryAction == null` → SizedBox.shrink (no chrome, no
//     padding eating space). The slot is hidden when the role/status
//     has no actionable verb.
//   * `ui.primaryAction != null` → renders a FilledButton with the
//     server-provided label (dumb-UI: copy comes from the server).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/slots/primary_action_slot.dart';

import '../../../_helpers/booking_detail_fixture.dart';

BookingDetail _bookingNoAction() {
  // The fixture default has primary_action: null on the ui block.
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(bookingDetailJson()),
    currentUserId: 7,
  );
}

BookingDetail _bookingWithAction({
  required String label,
  String endpoint = '/bookings/42/en-route/',
  String style = 'primary',
}) {
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(bookingDetailJson(
      uiOverride: {
        'status_label': 'Confirmed',
        'body_text': '',
        'primary_action': {
          'label': label,
          'endpoint': endpoint,
          'method': 'POST',
          'style': style,
        },
        'secondary_actions': <Map<String, dynamic>>[],
        'show_tracking': false,
        'show_quote_card': false,
        'show_dispute_button': false,
        'tone': 'positive',
      },
    )),
    currentUserId: 7,
  );
}

Future<void> _pump(WidgetTester tester, BookingDetail b) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: PrimaryActionSlot(booking: b)),
    ),
  ));
}

void main() {
  testWidgets('renders SizedBox.shrink when primaryAction is null',
      (tester) async {
    await _pump(tester, _bookingNoAction());
    // No FilledButton in the tree.
    expect(find.byType(FilledButton), findsNothing);
    // The slot still mounts; its child is the shrink.
    expect(find.byType(PrimaryActionSlot), findsOneWidget);
  });

  testWidgets('renders FilledButton with server-provided label',
      (tester) async {
    await _pump(
      tester,
      _bookingWithAction(label: "I'm on the way"),
    );
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text("I'm on the way"), findsOneWidget);
  });

  testWidgets('button label is the EXACT server string (dumb-UI principle)',
      (tester) async {
    // The frontend never invents copy or transforms case. A regression
    // that did `label.toUpperCase()` would fail this test.
    await _pump(
      tester,
      _bookingWithAction(label: 'Confirm cash received'),
    );
    expect(find.text('Confirm cash received'), findsOneWidget);
    expect(find.text('CONFIRM CASH RECEIVED'), findsNothing);
  });
}

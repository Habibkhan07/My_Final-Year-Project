// Tests for `BookingOrchestratorActionButton`.
//
// The button widget classifies actions by endpoint suffix
// (BookingOrchestratorActionButton._classify) and decides:
//   * direct POST (no body) — en-route, arrived, start-inspection
//   * direct POST (auto body) — confirm-cash-received
//   * pending sheet — cancel, tech-cancel, reschedule, no-show, dispute,
//     submit-quote, request-revision
//
// Regression vectors:
//   * Direct POST passes the action to executor.execute (no body for
//     bodyless ops; auto body of {cash_amount: …} for cash collection).
//   * Cancel opens the pending sheet (we look for the title text).
//   * Busy state replaces the label with a CircularProgressIndicator.
//   * Network errors surface a SnackBar without crashing.
import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_ui_block.dart';
import 'package:frontend/features/orchestrator/presentation/providers/booking_action_executor.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/booking_orchestrator_action_button.dart';
import 'package:mocktail/mocktail.dart';

class _MockExecutor extends Mock implements BookingActionExecutor {}

class _FakeAction extends Fake implements BookingUiAction {}

BookingDetail _booking() {
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson({
      'id': 42,
      'status': 'CONFIRMED',
      'service': {'id': 1, 'name': 'Plumbing', 'icon_name': 'plumbing'},
      'sub_service': null,
      'technician': {
        'id': 99,
        'display_name': 'A',
        'profile_picture_url': null,
      },
      'customer': {'id': 7, 'full_name': 'B', 'phone_no': '+92'},
      'address': null,
      'address_snapshot': '',
      'scheduled_start': '2026-05-09T10:00:00Z',
      'scheduled_end': '2026-05-09T11:00:00Z',
      'phase_timestamps': {
        'accepted_at': null,
        'en_route_started_at': null,
        'arrived_at': null,
        'inspection_started_at': null,
        'quote_first_submitted_at': null,
        'work_started_at': null,
        'completed_at': null,
      },
      'pricing': {
        'inspection_fee': '500.00',
        'base_services_total': null,
        'discount_applied': null,
        'final_cash_to_collect': '1500.00',
        'promo_code_snapshot': null,
        'promo_discount_snapshot': null,
      },
      'cash_collection': {'amount': null, 'at': null, 'method': 'cash'},
      'parent_booking_id': null,
      'child_booking_id': null,
      'cancel_reason': null,
      'no_show_actor': null,
      'active_quote': null,
      'booking_items': <Map<String, dynamic>>[],
      'open_tickets_count': 0,
      'ui': {
        'status_label': 'X',
        'body_text': '',
        'primary_action': null,
        'secondary_actions': <Map<String, dynamic>>[],
        'show_tracking': false,
        'show_quote_card': false,
        'show_dispute_button': false,
        'tone': 'neutral',
      },
      'available_transitions': <String>[],
    }),
    currentUserId: 7,
  );
}

BookingUiAction _action({
  String label = 'Tap me',
  required String endpoint,
  String method = 'POST',
}) => BookingUiAction(
  label: label,
  endpoint: endpoint,
  method: method,
  style: BookingUiActionStyle.primary,
);

Future<_MockExecutor> _pump(
  WidgetTester tester, {
  required BookingUiAction action,
}) async {
  final exec = _MockExecutor();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bookingActionExecutorProvider.overrideWithValue(exec)],
      child: MaterialApp(
        home: Scaffold(
          body: BookingOrchestratorActionButton(
            action: action,
            booking: _booking(),
            isPrimary: true,
          ),
        ),
      ),
    ),
  );
  return exec;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAction());
  });

  testWidgets('en-route direct POST: tap calls executor with no body', (
    tester,
  ) async {
    final exec = await _pump(
      tester,
      action: _action(endpoint: '/bookings/42/en-route/'),
    );
    when(
      () => exec.execute(any(), body: any(named: 'body')),
    ).thenAnswer((_) async {});

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    verify(() => exec.execute(any(), body: null)).called(1);
  });

  testWidgets(
    'confirm-cash-received: auto body carries final_cash_to_collect',
    (tester) async {
      final exec = await _pump(
        tester,
        action: _action(endpoint: '/bookings/42/confirm-cash-received/'),
      );
      when(
        () => exec.execute(any(), body: any(named: 'body')),
      ).thenAnswer((_) async {});

      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () => exec.execute(any(), body: captureAny(named: 'body')),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['cash_amount'], 1500);
    },
  );

  testWidgets('cancel endpoint opens the BookingActionPendingSheet', (
    tester,
  ) async {
    await _pump(
      tester,
      action: _action(label: 'Cancel', endpoint: '/bookings/42/cancel/'),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // The sheet's title for customer-cancel.
    expect(find.text('Cancel booking?'), findsOneWidget);
  });

  testWidgets('busy state shows a CircularProgressIndicator', (tester) async {
    final completer = Completer<void>();
    final exec = await _pump(
      tester,
      action: _action(endpoint: '/bookings/42/en-route/'),
    );
    when(
      () => exec.execute(any(), body: any(named: 'body')),
    ).thenAnswer((_) => completer.future);

    await tester.tap(find.text('Tap me'));
    // Pump once so the setState(_busy = true) lands but the future
    // hasn't resolved yet.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Label is replaced by the spinner.
    expect(find.text('Tap me'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();
    // After resolution, label is back.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('SocketException from executor surfaces a SnackBar', (
    tester,
  ) async {
    final exec = await _pump(
      tester,
      action: _action(endpoint: '/bookings/42/en-route/'),
    );
    when(
      () => exec.execute(any(), body: any(named: 'body')),
    ).thenThrow(const SocketException('offline'));

    await tester.tap(find.text('Tap me'));
    await tester.pump(); // microtask
    await tester.pump(const Duration(milliseconds: 50)); // snackbar anim

    expect(find.text('No connection. Try again when online.'), findsOneWidget);
  });

  testWidgets('HttpFailure from executor surfaces server message in SnackBar', (
    tester,
  ) async {
    final exec = await _pump(
      tester,
      action: _action(endpoint: '/bookings/42/en-route/'),
    );
    when(() => exec.execute(any(), body: any(named: 'body'))).thenThrow(
      const HttpFailure(
        statusCode: 409,
        code: 'invalid_transition',
        message: 'Cannot do that now.',
        errors: {},
      ),
    );

    await tester.tap(find.text('Tap me'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Cannot do that now.'), findsOneWidget);
  });

  testWidgets('reschedule endpoint shows the "coming soon" sheet', (
    tester,
  ) async {
    await _pump(
      tester,
      action: _action(
        label: 'Reschedule',
        endpoint: '/bookings/42/reschedule/',
      ),
    );
    await tester.tap(find.text('Reschedule'));
    await tester.pumpAndSettle();
    expect(find.text('Reschedule coming soon'), findsOneWidget);
  });

  testWidgets('disputes endpoint shows the dispute pending sheet', (
    tester,
  ) async {
    await _pump(
      tester,
      action: _action(
        label: 'Open dispute',
        endpoint: '/bookings/42/disputes/',
      ),
    );
    await tester.tap(find.text('Open dispute'));
    await tester.pumpAndSettle();
    expect(find.text('Dispute form coming soon'), findsOneWidget);
  });
}

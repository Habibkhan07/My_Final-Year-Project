import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_request.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_status.dart';
import 'package:frontend/features/technician/wallet/presentation/widgets/withdrawal_history_row.dart';

WithdrawalRequest _row({
  required WithdrawalStatus status,
  String label = 'Under review',
  String adminRef = '',
  String payoutKind = 'bank',
}) =>
    WithdrawalRequest(
      id: 42,
      amount: 500.0,
      status: status,
      uiStatusLabel: label,
      payout: PayoutDescriptor(
        kind: payoutKind,
        label: 'HBL — Ali',
        masked: '••1234',
      ),
      adminExternalRef: adminRef,
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      reviewedAt: null,
    );

Future<void> _pumpRow(WidgetTester tester, WithdrawalRequest req) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: WithdrawalHistoryRow(request: req)),
    ),
  );
}

void main() {
  testWidgets('renders the payout label + masked + amount + status pill',
      (tester) async {
    await _pumpRow(
      tester,
      _row(status: WithdrawalStatus.pendingReview, label: 'Under review'),
    );

    expect(find.text('HBL — Ali'), findsOneWidget);
    expect(find.text('••1234'), findsOneWidget);
    expect(find.text('Rs. 500'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
  });

  testWidgets('jazzcash payout kind picks the phone icon', (tester) async {
    await _pumpRow(
      tester,
      _row(
        status: WithdrawalStatus.pendingReview,
        payoutKind: 'jazzcash',
      ),
    );

    expect(find.byIcon(Icons.phone_iphone), findsOneWidget);
    expect(find.byIcon(Icons.account_balance), findsNothing);
  });

  testWidgets('admin_external_ref renders only when non-empty',
      (tester) async {
    await _pumpRow(
      tester,
      _row(
        status: WithdrawalStatus.processed,
        label: 'Processed',
        adminRef: 'JC-MERCH-2026-05-20-7821',
      ),
    );

    expect(find.textContaining('JC-MERCH-2026-05-20-7821'), findsOneWidget);
    expect(find.textContaining('Ref:'), findsOneWidget);
  });

  testWidgets('admin_external_ref absent when empty', (tester) async {
    await _pumpRow(
      tester,
      _row(status: WithdrawalStatus.pendingReview),
    );

    expect(find.textContaining('Ref:'), findsNothing);
  });

  testWidgets('each WithdrawalStatus picks a distinct pill colour', (tester) async {
    // We render each status and capture the pill's container color.
    // Distinct colours → adding a new enum value forces the switch
    // to grow, which is the point.
    final seen = <Color>{};
    for (final status in WithdrawalStatus.values) {
      await _pumpRow(
        tester,
        _row(status: status, label: status.name),
      );
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text(status.name),
          matching: find.byType(Container),
        ).first,
      );
      final color = (container.decoration as BoxDecoration).color;
      if (color != null) seen.add(color);
    }
    expect(seen.length, WithdrawalStatus.values.length);
  });
}

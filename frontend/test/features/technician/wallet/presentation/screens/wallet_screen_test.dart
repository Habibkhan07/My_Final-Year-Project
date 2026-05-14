import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/wallet_state.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/wallet_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/wallet/presentation/screens/wallet_screen.dart';

class _MockRepo extends Mock implements WalletRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [walletRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: WalletScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders balance + both CTAs in happy path', (tester) async {
    when(() => repo.getBalance()).thenAnswer(
      (_) async => WalletState.fromBalance(
        balance: 1500.00,
        asOf: DateTime.utc(2026, 5, 13, 22, 30),
      ),
    );

    await pumpScreen(tester);

    expect(find.text('Wallet'), findsOneWidget); // AppBar title
    expect(find.text('1,500'), findsOneWidget);  // Balance display
    expect(find.text('Top up'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
  });

  testWidgets('Top up tap opens the amount sheet', (tester) async {
    when(() => repo.getBalance()).thenAnswer(
      (_) async => WalletState.fromBalance(
        balance: 100.0,
        asOf: DateTime.utc(2026, 5, 13),
      ),
    );

    await pumpScreen(tester);
    await tester.tap(find.text('Top up'));
    await tester.pumpAndSettle();

    // TopupAmountSheet renders its own title + Continue CTA.
    expect(find.text('Top up wallet'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Withdraw tap shows "Thursday" snackbar', (tester) async {
    when(() => repo.getBalance()).thenAnswer(
      (_) async => WalletState.fromBalance(
        balance: 100.0,
        asOf: DateTime.utc(2026, 5, 13),
      ),
    );

    await pumpScreen(tester);
    await tester.tap(find.text('Withdraw'));
    await tester.pump();

    expect(find.textContaining('Thursday'), findsOneWidget);
  });

  // F5 — lockout strip renders only when the wallet is in lockout.

  testWidgets(
    'positive balance does NOT render the lockout strip',
    (tester) async {
      when(() => repo.getBalance()).thenAnswer(
        (_) async => WalletState.fromBalance(
          balance: 500.0,
          asOf: DateTime.utc(2026, 5, 14),
        ),
      );

      await pumpScreen(tester);

      expect(find.text('Wallet locked'), findsNothing);
    },
  );

  testWidgets(
    'negative balance renders the lockout strip with the owed amount',
    (tester) async {
      when(() => repo.getBalance()).thenAnswer(
        (_) async => WalletState.fromBalance(
          balance: -495.0,
          asOf: DateTime.utc(2026, 5, 14),
        ),
      );

      await pumpScreen(tester);

      // Strip header + body copy, both visible.
      expect(find.text('Wallet locked'), findsOneWidget);
      expect(
        find.text('Top up Rs. 495 to clear the lockout.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'paisa-fraction negative balance shows the rounded-UP owed amount',
    (tester) async {
      // Mirrors F2's WalletState.fromBalance — floor(-100.01) = -101,
      // owed = 101. Strip reads off ``wallet.owedPkr`` directly.
      when(() => repo.getBalance()).thenAnswer(
        (_) async => WalletState.fromBalance(
          balance: -100.01,
          asOf: DateTime.utc(2026, 5, 14),
        ),
      );

      await pumpScreen(tester);

      expect(
        find.text('Top up Rs. 101 to clear the lockout.'),
        findsOneWidget,
      );
    },
  );
}

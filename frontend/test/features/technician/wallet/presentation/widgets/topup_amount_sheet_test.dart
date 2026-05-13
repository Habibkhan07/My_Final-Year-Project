import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/topup_session.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/wallet_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/topup_notifier.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/topup_state.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/wallet/presentation/widgets/topup_amount_sheet.dart';

class _MockRepo extends Mock implements WalletRepository {}

Widget _scope(WalletRepository repo) {
  return ProviderScope(
    overrides: [walletRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: Scaffold(body: TopupAmountSheet())),
  );
}

void main() {
  late _MockRepo repo;
  setUp(() {
    repo = _MockRepo();
  });

  testWidgets('renders title + Continue button', (tester) async {
    await tester.pumpWidget(_scope(repo));
    expect(find.text('Top up wallet'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('empty amount → inline validation error', (tester) async {
    await tester.pumpWidget(_scope(repo));
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Enter a whole-rupee amount.'), findsOneWidget);
    // Repository must NOT have been called for empty input.
    verifyNever(() => repo.startTopup(amountRs: any(named: 'amountRs')));
  });

  testWidgets('below min (Rs.50) → out-of-range error', (tester) async {
    await tester.pumpWidget(_scope(repo));
    await tester.enterText(find.byType(TextField), '50');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.textContaining('between Rs.100 and Rs.25000'), findsOneWidget);
    verifyNever(() => repo.startTopup(amountRs: any(named: 'amountRs')));
  });

  testWidgets('quick-pick fills the field', (tester) async {
    await tester.pumpWidget(_scope(repo));
    await tester.tap(find.text('Rs. 500'));
    await tester.pump();
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('valid amount → calls repository.startTopup', (tester) async {
    when(() => repo.startTopup(amountRs: 1000)).thenAnswer(
      (_) async => const TopupSession(
        topupId: 1,
        redirectUrl: 'https://example.com/bridge?t=q',
      ),
    );

    await tester.pumpWidget(_scope(repo));
    await tester.enterText(find.byType(TextField), '1000');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    verify(() => repo.startTopup(amountRs: 1000)).called(1);
  });

  testWidgets('flow=awaitingGateway after successful start', (tester) async {
    when(() => repo.startTopup(amountRs: 1000)).thenAnswer(
      (_) async => const TopupSession(
        topupId: 1,
        redirectUrl: 'https://example.com/bridge?t=q',
      ),
    );

    final container = ProviderContainer(
      overrides: [walletRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    // Keep a permanent listener on the provider so it does NOT
    // auto-dispose the moment the sheet pops — otherwise start()
    // lands on a disposed notifier. This mirrors the wallet screen
    // in production (TopUpButton's ref.listen pins it).
    container.listen(topupProvider, (_, _) {}, fireImmediately: true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: TopupAmountSheet())),
      ),
    );
    await tester.enterText(find.byType(TextField), '1000');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(container.read(topupProvider).flow, TopupFlow.awaitingGateway);
  });
}

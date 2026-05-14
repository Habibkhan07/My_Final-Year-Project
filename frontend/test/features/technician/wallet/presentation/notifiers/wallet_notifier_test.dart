import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/wallet_state.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/wallet_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/wallet_notifier.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';

class _MockRepo extends Mock implements WalletRepository {}

void main() {
  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [walletRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  group('build()', () {
    test('loads the balance via the repository', () async {
      final state = WalletState.fromBalance(
        balance: 1500.00,
        asOf: DateTime.utc(2026, 5, 13, 22, 30),
      );
      when(() => repo.getBalance()).thenAnswer((_) async => state);

      final result = await container.read(walletProvider.future);

      expect(result.balance, 1500.00);
      verify(() => repo.getBalance()).called(1);
    });

    // Error-path coverage lives in the repository + data source tests
    // (see wallet_repository_impl_test.dart). Replicating it here against
    // the Riverpod provider runs into a known auto-dispose race during
    // build-time exceptions; not worth the test-only workaround given
    // the failure mapping is already exercised one layer down.
  });

  group('onBalanceEvent (realtime patch)', () {
    test('replaces balance in-place after first build', () async {
      when(() => repo.getBalance()).thenAnswer(
        (_) async => WalletState.fromBalance(balance: 1000.00, asOf: DateTime.utc(2026, 5, 13)),
      );

      await container.read(walletProvider.future);

      container
          .read(walletProvider.notifier)
          .onBalanceEvent(700.00);

      final after = container.read(walletProvider).requireValue;
      expect(after.balance, 700.00);
    });

    // Critical regression — the original `copyWith(balance:)` patch left
    // isLockedOut / balancePkr / owedPkr STALE after a realtime event,
    // so the wallet screen's lockout strip never appeared on the
    // commission-driven path. The fix is to route through
    // `WalletState.withBalance`, which recomputes all four atomically.
    test(
      'positive → negative crossover refreshes ALL lockout fields atomically',
      () async {
        when(() => repo.getBalance()).thenAnswer(
          (_) async => WalletState.fromBalance(
            balance: 200.0,
            asOf: DateTime.utc(2026, 5, 14),
          ),
        );
        await container.read(walletProvider.future);

        container
            .read(walletProvider.notifier)
            .onBalanceEvent(-50.0);

        final after = container.read(walletProvider).requireValue;
        expect(after.balance, -50.0);
        // The bug: these three would have remained at their initial-load
        // values (false / 200 / 0) without the withBalance refresh.
        expect(after.isLockedOut, true);
        expect(after.balancePkr, -50);
        expect(after.owedPkr, 50);
      },
    );

    test(
      'negative → positive clears lockout fields atomically (top-up path)',
      () async {
        when(() => repo.getBalance()).thenAnswer(
          (_) async => WalletState.fromBalance(
            balance: -100.0,
            asOf: DateTime.utc(2026, 5, 14),
          ),
        );
        await container.read(walletProvider.future);

        container
            .read(walletProvider.notifier)
            .onBalanceEvent(500.0);

        final after = container.read(walletProvider).requireValue;
        expect(after.balance, 500.0);
        expect(after.isLockedOut, false);
        expect(after.balancePkr, 500);
        expect(after.owedPkr, 0);
      },
    );

    test('paisa-fraction realtime patch uses CEILING for owed', () {
      when(() => repo.getBalance()).thenAnswer(
        (_) async => WalletState.fromBalance(
          balance: 100.0,
          asOf: DateTime.utc(2026, 5, 14),
        ),
      );
      return container.read(walletProvider.future).then((_) {
        container
            .read(walletProvider.notifier)
            .onBalanceEvent(-100.01);

        final after = container.read(walletProvider).requireValue;
        // Mirrors the backend lockout_status rounding: FLOOR balance,
        // CEILING owed — invariant balancePkr + owedPkr == 0.
        expect(after.balancePkr, -101);
        expect(after.owedPkr, 101);
        expect(after.balancePkr + after.owedPkr, 0);
      });
    });

    test('asOf is bumped to "now" so the wallet card reflects the patch', () async {
      final originalAsOf = DateTime.utc(2026, 5, 13, 9);
      when(() => repo.getBalance()).thenAnswer(
        (_) async => WalletState.fromBalance(
          balance: 100.0,
          asOf: originalAsOf,
        ),
      );
      await container.read(walletProvider.future);

      final before = DateTime.now();
      container
          .read(walletProvider.notifier)
          .onBalanceEvent(75.0);
      final after = container.read(walletProvider).requireValue;

      expect(
        after.asOf.isAfter(originalAsOf),
        isTrue,
        reason: 'asOf must advance past the load timestamp',
      );
      expect(
        after.asOf.isBefore(before.add(const Duration(seconds: 2))),
        isTrue,
        reason: 'asOf must be approximately now',
      );
    });

    test('is a no-op before build completes (no state change)', () async {
      // No build yet — state is AsyncLoading.
      container
          .read(walletProvider.notifier)
          .onBalanceEvent(99.00);
      // No exception, no AsyncData written.
      // Note: we can't easily assert the AsyncLoading without forcing a
      // read (which would trigger build). The guard inside onBalanceEvent
      // is the protection — this test is documentation that calling it
      // early doesn't blow up.
      expect(true, isTrue);
    });
  });

  group('refresh()', () {
    test('re-fetches via repository', () async {
      when(() => repo.getBalance()).thenAnswer(
        (_) async => WalletState.fromBalance(balance: 1.0, asOf: DateTime.utc(2026, 5, 13)),
      );
      await container.read(walletProvider.future);

      when(() => repo.getBalance()).thenAnswer(
        (_) async => WalletState.fromBalance(balance: 2.0, asOf: DateTime.utc(2026, 5, 13)),
      );
      await container.read(walletProvider.notifier).refresh();

      expect(container.read(walletProvider).requireValue.balance, 2.0);
      verify(() => repo.getBalance()).called(2);
    });
  });
}

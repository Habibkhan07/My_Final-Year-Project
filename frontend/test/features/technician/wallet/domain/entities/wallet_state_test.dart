import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/wallet/domain/entities/wallet_state.dart';

/// Pins the local lockout-derivation formula in [WalletState.fromBalance] /
/// [WalletState.withBalance] — must agree with backend ``wallet.selectors.lockout``
/// at every boundary or the banner copy on the dashboard will disagree with
/// the wallet detail GET response.
///
/// Rule: ``isLockedOut = balance < 0``. For locked accounts, ``balancePkr``
/// rounds FLOOR and ``owedPkr = -balancePkr`` so the visual invariant
/// ``balancePkr + owedPkr == 0`` holds.
void main() {
  group('WalletState.fromBalance — boundary semantics', () {
    final asOf = DateTime.utc(2026, 5, 14, 10);

    test('zero balance is NOT locked', () {
      final state = WalletState.fromBalance(balance: 0.0, asOf: asOf);
      expect(state.isLockedOut, false);
      expect(state.balancePkr, 0);
      expect(state.owedPkr, 0);
    });

    test('positive balance is not locked', () {
      final state = WalletState.fromBalance(balance: 1500.0, asOf: asOf);
      expect(state.isLockedOut, false);
      expect(state.balancePkr, 1500);
      expect(state.owedPkr, 0);
    });

    test('one paisa negative is locked, owes Rs.1', () {
      final state = WalletState.fromBalance(balance: -0.01, asOf: asOf);
      expect(state.isLockedOut, true);
      expect(state.balancePkr, -1); // floor(-0.01) = -1
      expect(state.owedPkr, 1);
      expect(state.balancePkr + state.owedPkr, 0);
    });

    test('whole-rupee negative balance reconciles cleanly', () {
      final state = WalletState.fromBalance(balance: -495.0, asOf: asOf);
      expect(state.isLockedOut, true);
      expect(state.balancePkr, -495);
      expect(state.owedPkr, 495);
      expect(state.balancePkr + state.owedPkr, 0);
    });

    test('paisa-fraction negative balance rounds owed UP', () {
      // Mirrors backend ``lockout_status`` ROUND_FLOOR — paying owed_pkr
      // exactly should fully clear lockout, never leave a paisa shortfall.
      final state = WalletState.fromBalance(balance: -100.01, asOf: asOf);
      expect(state.isLockedOut, true);
      expect(state.balancePkr, -101);
      expect(state.owedPkr, 101);
      expect(state.balancePkr + state.owedPkr, 0);
    });

    test('positive paisa fraction truncates toward zero', () {
      final state = WalletState.fromBalance(balance: 100.99, asOf: asOf);
      expect(state.isLockedOut, false);
      expect(state.balancePkr, 100); // truncate, not round
      expect(state.owedPkr, 0);
    });
  });

  group('WalletState.withBalance — realtime patch refresh', () {
    final asOf = DateTime.utc(2026, 5, 14, 10);

    test('positive → negative recomputes lockout fields', () {
      final state = WalletState.fromBalance(balance: 200.0, asOf: asOf);
      expect(state.isLockedOut, false);

      final patched = state.withBalance(-50.0);
      expect(patched.isLockedOut, true);
      expect(patched.balancePkr, -50);
      expect(patched.owedPkr, 50);
      // asOf is preserved — realtime patches don't restamp the time anchor.
      expect(patched.asOf, asOf);
    });

    test('negative → positive clears lockout', () {
      final state = WalletState.fromBalance(balance: -100.0, asOf: asOf);
      expect(state.isLockedOut, true);

      final patched = state.withBalance(50.0);
      expect(patched.isLockedOut, false);
      expect(patched.balancePkr, 50);
      expect(patched.owedPkr, 0);
    });

    test('crossing zero exactly does NOT lock', () {
      final state = WalletState.fromBalance(balance: -100.0, asOf: asOf);
      final patched = state.withBalance(0.0);
      expect(patched.isLockedOut, false);
      expect(patched.balancePkr, 0);
      expect(patched.owedPkr, 0);
    });
  });

  group('equality + hashCode', () {
    final asOf = DateTime.utc(2026, 5, 14, 10);

    test('two equal states compare equal', () {
      final a = WalletState.fromBalance(balance: 500.0, asOf: asOf);
      final b = WalletState.fromBalance(balance: 500.0, asOf: asOf);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing isLockedOut compares not-equal', () {
      final a = WalletState.fromBalance(balance: 500.0, asOf: asOf);
      final b = WalletState.fromBalance(balance: -50.0, asOf: asOf);
      expect(a, isNot(equals(b)));
    });
  });
}

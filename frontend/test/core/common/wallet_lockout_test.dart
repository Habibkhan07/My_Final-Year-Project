import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/common/wallet_lockout.dart';

/// Pins the lockout rule + rounding policy that THREE consumers depend on:
///
///   * `WalletState.fromBalance` (wallet feature)
///   * `LockoutBanner.isLocked` (dashboard widget)
///   * `TechnicianDashboardNotifier.setOnline` gate
///
/// Mirror of backend ``wallet.selectors.lockout``. Whenever the boundary
/// changes (e.g. switch to a non-zero threshold), this test catches it
/// before the UI silently goes out of sync with the server.
void main() {
  group('isWalletLocked — strict ``< 0`` semantics', () {
    test('zero is NOT locked (boundary)', () {
      expect(isWalletLocked(0.0), isFalse);
    });

    test('positive is NOT locked', () {
      expect(isWalletLocked(0.01), isFalse);
      expect(isWalletLocked(1500.0), isFalse);
    });

    test('one paisa negative IS locked', () {
      expect(isWalletLocked(-0.01), isTrue);
    });

    test('whole-rupee negative IS locked', () {
      expect(isWalletLocked(-100.0), isTrue);
    });

    test('negative zero is NOT locked (-0.0 is not strictly less than 0)', () {
      // IEEE 754 quirk — Dart treats -0.0 == 0, so the rule holds.
      expect(isWalletLocked(-0.0), isFalse);
    });
  });

  group('owedRupees — round UP on paisa fractions', () {
    test('non-locked returns 0', () {
      expect(owedRupees(0.0), 0);
      expect(owedRupees(500.0), 0);
      expect(owedRupees(-0.0), 0);
    });

    test('whole-rupee negative returns absolute value', () {
      expect(owedRupees(-495.0), 495);
      expect(owedRupees(-1.0), 1);
    });

    test('paisa-fraction negative rounds UP (CEILING)', () {
      // Paying 101 on a balance of -100.01 brings it to 0.99 — unlocked.
      // Truncation would leave a paisa shortfall.
      expect(owedRupees(-100.01), 101);
      expect(owedRupees(-0.01), 1);
      expect(owedRupees(-0.99), 1);
    });
  });

  group('balanceRupees — FLOOR for locked, TRUNCATE for non-negative', () {
    test('non-negative truncates toward zero', () {
      expect(balanceRupees(0.0), 0);
      expect(balanceRupees(100.99), 100);
      expect(balanceRupees(500.0), 500);
    });

    test('negative whole-rupee returns the integer', () {
      expect(balanceRupees(-495.0), -495);
    });

    test('negative paisa-fraction FLOORs (toward -infinity)', () {
      expect(balanceRupees(-100.01), -101);
      expect(balanceRupees(-0.01), -1);
      expect(balanceRupees(-0.99), -1);
    });
  });

  group('invariant: balanceRupees + owedRupees == 0 for locked accounts', () {
    test('holds for whole-rupee negatives', () {
      for (final b in [-1.0, -100.0, -495.0, -10000.0]) {
        expect(balanceRupees(b) + owedRupees(b), 0,
            reason: 'invariant broke at balance=$b');
      }
    });

    test('holds for paisa-fraction negatives', () {
      for (final b in [-0.01, -100.01, -100.99, -1000.50]) {
        expect(balanceRupees(b) + owedRupees(b), 0,
            reason: 'invariant broke at balance=$b');
      }
    });

    test('balanceRupees == 0 and owedRupees == 0 for the zero boundary', () {
      expect(balanceRupees(0.0), 0);
      expect(owedRupees(0.0), 0);
    });
  });
}

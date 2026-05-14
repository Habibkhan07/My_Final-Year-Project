import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/wallet/data/models/wallet_balance_model.dart';

/// Pins the wire contract for ``GET /api/technicians/wallet/`` payload
/// parsing. The backend (B5) ships five fields; the parser must read
/// all of them and the toEntity() map must pass them through unmodified
/// (the entity stores authoritative server values from this codepath;
/// realtime patches refresh derived fields separately).
void main() {
  group('WalletBalanceModel.fromJson', () {
    test('parses all five fields from a complete payload', () {
      final model = WalletBalanceModel.fromJson({
        'balance': '1500.00',
        'as_of': '2026-05-14T10:00:00Z',
        'is_locked_out': false,
        'balance_pkr': 1500,
        'owed_pkr': 0,
      });

      expect(model.balance, '1500.00');
      expect(model.asOf, '2026-05-14T10:00:00Z');
      expect(model.isLockedOut, false);
      expect(model.balancePkr, 1500);
      expect(model.owedPkr, 0);
    });

    test('parses a locked-out payload with paisa fraction', () {
      final model = WalletBalanceModel.fromJson({
        'balance': '-100.01',
        'as_of': '2026-05-14T10:00:00Z',
        'is_locked_out': true,
        'balance_pkr': -101,
        'owed_pkr': 101,
      });

      expect(model.isLockedOut, true);
      expect(model.balancePkr, -101);
      expect(model.owedPkr, 101);
    });

    test('defaults gracefully when the three lockout fields are absent', () {
      // Backwards-compat: an older backend build (pre-B5) might respond
      // without the new fields. Parser must not crash; defaults are
      // "not locked, nothing owed" so the UI doesn't falsely lock the tech.
      final model = WalletBalanceModel.fromJson({
        'balance': '500.00',
        'as_of': '2026-05-14T10:00:00Z',
      });

      expect(model.balance, '500.00');
      expect(model.isLockedOut, false);
      expect(model.balancePkr, 0);
      expect(model.owedPkr, 0);
    });
  });

  group('WalletBalanceModel.toEntity', () {
    test('passes lockout fields through unchanged from the wire', () {
      const model = WalletBalanceModel(
        balance: '-495.00',
        asOf: '2026-05-14T10:00:00Z',
        isLockedOut: true,
        balancePkr: -495,
        owedPkr: 495,
      );

      final entity = model.toEntity();

      // Entity trusts server values on first load (the GET endpoint is
      // authoritative). Realtime balance patches use WalletState.withBalance
      // to refresh derived fields locally — that's tested in
      // wallet_state_test.dart.
      expect(entity.balance, -495.0);
      expect(entity.isLockedOut, true);
      expect(entity.balancePkr, -495);
      expect(entity.owedPkr, 495);
    });
  });
}

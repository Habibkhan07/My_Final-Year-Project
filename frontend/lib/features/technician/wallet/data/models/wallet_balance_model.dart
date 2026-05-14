import '../../domain/entities/wallet_state.dart';

/// Wire-shape for ``GET /api/technicians/wallet/``.
///
/// Backend serializes the Decimal balance as a STRING to preserve
/// precision across the JSON boundary; ``fromJson`` parses it back to a
/// double for the UI layer. Two-dp precision is sufficient — rupee is
/// the smallest unit displayed and the backend rounds to 2dp at write
/// time via the ledger.
///
/// Lockout fields (``isLockedOut`` / ``balancePkr`` / ``owedPkr``) ship as
/// part of the same payload from B5 onwards. The wire fields are the
/// authoritative source on first load; subsequent realtime patches
/// (``wallet_balance_updated``) only carry balance and the entity
/// recomputes the derived fields via [WalletState.withBalance].
class WalletBalanceModel {
  final String balance;
  final String asOf;
  final bool isLockedOut;
  final int balancePkr;
  final int owedPkr;

  const WalletBalanceModel({
    required this.balance,
    required this.asOf,
    required this.isLockedOut,
    required this.balancePkr,
    required this.owedPkr,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) =>
      WalletBalanceModel(
        balance: json['balance'] as String,
        asOf: json['as_of'] as String,
        // Backwards-compat defaults: pre-B5 backend builds didn't include
        // these fields. Default to "not locked, nothing owed" so an old
        // server response doesn't crash the parser. In practice the
        // deployed backend (post-B5) always emits all three.
        isLockedOut: json['is_locked_out'] as bool? ?? false,
        balancePkr: json['balance_pkr'] as int? ?? 0,
        owedPkr: json['owed_pkr'] as int? ?? 0,
      );

  WalletState toEntity() => WalletState(
        balance: double.parse(balance),
        asOf: DateTime.parse(asOf),
        isLockedOut: isLockedOut,
        balancePkr: balancePkr,
        owedPkr: owedPkr,
      );
}

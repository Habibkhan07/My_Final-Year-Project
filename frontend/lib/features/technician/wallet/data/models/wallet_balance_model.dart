import '../../domain/entities/wallet_state.dart';

/// Wire-shape for ``GET /api/technicians/wallet/``.
///
/// Backend serializes the Decimal balance as a STRING to preserve
/// precision across the JSON boundary; ``fromJson`` parses it back to a
/// double for the UI layer. Two-dp precision is sufficient — rupee is
/// the smallest unit displayed and the backend rounds to 2dp at write
/// time via the ledger.
class WalletBalanceModel {
  final String balance;
  final String asOf;

  const WalletBalanceModel({required this.balance, required this.asOf});

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) =>
      WalletBalanceModel(
        balance: json['balance'] as String,
        asOf: json['as_of'] as String,
      );

  WalletState toEntity() => WalletState(
        balance: double.parse(balance),
        asOf: DateTime.parse(asOf),
      );
}

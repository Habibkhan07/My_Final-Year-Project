import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/entities/wallet_transaction_page.dart';

/// Wire-shape for one row of ``GET /api/technicians/wallet/transactions/``.
///
/// ``amount`` and ``balanceAfter`` arrive as Decimal-as-string to
/// preserve precision; ``fromJson`` parses to double at this boundary so
/// the domain entity stays primitive.
class WalletTransactionModel {
  final int id;
  final String type;
  final String amount;
  final String balanceAfter;
  final String timestamp;
  final String memo;
  final String uiIcon;
  final String uiTitle;
  final String uiSubtitle;
  final String uiAmountColor;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.timestamp,
    required this.memo,
    required this.uiIcon,
    required this.uiTitle,
    required this.uiSubtitle,
    required this.uiAmountColor,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) =>
      WalletTransactionModel(
        id: json['id'] as int,
        type: json['type'] as String,
        amount: json['amount'] as String,
        balanceAfter: json['balance_after'] as String,
        timestamp: json['timestamp'] as String,
        memo: (json['memo'] as String?) ?? '',
        uiIcon: json['ui_icon'] as String,
        uiTitle: json['ui_title'] as String,
        uiSubtitle: (json['ui_subtitle'] as String?) ?? '',
        uiAmountColor: json['ui_amount_color'] as String,
      );

  WalletTransactionEntity toEntity() => WalletTransactionEntity(
        id: id,
        type: type,
        amount: double.parse(amount),
        balanceAfter: double.parse(balanceAfter),
        timestamp: DateTime.parse(timestamp),
        memo: memo,
        uiIcon: uiIcon,
        uiTitle: uiTitle,
        uiSubtitle: uiSubtitle,
        uiAmountColor: uiAmountColor,
      );
}

/// Wire-shape for a single cursor-paginated page.
class WalletTransactionPageModel {
  final List<WalletTransactionModel> results;
  final String? nextCursor;

  const WalletTransactionPageModel({
    required this.results,
    required this.nextCursor,
  });

  factory WalletTransactionPageModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['results'] as List<dynamic>?) ?? const [];
    return WalletTransactionPageModel(
      results: raw
          .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      nextCursor: json['next_cursor'] as String?,
    );
  }

  WalletTransactionPage toEntity() => WalletTransactionPage(
        results: results.map((m) => m.toEntity()).toList(growable: false),
        nextCursor: nextCursor,
      );
}

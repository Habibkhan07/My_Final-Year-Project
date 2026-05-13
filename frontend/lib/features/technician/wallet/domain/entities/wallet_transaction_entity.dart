/// Domain entity for a single wallet ledger row.
///
/// Fed by ``GET /api/technicians/wallet/transactions/``. The backend
/// selector shapes the Dumb-UI fields (``uiIcon``, ``uiTitle``,
/// ``uiSubtitle``, ``uiAmountColor``) so the Flutter [TransactionRow]
/// widget never branches on ``type``.
///
/// Five concrete transaction kinds are emitted by the backend ledger:
///   * ``COMMISSION_DEBIT``  — platform commission on a completed job
///   * ``TOPUP_CREDIT``      — tech tops up the wallet via gateway
///   * ``WITHDRAWAL_DEBIT``  — admin processed a withdrawal payout
///   * ``REFUND_DEBIT``      — tech's deposit debited to fund a refund
///   * ``ADJUSTMENT``        — manual admin ledger correction (either sign)
///
/// Cash exchanges (customer-to-tech) are NEVER on this list — they're
/// not wallet entries. See the wallet-vs-metrics separation rule.
class WalletTransactionEntity {
  final int id;
  final String type;
  final double amount;
  final double balanceAfter;
  final DateTime timestamp;
  final String memo;
  final String uiIcon;
  final String uiTitle;
  final String uiSubtitle;
  final String uiAmountColor;

  const WalletTransactionEntity({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTransactionEntity &&
          id == other.id &&
          type == other.type &&
          amount == other.amount &&
          balanceAfter == other.balanceAfter &&
          timestamp == other.timestamp &&
          memo == other.memo &&
          uiIcon == other.uiIcon &&
          uiTitle == other.uiTitle &&
          uiSubtitle == other.uiSubtitle &&
          uiAmountColor == other.uiAmountColor;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        amount,
        balanceAfter,
        timestamp,
        memo,
        uiIcon,
        uiTitle,
        uiSubtitle,
        uiAmountColor,
      );
}

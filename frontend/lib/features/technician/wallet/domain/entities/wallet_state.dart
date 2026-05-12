/// Tech-facing virtual wallet snapshot.
///
/// Fed by ``GET /api/technicians/wallet/`` (initial load + pull-to-refresh)
/// and patched in-place by ``WALLET_BALANCE_UPDATED`` realtime events. The
/// dashboard's ``walletBalance`` pill consumes the same backend event via
/// its own notifier — both surfaces stay in sync.
///
/// ``balance`` is parsed from the server's Decimal-as-string at the data
/// layer so the domain layer never sees the wire format. UI formats Rs.
/// display via NumberFormat at the widget boundary.
class WalletState {
  final double balance;
  final DateTime asOf;

  const WalletState({required this.balance, required this.asOf});

  WalletState copyWith({double? balance, DateTime? asOf}) =>
      WalletState(
        balance: balance ?? this.balance,
        asOf: asOf ?? this.asOf,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletState && balance == other.balance && asOf == other.asOf;

  @override
  int get hashCode => Object.hash(balance, asOf);
}

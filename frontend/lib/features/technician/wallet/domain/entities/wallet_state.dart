import '../../../../../core/common/wallet_lockout.dart' as lockout;

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
///
/// Lockout fields
/// --------------
/// The backend's wallet detail serializer ships three derived fields:
///
///   * ``isLockedOut``  — true iff ``balance < 0``
///   * ``balancePkr``   — int rupees, FLOOR'd when locked
///   * ``owedPkr``      — positive int, CEILING of |balance| when locked
///
/// When a realtime ``wallet_balance_updated`` frame arrives (carrying only
/// the new balance — see ``wallet.services.ledger._broadcast_wallet_balance_updated``),
/// the notifier MUST refresh the three derived fields locally so the lockout
/// banner stays in sync. Use [WalletState.withBalance] for that — it mirrors
/// the backend's ``wallet.selectors.lockout.lockout_status`` formula exactly
/// (the formula lives in ``core/common/wallet_lockout.dart`` and is shared
/// with the dashboard's banner + toggle gate).
class WalletState {
  final double balance;
  final DateTime asOf;
  final bool isLockedOut;
  final int balancePkr;
  final int owedPkr;

  const WalletState({
    required this.balance,
    required this.asOf,
    required this.isLockedOut,
    required this.balancePkr,
    required this.owedPkr,
  });

  /// Smart constructor that derives the three lockout fields locally from
  /// a raw balance. The formula lives in ``core/common/wallet_lockout.dart``
  /// — shared with the dashboard's banner + toggle gate so a future
  /// rounding tweak applies everywhere at once.
  ///
  /// Use this when patching state from a realtime event that carries only
  /// the new balance, or in tests that don't care about the lockout fields
  /// (passing the explicit values would just duplicate this formula).
  factory WalletState.fromBalance({
    required double balance,
    required DateTime asOf,
  }) {
    return WalletState(
      balance: balance,
      asOf: asOf,
      isLockedOut: lockout.isWalletLocked(balance),
      balancePkr: lockout.balanceRupees(balance),
      owedPkr: lockout.owedRupees(balance),
    );
  }

  WalletState copyWith({
    double? balance,
    DateTime? asOf,
    bool? isLockedOut,
    int? balancePkr,
    int? owedPkr,
  }) => WalletState(
        balance: balance ?? this.balance,
        asOf: asOf ?? this.asOf,
        isLockedOut: isLockedOut ?? this.isLockedOut,
        balancePkr: balancePkr ?? this.balancePkr,
        owedPkr: owedPkr ?? this.owedPkr,
      );

  /// Patch the balance AND refresh the derived lockout fields together.
  ///
  /// Realtime ``wallet_balance_updated`` frames carry only the new balance.
  /// A naive ``copyWith(balance: ...)`` would leave the lockout fields stale:
  /// the tech's balance would dip negative but ``isLockedOut`` would stay
  /// false until the next GET. This helper recomputes all three derived
  /// fields together using the same formula as the backend, keeping the
  /// banner in sync without a round-trip.
  ///
  /// [asOf] defaults to the existing timestamp so callers can keep the
  /// original anchor; passing ``DateTime.now()`` is appropriate when a
  /// realtime event has just arrived (the wallet notifier does this so
  /// the wallet screen shows "balance as of just now").
  WalletState withBalance(double newBalance, {DateTime? asOf}) =>
      WalletState.fromBalance(
        balance: newBalance,
        asOf: asOf ?? this.asOf,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletState &&
          balance == other.balance &&
          asOf == other.asOf &&
          isLockedOut == other.isLockedOut &&
          balancePkr == other.balancePkr &&
          owedPkr == other.owedPkr;

  @override
  int get hashCode =>
      Object.hash(balance, asOf, isLockedOut, balancePkr, owedPkr);
}

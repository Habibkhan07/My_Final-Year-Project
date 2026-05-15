import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../domain/entities/wallet_state.dart';
import '../providers/dependency_injection.dart';
import 'pending_withdrawal_notifier.dart';

part 'wallet_notifier.g.dart';

/// State holder for the tech-only Wallet screen.
///
/// Two mutation paths:
///   * [build]          — initial fetch + pull-to-refresh from
///                        ``GET /api/technicians/wallet/``.
///   * [onBalanceEvent] — single-field patch fired by the
///                        ``wallet_balance_updated`` realtime event so the
///                        screen reflects commission deductions / top-ups
///                        without a full reload.
///
/// **keepAlive: false** — the wallet screen is a leaf route, not a tab.
/// When the tech navigates away, the notifier is disposed; on return it
/// re-fetches. The dashboard pill (whose notifier IS keepAlive) is the
/// always-on surface for the same balance, so missing events while the
/// wallet screen is dismissed costs us nothing.
@riverpod
class WalletNotifier extends _$WalletNotifier {
  @override
  Future<WalletState> build() async {
    // Subscribe to the realtime firehose. Filter on ``walletBalanceUpdated``;
    // patch ``balance`` in place so the UI updates without an AsyncLoading
    // flash. The pipeline already dedupes by event id at SystemEventNotifier,
    // and we add a second id-equality guard here for housekeeping rebuilds.
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (previous?.latestEvent?.id == event.id) return;
      if (event.eventType != SystemEventType.walletBalanceUpdated) return;

      final balanceRaw = event.payload['balance'];
      if (balanceRaw is! String) return;
      final parsed = double.tryParse(balanceRaw);
      if (parsed == null) return;

      onBalanceEvent(parsed);

      // Cross-feature refresh hook for the pending-withdrawal pill.
      // Routes WITHDRAWAL_DEBIT events to a public method so unit
      // tests can exercise the invalidation without faking the
      // system-event provider.
      final txnType = event.payload['transaction_type']?.toString() ?? '';
      onWalletTransactionEvent(txnType);
    });

    final repo = ref.read(walletRepositoryProvider);
    return await repo.getBalance();
  }

  /// Pull-to-refresh entry point. Preserves the prior value during the
  /// round trip via ``AsyncValue.guard`` so the balance card doesn't
  /// flash a skeleton while reloading.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(walletRepositoryProvider);
      return await repo.getBalance();
    });
  }

  /// Patch the balance in-place from a realtime event.
  ///
  /// Public so tests can drive it without faking the full system-event
  /// envelope. Silently ignored if the screen hasn't loaded yet — the
  /// initial [build] fetch will pick up whatever the latest balance is.
  ///
  /// **Lockout fields refresh together with balance.** A realtime
  /// ``wallet_balance_updated`` event carries only the new balance — but
  /// ``isLockedOut`` / ``balancePkr`` / ``owedPkr`` are derived from it.
  /// Calling [WalletState.withBalance] keeps the four fields atomic so
  /// the lockout strip flips in the same frame as the balance changes
  /// (matches backend B6's atomic ledger + is_online write). A naive
  /// ``copyWith(balance: ...)`` would leave the derived fields stale and
  /// the strip would not appear until the next GET. ``asOf`` is bumped
  /// to ``DateTime.now()`` so the wallet card's "as of" reflects the
  /// realtime patch, not the stale fetch timestamp.
  /// Cross-feature reactor for ``wallet_balance_updated`` events that
  /// carry a ``transaction_type``. Currently only one branch fires:
  /// ``WITHDRAWAL_DEBIT`` invalidates [pendingWithdrawalProvider] so
  /// the wallet-screen pending pill disappears in the same frame as
  /// the balance patch (closes the visibility gap caused by not
  /// having a dedicated ``withdrawal_processed`` wire event).
  ///
  /// Other types (COMMISSION_DEBIT, TOPUP_CREDIT, REFUND_DEBIT,
  /// ADJUSTMENT) are no-ops here — they don't affect the pending
  /// pill, and we'd rather skip a wasted re-fetch than invalidate
  /// indiscriminately on every ledger write.
  ///
  /// Public so tests can drive the invalidation without faking the
  /// system-event layer.
  @visibleForTesting
  void onWalletTransactionEvent(String transactionType) {
    if (transactionType == 'WITHDRAWAL_DEBIT') {
      ref.invalidate(pendingWithdrawalProvider);
    }
  }

  @visibleForTesting
  void onBalanceEvent(double newBalance) {
    if (state is! AsyncData<WalletState>) return;
    final current = state.requireValue;
    state = AsyncData(
      current.withBalance(newBalance, asOf: DateTime.now()),
    );
  }
}

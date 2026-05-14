import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/failures/wallet_failure.dart';
import '../notifiers/wallet_notifier.dart';
import '../notifiers/wallet_transactions_notifier.dart';
import '../notifiers/pending_withdrawal_notifier.dart';
import '../widgets/balance_card.dart';
import '../widgets/pending_withdrawal_strip.dart';
import '../widgets/top_up_button.dart';
import '../widgets/transactions_section.dart';
import '../widgets/wallet_lockout_strip.dart';
import '../widgets/withdraw_button.dart';

/// Tech-only Wallet screen. Layout (Foodpanda-style, brand-blue):
///   AppBar    — "Wallet" + back
///   Body      — balance card (hero) → Top up → Withdraw → Recent activity
///   Refresh   — pull-to-refresh on the scroll surface (refreshes BOTH
///               balance and transaction history together)
///
/// The transaction list shows only wallet-side rows (commission /
/// topup / withdrawal / refund / adjustment). Cash exchanges
/// (customer→tech) deliberately live on the Metrics screen instead —
/// the wallet is the platform-money ledger, not a cash earnings view.
/// See the wallet-vs-metrics-separation rule.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all three streams that feed this screen together
          // so the pull-to-refresh gesture covers the whole surface.
          // pendingWithdrawal piggybacks on the same history endpoint,
          // so invalidating it is enough to re-fetch.
          ref.invalidate(pendingWithdrawalProvider);
          await Future.wait<void>([
            ref.read(walletProvider.notifier).refresh(),
            ref.read(walletTransactionsProvider.notifier).refresh(),
          ]);
        },
        child: walletAsync.when(
          loading: () => const _LoadingView(),
          error: (err, _) => _ErrorView(
            error: err is WalletFailure
                ? err
                : const WalletServerFailure('Unexpected error'),
            onRetry: () => ref.read(walletProvider.notifier).refresh(),
          ),
          data: (wallet) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lockout strip — rendered when balance < 0. Coherent
                // with the dashboard banner so the tech sees the same
                // Rs. X owed in both surfaces (F4 and F5).
                if (wallet.isLockedOut) ...[
                  WalletLockoutStrip(wallet: wallet),
                  const SizedBox(height: 16),
                ],
                BalanceCard(wallet: wallet),
                const SizedBox(height: 24),
                const PendingWithdrawalStrip(),
                const TopUpButton(),
                const SizedBox(height: 12),
                const WithdrawButton(),
                const SizedBox(height: 8),
                _WithdrawalHistoryLink(),
                const TransactionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small text-button link to the withdrawal-history screen. Lives
/// directly under the Withdraw CTA so the visibility surface is one
/// tap away from the action that creates rows on it.
class _WithdrawalHistoryLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.center,
        child: TextButton.icon(
          onPressed: () => context.push('/withdrawals/history'),
          icon: const Icon(Icons.history, size: 18),
          label: const Text('View withdrawal history'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 160),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final WalletFailure error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (error) {
      WalletNetworkFailure() => Icons.wifi_off,
      WalletPermissionFailure() => Icons.lock_outline,
      WalletServerFailure() => Icons.error_outline,
      // Practically unreachable on the GET endpoint (which succeeds
      // regardless of balance), but required for sealed exhaustiveness
      // because future write paths (withdrawal) will raise this. The
      // dedicated lockout banner lives in F4/F5 on the same screen —
      // see [WalletState.isLockedOut].
      WalletLockoutFailure() => Icons.account_balance_wallet_outlined,
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: AppColors.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          error.message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/failures/wallet_failure.dart';
import '../notifiers/wallet_transactions_notifier.dart';
import 'transaction_row.dart';

/// The transaction-history section of the WalletScreen.
///
/// Behavior:
///   * AsyncData with rows  → ListView.separated of [TransactionRow]s.
///   * AsyncData empty      → empty-state pill ("No wallet activity yet").
///   * AsyncLoading         → 5-row shimmer-style skeleton.
///   * AsyncError           → inline error + retry button.
///   * On reaching the end of the list, kicks loadMore() if hasMore.
///
/// The widget itself is a ConsumerWidget that watches the family
/// notifier; tap-to-action plumbing is bound here so the parent
/// WalletScreen stays the layout owner.
class TransactionsSection extends ConsumerWidget {
  const TransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 24, 4, 12),
          child: Text(
            'Recent activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        async.when(
          loading: () => const _Skeleton(),
          error: (err, _) => _ErrorBox(
            error: err is WalletFailure
                ? err
                : const WalletServerFailure('Could not load activity.'),
            onRetry: () =>
                ref.read(walletTransactionsProvider.notifier).refresh(),
          ),
          data: (state) {
            if (state.page.isEmpty) return const _EmptyPill();
            return _LoadedList(
              rows: state.page.results,
              isLoadingMore: state.isLoadingMore,
              hasMore: state.page.hasMore,
              onLoadMore: () => ref
                  .read(walletTransactionsProvider.notifier)
                  .loadMore(),
            );
          },
        ),
      ],
    );
  }
}

class _LoadedList extends StatefulWidget {
  const _LoadedList({
    required this.rows,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<WalletTransactionEntity> rows;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  State<_LoadedList> createState() => _LoadedListState();
}

class _LoadedListState extends State<_LoadedList> {
  bool _autoLoadedOnce = false;

  @override
  Widget build(BuildContext context) {
    // The wallet screen's parent is a SingleChildScrollView; we render
    // a non-scrolling list and rely on the parent scroller to drive
    // load-more. Trigger heuristic: when this widget is built with
    // hasMore=true AND we haven't auto-loaded, schedule a one-shot
    // load-more on the next frame. The visible-list test handles
    // happy-path coverage; the on-scroll polish lives in a later
    // commit when we move to a SliverList.
    if (widget.hasMore && !widget.isLoadingMore && !_autoLoadedOnce) {
      _autoLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadMore();
      });
    } else if (!widget.hasMore) {
      _autoLoadedOnce = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < widget.rows.length; i++) ...[
            TransactionRow(entity: widget.rows[i]),
            if (i < widget.rows.length - 1)
              const Divider(height: 1, color: AppColors.outlineVariant),
          ],
          if (widget.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPill extends StatelessWidget {
  const _EmptyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.receipt_long_outlined,
              color: AppColors.onSurfaceVariant, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No wallet activity yet',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: double.infinity,
                          height: 12,
                          color: AppColors.surfaceContainerHigh),
                      const SizedBox(height: 6),
                      Container(
                          width: 120,
                          height: 10,
                          color: AppColors.surfaceContainerHigh),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                    width: 60,
                    height: 14,
                    color: AppColors.surfaceContainerHigh),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error, required this.onRetry});

  final WalletFailure error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (error) {
      WalletNetworkFailure() => Icons.wifi_off,
      WalletPermissionFailure() => Icons.lock_outline,
      WalletServerFailure() => Icons.error_outline,
      // Unreachable in practice on the transactions list endpoint —
      // it succeeds regardless of lockout. Added for sealed exhaustiveness.
      WalletLockoutFailure() => Icons.account_balance_wallet_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            error.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

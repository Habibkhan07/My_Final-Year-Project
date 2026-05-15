import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/failures/withdrawal_failure.dart';
import '../notifiers/withdrawal_history_notifier.dart';
import '../widgets/withdrawal_history_row.dart';

/// Tech-facing screen listing this tech's withdrawal-request history.
///
/// One screen, three states:
///   * loading        — skeleton rows.
///   * empty list     — friendly empty-state pill.
///   * data           — newest-first list, pull-to-refresh, on-scroll
///                       load-more, inline "couldn't load more" footer
///                       on a paginated failure.
///
/// Existing PROCESSED rows also appear in the wallet transaction list
/// as ``WITHDRAWAL_DEBIT`` entries — those surface the post-fulfilment
/// state. This screen is the ONLY surface for PENDING_REVIEW /
/// APPROVED / REJECTED visibility (those statuses don't write to the
/// ledger).
class WithdrawalHistoryScreen extends ConsumerStatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  ConsumerState<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState
    extends ConsumerState<WithdrawalHistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  /// Kick off the next page when the scroll position is within ~120px
  /// of the bottom. The notifier's re-entry guard prevents duplicate
  /// fetches when scroll bursts past the threshold quickly.
  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      ref.read(withdrawalHistoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(withdrawalHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Withdrawal history'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(withdrawalHistoryProvider.notifier).refresh(),
        child: async.when(
          loading: () => const _LoadingView(),
          error: (err, _) => _ErrorView(
            failure: err is WithdrawalFailure
                ? err
                : const WithdrawalServerFailure(),
            onRetry: () =>
                ref.read(withdrawalHistoryProvider.notifier).refresh(),
          ),
          data: (state) {
            if (state.page.results.isEmpty) {
              return const _EmptyView();
            }
            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: state.page.results.length +
                  (state.page.hasMore || state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < state.page.results.length) {
                  return WithdrawalHistoryRow(
                    request: state.page.results[index],
                  );
                }
                // Footer: spinner while loading, otherwise nothing
                // (the on-scroll listener kicked the load).
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: state.isLoadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Icon(Icons.history,
                size: 48, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'No withdrawals yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Submit your first request from the wallet screen.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  final WithdrawalFailure failure;
  final VoidCallback onRetry;
  const _ErrorView({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final message = switch (failure) {
      WithdrawalNetworkFailure(:final message) => message,
      WithdrawalPermissionFailure(:final message) => message,
      _ => 'Could not load withdrawal history.',
    };
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Icon(Icons.error_outline, size: 40, color: AppColors.error),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

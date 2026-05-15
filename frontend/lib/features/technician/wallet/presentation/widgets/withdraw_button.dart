import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../notifiers/pending_withdrawal_notifier.dart';
import '../notifiers/wallet_notifier.dart';
import 'withdraw_sheet.dart';

/// Withdraw CTA on the wallet screen.
///
/// Tap → opens the [WithdrawSheet] as a modal bottom sheet (matches
/// the existing top-up flow's container choice). Disabled when the
/// wallet is currently locked out — the server would reject a submit
/// anyway, but pre-empting the round-trip keeps the UX honest.
///
/// We keep this widget [ConsumerWidget] so it can read
/// ``walletProvider`` for the lockout flag without forcing the parent
/// screen to re-pass derived state.
class WithdrawButton extends ConsumerWidget {
  const WithdrawButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final pendingAsync = ref.watch(pendingWithdrawalProvider);
    // Default to "not locked" while the wallet is still fetching so
    // the button isn't briefly disabled on initial render. The sheet
    // itself re-checks lockout when it opens.
    final isLockedOut = walletAsync.value?.isLockedOut ?? false;
    // ``pendingAsync.value`` is non-null only on success-with-data —
    // ``AsyncError`` and the initial loading both leave it null, so
    // the button stays tappable in those states (server is the
    // authoritative gate; 409 will surface inside the sheet if a
    // pending request really does exist).
    final hasPending = pendingAsync.value != null;

    final disabled = isLockedOut || hasPending;
    final String label;
    if (isLockedOut) {
      label = 'Withdraw (locked)';
    } else if (hasPending) {
      label = 'Withdraw (request pending)';
    } else {
      label = 'Withdraw';
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: disabled ? null : () => _openSheet(context),
        icon: const Icon(Icons.account_balance_outlined),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: disabled
                ? AppColors.outline.withValues(alpha: 0.5)
                : AppColors.primary,
            width: 1.5,
          ),
          disabledForegroundColor: AppColors.onSurfaceVariant,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusXL),
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WithdrawSheet(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/common/wallet_lockout.dart' as lockout;
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Wallet-lockout banner shown above the up-next card when the tech's
/// wallet balance is negative.
///
/// The lockout rule and rounding policy live in
/// ``core/common/wallet_lockout.dart`` — shared with the wallet feature's
/// [WalletState.fromBalance] so the two never drift. See backend memory
/// ``wallet-money-mechanics`` for the authoritative table.
///
/// **Why the dashboard owns this** (not the wallet feature): the tech
/// lives on the dashboard during a shift. The banner needs to be where
/// the tech's attention is — same surface as the online toggle. The
/// wallet screen has its own lockout strip for when the tech navigates
/// there to top up.
///
/// **Copy contract.** "Top up Rs.{owed} to clear the lockout." — same
/// wording used by the wallet strip and the accept-blocked snackbar so
/// the tech reads a coherent message across all three surfaces.
///
/// **CTA.** Tap → push the wallet screen at `/wallet`. The matching red
/// strip on that screen reuses the same Rs. X figure so the tech
/// understands they're in the right place.
///
/// Realtime sync: this banner reads ``walletBalance`` straight off the
/// dashboard entity, which the notifier patches in-place on every
/// ``wallet_balance_updated`` realtime event. No extra subscription
/// needed — when the backend commission write flips the tech's wallet
/// negative, the WS frame patches walletBalance and this widget
/// rebuilds on the next frame.
class LockoutBanner extends StatelessWidget {
  /// Construct a banner from the tech's current wallet balance.
  /// Callers should only mount this widget when [isLocked] returns true;
  /// the widget itself does not branch on the input.
  const LockoutBanner({super.key, required this.walletBalance});

  /// Signed wallet balance in PKR (the dashboard entity's raw field).
  final double walletBalance;

  /// True iff the wallet is currently in lockout. Thin re-export of the
  /// shared rule so the dashboard screen layout can `if (...)` without
  /// pulling the lockout utility import alongside.
  static bool isLocked(double balance) => lockout.isWalletLocked(balance);

  @override
  Widget build(BuildContext context) {
    final owed = lockout.owedRupees(walletBalance);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Material(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          onTap: () => GoRouter.of(context).push('/wallet'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.error,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet locked',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Top up Rs. $owed to clear the lockout.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.onErrorContainer,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

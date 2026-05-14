import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/wallet_state.dart';

/// Red strip rendered above the [BalanceCard] when the wallet is in lockout.
///
/// The dashboard already has its own [LockoutBanner] — this strip is the
/// counterpart for the moment the tech has navigated to the wallet screen
/// to top up. Coherent copy with the dashboard banner (same Rs. X owed)
/// so the tech understands they're in the right place.
///
/// Read the lockout fields off [WalletState] (populated by the F2 entity
/// migration) so all three values come from the same authoritative GET
/// response. No paisa math at this layer — backend already rounded.
class WalletLockoutStrip extends StatelessWidget {
  const WalletLockoutStrip({super.key, required this.wallet});

  final WalletState wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
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
                  'Top up Rs. ${wallet.owedPkr} to clear the lockout.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

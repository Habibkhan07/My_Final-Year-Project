import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/wallet_state.dart';

/// Hero balance display — the focus of the wallet screen.
///
/// Two-line layout matching the Stitch reference:
///   * Big Rs. number (28-32sp)
///   * Label "Current balance"
///   * Small "Updated: HH:mm" timestamp anchoring freshness
///
/// Brand-blue gradient background (primaryContainer → primary) so the
/// surface visually signals "money / important" without needing copy.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.wallet});

  final WalletState wallet;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final updatedAt = DateFormat('HH:mm').format(wallet.asOf.toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        borderRadius: BorderRadius.circular(AppShapes.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current balance',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Rs.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatter.format(wallet.balance),
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Updated $updatedAt',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

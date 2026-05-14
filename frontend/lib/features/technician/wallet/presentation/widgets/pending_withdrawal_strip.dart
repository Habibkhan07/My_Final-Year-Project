import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/withdrawal_status.dart';
import '../notifiers/pending_withdrawal_notifier.dart';

/// Wallet-screen pill that surfaces the tech's open in-flight
/// withdrawal request (if any).
///
/// Visible only when the [pendingWithdrawalProvider] resolves to a
/// non-null [WithdrawalRequest]. While the underlying request is
/// fetching (initial wallet-screen mount), the strip is a no-op —
/// flashing it on/off would be more distracting than helpful for a
/// best-effort visibility surface.
///
/// Tap → pushes ``/withdrawals/history`` so the tech can see the row
/// with its full timeline (requested_at, reviewed_at, etc.).
class PendingWithdrawalStrip extends ConsumerWidget {
  const PendingWithdrawalStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingWithdrawalProvider);
    final request = async.value;
    if (request == null) return const SizedBox.shrink();

    final isApproved = request.status == WithdrawalStatus.approved;
    final label = isApproved
        ? 'Withdrawal approved — processing'
        : 'Withdrawal under review';
    final amount = 'Rs. ${request.amount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          onTap: () => context.push('/withdrawals/history'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isApproved ? Icons.local_shipping_outlined : Icons.schedule,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$amount → ${request.payout.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

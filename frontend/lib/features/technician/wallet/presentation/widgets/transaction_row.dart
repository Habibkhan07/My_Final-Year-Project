import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/wallet_transaction_entity.dart';

/// One Dumb-UI row in the wallet transaction list.
///
/// All branching on transaction kind happens at the backend selector;
/// this widget consumes ``uiIcon`` / ``uiTitle`` / ``uiSubtitle`` /
/// ``uiAmountColor`` directly and never inspects ``entity.type``.
class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.entity});

  final WalletTransactionEntity entity;

  static final NumberFormat _rs = NumberFormat('#,##0', 'en_PK');

  @override
  Widget build(BuildContext context) {
    final amountColor = entity.uiAmountColor == 'credit'
        ? AppColors.secondary
        : AppColors.onSurface;
    final sign = entity.amount >= 0 ? '+' : '−';
    final absAmount = entity.amount.abs();
    final formatted = '$sign Rs. ${_rs.format(absAmount)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IconBubble(iconKey: entity.uiIcon, isCredit: entity.uiAmountColor == 'credit'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.uiTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entity.uiSubtitle.isEmpty
                      ? _relativeTime(entity.timestamp)
                      : '${entity.uiSubtitle}  •  ${_relativeTime(entity.timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Coarse "2h ago" / "3d ago" relative time. Older than 7 days falls
  /// back to a short date so the list doesn't lie ("180d ago").
  String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(ts.toLocal());
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.iconKey, required this.isCredit});

  final String iconKey;
  final bool isCredit;

  @override
  Widget build(BuildContext context) {
    final iconData = _iconFor(iconKey);
    final bg = isCredit
        ? AppColors.secondaryContainer.withValues(alpha: 0.35)
        : AppColors.primaryFixed;
    final fg = isCredit ? AppColors.secondary : AppColors.primary;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 20, color: fg),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'commission':
        return Icons.percent;
      case 'topup':
        return Icons.add_card;
      case 'withdrawal':
        return Icons.payments_outlined;
      case 'refund':
        return Icons.undo;
      case 'adjustment':
        return Icons.build_circle_outlined;
      default:
        return Icons.receipt_long;
    }
  }
}

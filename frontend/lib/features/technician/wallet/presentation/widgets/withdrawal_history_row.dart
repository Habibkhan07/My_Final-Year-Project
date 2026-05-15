import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/withdrawal_request.dart';
import '../../domain/entities/withdrawal_status.dart';
import '../format.dart';

/// One row of the withdrawal-history list — Dumb-UI presenter.
///
/// No branching on [WithdrawalRequest.status] for copy: the row reads
/// ``uiStatusLabel`` straight from the server-shaped entity. Status
/// drives only the pill colour, via a single switch — adding a new
/// [WithdrawalStatus] case is a compile-time error here.
///
/// Layout (matches the wallet TransactionRow visual rhythm):
///   leading icon (kind: bank / jazzcash)  |  title + subtitle  |  amount
///   bottom row spans the same width with the status pill on the left.
class WithdrawalHistoryRow extends StatelessWidget {
  final WithdrawalRequest request;

  const WithdrawalHistoryRow({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final pillColors = _pillColors(request.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LeadingIcon(kind: request.payout.kind),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.payout.label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  request.payout.masked,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatusPill(
                      label: request.uiStatusLabel,
                      backgroundColor: pillColors.bg,
                      foregroundColor: pillColors.fg,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime(request.requestedAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                if (request.adminExternalRef.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ref: ${request.adminExternalRef}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatRs(request.amount),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  /// Pill colour per status — one switch, exhaustive over the enum.
  /// Adding a new value to [WithdrawalStatus] forces an update here.
  _PillColors _pillColors(WithdrawalStatus status) => switch (status) {
        WithdrawalStatus.pendingReview => const _PillColors(
            bg: Color(0xFFFFF4D2),
            fg: Color(0xFF7A5A00),
          ),
        WithdrawalStatus.approved => const _PillColors(
            bg: Color(0xFFE0EAFF),
            fg: Color(0xFF1A3A8A),
          ),
        WithdrawalStatus.processed => const _PillColors(
            bg: Color(0xFFDCF5E1),
            fg: Color(0xFF1A6B36),
          ),
        WithdrawalStatus.rejected => const _PillColors(
            bg: Color(0xFFFEE0DE),
            fg: Color(0xFF7B0F0F),
          ),
      };

  /// Short relative-time string for the requestedAt timestamp.
  /// Same shape as TransactionRow's subtitle so the wallet history
  /// surfaces feel like one design.
  String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    // Beyond a week, render the calendar date.
    return '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
  }
}

class _LeadingIcon extends StatelessWidget {
  final String kind;
  const _LeadingIcon({required this.kind});

  @override
  Widget build(BuildContext context) {
    final icon = kind == 'bank'
        ? Icons.account_balance
        : kind == 'jazzcash'
            ? Icons.phone_iphone
            : Icons.payments_outlined;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppShapes.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
      );
}

class _PillColors {
  final Color bg;
  final Color fg;
  const _PillColors({required this.bg, required this.fg});
}

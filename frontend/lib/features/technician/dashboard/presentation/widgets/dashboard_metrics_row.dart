import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/technician_dashboard_entity.dart';

/// Daily Ledger card — Stitch's sticky-bottom layout.
///
/// Two stat columns separated by a vertical divider:
///   [ Jobs Completed | count ]   |   [ Cash Collected | Rs. amount ]
///
/// Cash is rendered in the secondary (success-green) ramp to draw the eye to
/// the technician's earnings — this is the dashboard's only "good news"
/// affordance, so it is intentionally chromatic against the otherwise neutral
/// surface.
class DashboardMetricsRow extends StatelessWidget {
  const DashboardMetricsRow({super.key, required this.metrics});
  final DashboardMetricsEntity metrics;

  @override
  Widget build(BuildContext context) {
    final cashFormatted =
        'Rs. ${NumberFormat('#,##0').format(metrics.cashCollectedToday.toInt())}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'Jobs Completed',
              value: '${metrics.jobsCompletedToday}',
              valueColor: AppColors.onSurface,
              alignEnd: false,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _Stat(
              label: 'Cash Collected',
              value: cashFormatted,
              valueColor: AppColors.secondary,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.36,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

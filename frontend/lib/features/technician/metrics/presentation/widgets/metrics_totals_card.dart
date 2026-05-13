import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/technician_metrics_entity.dart';

/// Two-stat hero card shown above the bar chart on the Metrics screen.
///
/// Left:  Jobs Done (neutral)
/// Right: Cash Collected (brand-blue, the headline number)
class MetricsTotalsCard extends StatelessWidget {
  const MetricsTotalsCard({super.key, required this.metrics});

  final TechnicianMetricsEntity metrics;

  @override
  Widget build(BuildContext context) {
    final cash = 'Rs. ${NumberFormat('#,##0').format(metrics.totalCash.toInt())}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'Jobs Done',
              value: '${metrics.totalJobs}',
              valueColor: AppColors.onSurface,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _Stat(
              label: 'Cash Collected',
              value: cash,
              valueColor: AppColors.primary,
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
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

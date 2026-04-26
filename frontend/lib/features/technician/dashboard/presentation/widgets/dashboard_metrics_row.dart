import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/technician_dashboard_entity.dart';

/// Purely presentational. Renders today's summary metrics as two side-by-side
/// cards at the bottom of the dashboard.
class DashboardMetricsRow extends StatelessWidget {
  const DashboardMetricsRow({super.key, required this.metrics});
  final DashboardMetricsEntity metrics;

  @override
  Widget build(BuildContext context) {
    final cashFormatted =
        'Rs. ${NumberFormat('#,##0').format(metrics.cashCollectedToday.toInt())}';

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.secondary,
            iconBackground: AppColors.secondaryContainer,
            label: 'Jobs Completed',
            value: '${metrics.jobsCompletedToday}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.payments_outlined,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primaryFixed,
            label: 'Cash Collected',
            value: cashFormatted,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppShapes.radiusSM),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.44,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

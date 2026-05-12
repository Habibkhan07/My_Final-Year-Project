import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/technician_metrics_entity.dart';

/// Two-section metrics card shown on the technician dashboard.
///
/// TODAY section  — 3 columns: Jobs Done · Cash Collected · Commission
/// THIS WEEK section — 2 columns: Jobs Done · Cash Collected
///
/// Color semantics:
///   Jobs     → [AppColors.onSurface]  (neutral count)
///   Cash     → [AppColors.secondary]  (green — money earned)
///   Commission → [AppColors.primary]  (brand blue — platform's cut)
class DashboardMetricsRow extends StatelessWidget {
  const DashboardMetricsRow({super.key, required this.metrics});

  final TechnicianMetricsEntity metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Section(
            label: 'TODAY',
            child: _TodayRow(metrics: metrics),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            indent: 16,
            endIndent: 16,
          ),
          _Section(
            label: 'THIS WEEK',
            child: _WeekRow(metrics: metrics),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.metrics});

  final TechnicianMetricsEntity metrics;

  @override
  Widget build(BuildContext context) {
    final cashFmt = 'Rs. ${NumberFormat('#,##0').format(metrics.cashCollectedToday.toInt())}';
    final commFmt = 'Rs. ${NumberFormat('#,##0').format(metrics.commissionDeductedToday.toInt())}';

    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: 'Jobs Done',
            value: '${metrics.jobsCompletedToday}',
            valueColor: AppColors.onSurface,
          ),
        ),
        _VerticalDivider(),
        Expanded(
          child: _Stat(
            label: 'Cash Collected',
            value: cashFmt,
            valueColor: AppColors.secondary,
          ),
        ),
        _VerticalDivider(),
        Expanded(
          child: _Stat(
            label: 'Commission',
            value: commFmt,
            valueColor: AppColors.primary,
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.metrics});

  final TechnicianMetricsEntity metrics;

  @override
  Widget build(BuildContext context) {
    final cashFmt = 'Rs. ${NumberFormat('#,##0').format(metrics.cashCollectedThisWeek.toInt())}';

    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: 'Jobs Done',
            value: '${metrics.jobsCompletedThisWeek}',
            valueColor: AppColors.onSurface,
          ),
        ),
        _VerticalDivider(),
        Expanded(
          child: _Stat(
            label: 'Cash Collected',
            value: cashFmt,
            valueColor: AppColors.secondary,
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.outlineVariant.withValues(alpha: 0.3),
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
    return Padding(
      padding: EdgeInsets.only(
        left: alignEnd ? 8 : 0,
        right: alignEnd ? 0 : 8,
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/technician_metrics_entity.dart';

/// Cash-collected bar chart for the Metrics screen.
///
/// One bar per [MetricsBucket]. The rightmost bar gets a stronger fill on
/// the Day view (labelled 'Today') so the protagonist is visually obvious.
/// X-axis labels are sampled for dense periods (Month = 30 bars) so the
/// labels never overlap on narrow screens.
class MetricsBarChart extends StatelessWidget {
  const MetricsBarChart({
    super.key,
    required this.buckets,
    required this.period,
  });

  final List<MetricsBucket> buckets;
  final MetricsPeriod period;

  /// Show every Nth label on dense periods so they don't collide.
  int get _labelStride => switch (period) {
        MetricsPeriod.month => 5, // 30 daily bars → show ~6 labels
        _ => 1,
      };

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCash = buckets.map((b) => b.cash).fold<double>(0, _max);
    // Round max up to a friendly gridline so the chart breathes.
    final niceMax = _niceCeil(maxCash);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: niceMax == 0 ? 1000 : niceMax,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipColor: (_) => AppColors.onSurface,
              getTooltipItem: (group, _, rod, _) {
                final bucket = buckets[group.x];
                return BarTooltipItem(
                  '${bucket.label}\nRs. ${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                  if (i % _labelStride != 0 && i != buckets.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      buckets[i].label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.outline,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: niceMax == 0 ? 250 : niceMax / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < buckets.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: buckets[i].cash,
                    width: switch (period) {
                      MetricsPeriod.month => 6,
                      MetricsPeriod.year => 14,
                      _ => 18,
                    },
                    color: _barColor(i),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 'Today' (Day view) and current-month bar (Year view) get the darker
  /// brand tone to call them out as the protagonist.
  Color _barColor(int i) {
    final isProtagonist =
        (period == MetricsPeriod.day && i == buckets.length - 1) ||
            (period == MetricsPeriod.year &&
                buckets[i].label == _currentMonthLabel());
    return isProtagonist ? AppColors.primary : AppColors.primaryContainer;
  }

  static double _max(double a, double b) => a > b ? a : b;

  /// Round up to a "nice" gridline. Keeps the y-axis tidy.
  static double _niceCeil(double v) {
    if (v <= 0) return 0;
    if (v <= 1000) return ((v / 100).ceil() * 100).toDouble();
    if (v <= 10000) return ((v / 1000).ceil() * 1000).toDouble();
    if (v <= 100000) return ((v / 10000).ceil() * 10000).toDouble();
    return ((v / 100000).ceil() * 100000).toDouble();
  }

  static const _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _currentMonthLabel() => _monthShort[DateTime.now().month - 1];
}

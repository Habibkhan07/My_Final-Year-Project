import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/technician_metrics_entity.dart';
import '../../domain/failures/metrics_failure.dart';
import '../notifiers/metrics_notifier.dart';
import '../widgets/metrics_bar_chart.dart';
import '../widgets/metrics_totals_card.dart';

/// Tech-only Metrics screen, reached from the bottom-nav "Metrics" tab.
///
/// Layout (top → bottom):
///   AppBar         — "Metrics" + back
///   SegmentedButton — Day · Week · Month · Year
///   MetricsTotalsCard — Jobs Done + Cash Collected (period totals)
///   "CASH COLLECTED" caption
///   MetricsBarChart — fl_chart bar chart of [MetricsBucket]s
///
/// State: the selected period is widget-local; each period has its own
/// Riverpod family entry (metricsProvider(period)) so tab switches are
/// instant once a period has loaded.
class MetricsScreen extends ConsumerStatefulWidget {
  const MetricsScreen({super.key});

  @override
  ConsumerState<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends ConsumerState<MetricsScreen> {
  MetricsPeriod _period = MetricsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(metricsProvider(_period));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Metrics'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(metricsProvider(_period).notifier).refresh(),
        child: async.when(
          loading: () => _Skeleton(period: _period, onPeriodChange: _setPeriod),
          error: (err, _) => _ErrorView(
            period: _period,
            onPeriodChange: _setPeriod,
            error: err is MetricsFailure ? err : const MetricsServerFailure(),
            onRetry: () =>
                ref.read(metricsProvider(_period).notifier).refresh(),
          ),
          data: (metrics) => _Loaded(
            metrics: metrics,
            period: _period,
            onPeriodChange: _setPeriod,
          ),
        ),
      ),
    );
  }

  void _setPeriod(MetricsPeriod p) => setState(() => _period = p);
}

// ---------------------------------------------------------------------------
// Period toggle — extracted so loading/error/data all use the same control
// ---------------------------------------------------------------------------

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period, required this.onChanged});

  final MetricsPeriod period;
  final ValueChanged<MetricsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MetricsPeriod>(
      segments: [
        for (final p in MetricsPeriod.values)
          ButtonSegment(value: p, label: Text(p.label)),
      ],
      selected: {period},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurfaceVariant,
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded state
// ---------------------------------------------------------------------------

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.metrics,
    required this.period,
    required this.onPeriodChange,
  });

  final TechnicianMetricsEntity metrics;
  final MetricsPeriod period;
  final ValueChanged<MetricsPeriod> onPeriodChange;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PeriodToggle(period: period, onChanged: onPeriodChange),
          const SizedBox(height: 16),
          MetricsTotalsCard(metrics: metrics),
          const SizedBox(height: 20),
          const _SectionLabel(label: 'CASH COLLECTED'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppShapes.radiusMD),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: MetricsBarChart(buckets: metrics.buckets, period: period),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.outline,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state — keep the period toggle visible so the tab is still usable
// ---------------------------------------------------------------------------

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.period, required this.onPeriodChange});

  final MetricsPeriod period;
  final ValueChanged<MetricsPeriod> onPeriodChange;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _PeriodToggle(period: period, onChanged: onPeriodChange),
        const SizedBox(height: 16),
        Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.period,
    required this.onPeriodChange,
    required this.error,
    required this.onRetry,
  });

  final MetricsPeriod period;
  final ValueChanged<MetricsPeriod> onPeriodChange;
  final MetricsFailure error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (error) {
      MetricsNetworkFailure() => (
        Icons.wifi_off,
        'No internet connection. Pull down to retry.',
      ),
      MetricsPermissionFailure() => (
        Icons.lock_outline,
        'You do not have permission to view metrics.',
      ),
      MetricsServerFailure() => (
        Icons.error_outline,
        'Something went wrong. Please retry.',
      ),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _PeriodToggle(period: period, onChanged: onPeriodChange),
        const SizedBox(height: 48),
        Icon(icon, size: 56, color: AppColors.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShapes.radiusXL),
              ),
              minimumSize: const Size(160, 48),
            ),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

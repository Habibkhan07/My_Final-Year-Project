import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/technician_dashboard_entity.dart';

/// Purely presentational. Renders the technician's remaining jobs for today
/// below the Up Next card.
///
/// Visual contract:
/// - Non-empty: white card with one row per job, no dividers (tonal separation
///   only — consistent with the FieldOps "No-Line" rule).
/// - Empty: inline "all done" message.
class LaterTodayList extends StatelessWidget {
  const LaterTodayList({super.key, required this.jobs});
  final List<LaterTodayJobEntity> jobs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(text: 'Later Today'),
        const SizedBox(height: 8),
        if (jobs.isEmpty)
          const _EmptyState()
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppShapes.radiusMD),
            ),
            child: Column(
              children: [
                for (int i = 0; i < jobs.length; i++)
                  _JobRow(job: jobs[i], isLast: i == jobs.length - 1),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.isLast});
  final LaterTodayJobEntity job;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => GoRouter.of(context).push('/booking/${job.jobId}'),
      borderRadius: BorderRadius.vertical(
        bottom: isLast
            ? const Radius.circular(AppShapes.radiusMD)
            : Radius.zero,
      ),
      highlightColor: AppColors.surfaceContainerHigh,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Scheduled time
            SizedBox(
              width: 56,
              child: Text(
                DateFormat.jm().format(job.scheduledTime),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Service title + address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.serviceTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.addressText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
      ),
      child: const Text(
        'No more jobs scheduled for today',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

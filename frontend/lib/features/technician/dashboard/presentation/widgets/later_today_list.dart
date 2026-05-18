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
        const _SectionHeading(),
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

/// Section header. Mirrors the icon + uppercase-label treatment of the
/// UP NEXT card's internal header so the two sections feel of-a-piece:
/// both are labelled "this is what's queued for you", just at
/// different priority levels.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(
          Icons.event_note_outlined,
          size: 14,
          color: AppColors.primaryContainer,
        ),
        SizedBox(width: 6),
        Text(
          'LATER TODAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.onSurface,
          ),
        ),
      ],
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

/// Empty state for the Later Today list. Chrome (surface + shadow)
/// was dropped because matching the "real content" card weight made
/// an empty section read as if it had content. A plain centred line
/// on the page background communicates "nothing here" more honestly.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Text(
        'Nothing else scheduled for today.',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

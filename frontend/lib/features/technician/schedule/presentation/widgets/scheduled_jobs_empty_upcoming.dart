import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../customer/bookings/presentation/utils/bookings_palette.dart';

/// Empty state for the tech's Upcoming Schedule.
///
/// Tech-framed copy: a tech with no upcoming jobs is either offline or
/// waiting on matchmaking. We point them at the Online toggle on the
/// dashboard rather than offering a CTA here (the empty state is
/// passive — the active "go online" affordance lives on the dashboard).
class ScheduledJobsEmptyUpcoming extends StatelessWidget {
  const ScheduledJobsEmptyUpcoming({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                color: BookingsPalette.brandPrimaryTint06,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.event_available_outlined,
                size: 72,
                color: BookingsPalette.brandPrimary.withValues(alpha: 0.40),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            const Text(
              'No upcoming jobs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            const Text(
              "When customers book you, they'll show up here.\nGo online from your dashboard to start receiving requests.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../customer/bookings/presentation/utils/bookings_palette.dart';

/// Empty state for the tech's Past Schedule — illustration + headline +
/// body, no CTA.
class ScheduledJobsEmptyPast extends StatelessWidget {
  const ScheduledJobsEmptyPast({super.key});

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
                Icons.history,
                size: 72,
                color: BookingsPalette.brandPrimary.withValues(alpha: 0.40),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            const Text(
              'No past jobs',
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
              'Your completed and cancelled jobs will show up here.',
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

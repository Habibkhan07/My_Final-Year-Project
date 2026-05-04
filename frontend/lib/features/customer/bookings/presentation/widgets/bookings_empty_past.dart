import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Empty state for the Past segment — illustration + headline + body, no
/// CTA (§7.3).
class BookingsEmptyPast extends StatelessWidget {
  const BookingsEmptyPast({super.key});

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
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.history,
                size: 72,
                color: AppColors.outlineVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            const Text(
              'No past bookings',
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
              'Your booking history will show up here once you complete a visit.',
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

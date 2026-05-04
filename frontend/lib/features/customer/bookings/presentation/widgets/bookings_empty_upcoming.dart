import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Empty state for the Upcoming segment — illustration + headline + body
/// + "Browse services" CTA (§7.2).
class BookingsEmptyUpcoming extends StatelessWidget {
  const BookingsEmptyUpcoming({super.key});

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
                Icons.event_available_outlined,
                size: 72,
                color: AppColors.outlineVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            const Text(
              'No upcoming bookings',
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
              'Browse services to book a technician for your next visit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            FilledButton(
              onPressed: () => context.go('/home'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s6,
                  vertical: AppSpacing.s3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppShapes.radiusXL),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              child: const Text('Browse services'),
            ),
          ],
        ),
      ),
    );
  }
}

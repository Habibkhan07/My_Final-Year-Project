import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Centered error / offline state with a single Retry CTA.
///
/// Three named constructors map to the three sealed-failure UI variants
/// (offline / server / unknown). Copy is tech-framed — "your schedule"
/// not "your bookings".
class ScheduledJobsErrorState extends StatelessWidget {
  const ScheduledJobsErrorState._({
    required this.icon,
    required this.headline,
    required this.body,
    required this.onRetry,
  });

  factory ScheduledJobsErrorState.offline({required VoidCallback onRetry}) =>
      ScheduledJobsErrorState._(
        icon: Icons.cloud_off_outlined,
        headline: "You're offline",
        body: 'Connect and try again.',
        onRetry: onRetry,
      );

  factory ScheduledJobsErrorState.server({required VoidCallback onRetry}) =>
      ScheduledJobsErrorState._(
        icon: Icons.error_outline,
        headline: "Couldn't load your schedule",
        body: 'Something went wrong on our end. Please try again.',
        onRetry: onRetry,
      );

  factory ScheduledJobsErrorState.unknown({required VoidCallback onRetry}) =>
      ScheduledJobsErrorState._(
        icon: Icons.error_outline,
        headline: "Couldn't load your schedule",
        body: 'Something went wrong. Please try again.',
        onRetry: onRetry,
      );

  final IconData icon;
  final String headline;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surfaceContainerLowest,
                minimumSize: const Size(200, AppSpacing.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppShapes.radiusXL),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Shimmer placeholder for [BookingCard]. Dimensions intentionally mirror
/// the real card so there's no layout flash on data arrival (§7.1).
///
/// Render 4 of these stacked with the same `s3` (12pt) gap the list uses
/// between real cards.
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerLow,
      period: const Duration(milliseconds: 1200),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — service icon + name + pill placeholder.
            Row(
              children: [
                _box(width: 24, height: 24, radius: 6),
                const SizedBox(width: AppSpacing.s2),
                _box(width: 90, height: 10, radius: 4),
                const Spacer(),
                _box(width: 90, height: 22, radius: AppShapes.radiusFull),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            // Headline row — avatar + 2 lines of headline.
            Row(
              children: [
                _box(width: 48, height: 48, radius: 24),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(width: double.infinity, height: 16, radius: 4),
                      const SizedBox(height: 6),
                      _box(width: 160, height: 16, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            _box(width: double.infinity, height: 1, radius: 0),
            const SizedBox(height: AppSpacing.s3),
            // Meta — date row.
            Row(
              children: [
                _box(width: 18, height: 18, radius: 4),
                const SizedBox(width: AppSpacing.s2),
                _box(width: 140, height: 12, radius: 4),
              ],
            ),
            const SizedBox(height: 6),
            // Meta — address row.
            Row(
              children: [
                _box(width: 18, height: 18, radius: 4),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: _box(width: double.infinity, height: 12, radius: 4),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            _box(width: double.infinity, height: 1, radius: 0),
            const SizedBox(height: AppSpacing.s2),
            // Price row.
            Row(
              children: [
                _box(width: 18, height: 18, radius: 4),
                const SizedBox(width: AppSpacing.s2),
                _box(width: 80, height: 12, radius: 4),
                const Spacer(),
                _box(width: 90, height: 18, radius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

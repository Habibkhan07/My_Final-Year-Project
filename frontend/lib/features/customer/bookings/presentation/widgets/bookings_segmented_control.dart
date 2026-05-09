import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/booking_segment.dart';
import '../providers/customer_bookings_counts_notifier.dart';
import '../providers/selected_segment_notifier.dart';

/// Two-segment switcher for "Upcoming" / "Past".
///
/// Reads [selectedSegmentProvider] for the active value and
/// [customerBookingsCountsProvider] for badge counts. Counts render as
/// `· N` appended to the label when the counts notifier is in
/// [AsyncData] — clean omission on loading or error (no `· —`
/// placeholder, per §4.2).
///
/// Styled per §3.6 against the project's existing tokens. Doesn't use
/// Material 3's [SegmentedButton] because we need a tighter, custom-padded
/// look that matches the Stitch reference; building it from a row of
/// tappable [Material] surfaces gives full control.
class BookingsSegmentedControl extends ConsumerWidget {
  const BookingsSegmentedControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSegmentProvider);
    final countsAsync = ref.watch(customerBookingsCountsProvider);

    int? upcomingCount;
    int? pastCount;
    countsAsync.whenData((counts) {
      upcomingCount = counts.upcoming;
      pastCount = counts.past;
    });

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppShapes.radiusSM),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Upcoming',
            count: upcomingCount,
            isActive: selected == BookingSegment.upcoming,
            onTap: () => ref
                .read(selectedSegmentProvider.notifier)
                .set(BookingSegment.upcoming),
          ),
          _Segment(
            label: 'Past',
            count: pastCount,
            isActive: selected == BookingSegment.past,
            onTap: () => ref
                .read(selectedSegmentProvider.notifier)
                .set(BookingSegment.past),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = count == null ? label : '$label · $count';
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.s2,
                horizontal: AppSpacing.s4,
              ),
              child: Text(
                display,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Warning-tone strip pinned between the segmented control and the list
/// when the displayed page came from the offline cache.
///
/// Same UX as the customer-side `BookingsOfflineBanner`: communicates
/// staleness, not connection loss.
class ScheduledJobsOfflineBanner extends StatelessWidget {
  const ScheduledJobsOfflineBanner({
    super.key,
    required this.cachedAt,
    required this.serverNow,
    required this.onRefresh,
  });

  final DateTime cachedAt;
  final DateTime serverNow;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final minutes = serverNow.difference(cachedAt).inMinutes.clamp(0, 999999);
    final ageLabel = _ageLabel(minutes);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixedDim.withValues(alpha: 0.20),
        border: Border(
          bottom: BorderSide(
            color: AppColors.tertiaryFixedDim.withValues(alpha: 0.40),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: AppColors.onTertiaryFixed,
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              'Offline · last updated $ageLabel',
              style: const TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onTertiaryFixed,
              ),
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
            visualDensity: VisualDensity.compact,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
              size: 18,
              color: AppColors.onTertiaryFixed,
            ),
          ),
        ],
      ),
    );
  }

  String _ageLabel(int minutes) {
    if (minutes < 1) return 'just now';
    if (minutes == 1) return '1 min ago';
    if (minutes < 60) return '$minutes min ago';
    final hours = minutes ~/ 60;
    if (hours == 1) return '1 hour ago';
    if (hours < 24) return '$hours hours ago';
    final days = hours ~/ 24;
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}

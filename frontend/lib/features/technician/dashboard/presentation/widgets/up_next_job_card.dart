import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/widgets/map/job_location_map.dart';
import '../../domain/entities/technician_dashboard_entity.dart';

/// Purely presentational. Shows the next scheduled job or an all-clear
/// empty state when [job] is null.
class UpNextJobCard extends StatelessWidget {
  const UpNextJobCard({super.key, required this.job});
  final UpNextJobEntity? job;

  @override
  Widget build(BuildContext context) {
    if (job == null) return const _NoUpNextState();
    return _JobCard(job: job!);
  }
}

// ---------------------------------------------------------------------------
// Loaded state
// ---------------------------------------------------------------------------

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final UpNextJobEntity job;

  String get _formattedTime => DateFormat.jm().format(job.scheduledTime);

  String get _timeUntil {
    final diff = job.scheduledTime.difference(DateTime.now());
    if (diff.isNegative || diff.inMinutes == 0) return 'Now';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return m == 0 ? 'In ${h}h' : 'In ${h}h ${m}m';
  }

  Future<void> _startNavigation() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${job.lat},${job.lng}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(formattedTime: _formattedTime, timeUntil: _timeUntil),
          _ServiceTitle(title: job.serviceTitle),
          _JobMeta(customerName: job.customerName, addressText: job.addressText),
          _LockedMap(lat: job.lat, lng: job.lng),
          _ActionRow(
            onNavigate: _startNavigation,
            onCall: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Customer contact details coming soon.')),
              ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.formattedTime, required this.timeUntil});
  final String formattedTime;
  final String timeUntil;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          const Text(
            'Up Next',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formattedTime,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryContainer,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppShapes.radiusFull),
            ),
            child: Text(
              timeUntil,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTitle extends StatelessWidget {
  const _ServiceTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.44,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

class _JobMeta extends StatelessWidget {
  const _JobMeta({required this.customerName, required this.addressText});
  final String customerName;
  final String addressText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          _InfoRow(icon: Icons.person_outline, text: customerName),
          const SizedBox(height: 5),
          _InfoRow(icon: Icons.location_on_outlined, text: addressText),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LockedMap extends StatelessWidget {
  const _LockedMap({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: JobLocationMap(
        lat: lat,
        lng: lng,
        height: 140,
        borderRadius: BorderRadius.circular(AppShapes.radiusSM),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onNavigate, required this.onCall});
  final VoidCallback onNavigate;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(child: _NavButton(onTap: onNavigate)),
          const SizedBox(width: 8),
          _CallButton(onTap: onCall),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.ctaGradient,
          borderRadius: BorderRadius.circular(AppShapes.radiusXL),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Start Navigation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(AppShapes.radiusSM),
        ),
        child: const Icon(Icons.phone_outlined, color: AppColors.onSurfaceVariant, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _NoUpNextState extends StatelessWidget {
  const _NoUpNextState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 40, color: AppColors.secondary),
          SizedBox(height: 10),
          Text(
            'No upcoming jobs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "You're all caught up for today",
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

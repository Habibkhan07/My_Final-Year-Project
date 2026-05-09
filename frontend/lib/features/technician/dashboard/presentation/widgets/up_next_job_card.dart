import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/widgets/map/job_location_map.dart';
import '../../domain/entities/technician_dashboard_entity.dart';
import '../providers/current_position_provider.dart';

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

/// Stateful so we can re-render the "In Xm" pill on a 30-second cadence
/// without forcing a full dashboard refetch. 30s keeps display within ±30s of
/// truth — finer ticking would burn battery for no perceptible benefit.
class _JobCard extends StatefulWidget {
  const _JobCard({required this.job});
  final UpNextJobEntity job;

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _formattedTime => DateFormat.jm().format(widget.job.scheduledTime);

  String get _timeUntil {
    final diff = widget.job.scheduledTime.difference(DateTime.now());
    if (diff.isNegative || diff.inMinutes == 0) return 'Now';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return m == 0 ? 'In ${h}h' : 'In ${h}h ${m}m';
  }

  Future<void> _startNavigation() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.job.lat},${widget.job.lng}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCustomer() async {
    final phone = widget.job.customerPhone;
    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Customer phone unavailable.')),
        );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
          _ServiceTitle(title: widget.job.serviceTitle),
          _JobMeta(
            customerName: widget.job.customerName,
            addressText: widget.job.addressText,
            destLat: widget.job.lat,
            destLng: widget.job.lng,
          ),
          _LockedMap(lat: widget.job.lat, lng: widget.job.lng),
          _ActionStack(
            onNavigate: _startNavigation,
            onCall: _callCustomer,
            phoneAvailable:
                widget.job.customerPhone != null &&
                widget.job.customerPhone!.isNotEmpty,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppShapes.radiusMD),
          topRight: Radius.circular(AppShapes.radiusMD),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, size: 14, color: AppColors.primaryContainer),
          const SizedBox(width: 6),
          Text(
            'UP NEXT • $formattedTime',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppShapes.radiusSM),
            ),
            child: Text(
              timeUntil,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
  const _JobMeta({
    required this.customerName,
    required this.addressText,
    required this.destLat,
    required this.destLng,
  });

  final String customerName;
  final String addressText;
  final double destLat;
  final double destLng;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(icon: Icons.person_outline, text: customerName),
          const SizedBox(height: 5),
          _AddressRow(
            addressText: addressText,
            destLat: destLat,
            destLng: destLng,
          ),
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
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Address row with an optional "X.Y km away" subtext.
///
/// The subtext silently hides when:
///   - location service is disabled
///   - permission was denied (one-shot ask happens on first read)
///   - the geolocator timed out
/// All three cases are handled inside `currentPositionProvider` which simply
/// resolves to `null`. We never block the address on a missing position.
class _AddressRow extends ConsumerWidget {
  const _AddressRow({
    required this.addressText,
    required this.destLat,
    required this.destLng,
  });

  final String addressText;
  final double destLat;
  final double destLng;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(currentPositionProvider);
    final position = positionAsync.value;

    String? distanceText;
    if (position != null) {
      final km = _haversineKm(
        position.latitude,
        position.longitude,
        destLat,
        destLng,
      );
      distanceText = '${km.toStringAsFixed(1)} km away';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                addressText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (distanceText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    distanceText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Great-circle distance in km between two lat/lng pairs.
/// Earth radius constant: 6371 km (mean radius — sufficient for UI display).
double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _deg2rad(double deg) => deg * (math.pi / 180.0);

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

/// Vertical CTA stack (Stitch layout):
///   [ Start Navigation ]    gradient, h=56, full-width   (primary)
///   [ Contact Customer ]    surface-container-low, h=48  (secondary)
///
/// Contact Customer is disabled-styled when no phone number is present.
class _ActionStack extends StatelessWidget {
  const _ActionStack({
    required this.onNavigate,
    required this.onCall,
    required this.phoneAvailable,
  });

  final VoidCallback onNavigate;
  final VoidCallback onCall;
  final bool phoneAvailable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          _NavButton(onTap: onNavigate),
          const SizedBox(height: 8),
          _CallButton(onTap: onCall, enabled: phoneAvailable),
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
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.ctaGradient,
          borderRadius: BorderRadius.circular(AppShapes.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Start Navigation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
  const _CallButton({required this.onTap, required this.enabled});
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? AppColors.onSurface : AppColors.outline;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppShapes.radiusXL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call_outlined, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              'Contact Customer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
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
          Icon(
            Icons.check_circle_outline,
            size: 40,
            color: AppColors.secondary,
          ),
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  void _openBooking() {
    // Pushes the audience-shared BookingOrchestratorScreen. `viewerRole`
    // is derived server-side by comparing the auth user to the booking's
    // customer — so the same route hands the tech the technician view.
    //
    // `push`, not `go`: the dashboard remains on the back-stack so the
    // AppBar back arrow inside the orchestrator can pop back here. `go`
    // replaces history and would leave the back arrow with nothing to do.
    GoRouter.of(context).push('/booking/${widget.job.jobId}');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Opaque hit-test means a tap anywhere on the card opens the
      // booking detail. Previously a `TechNavigationPanel` lived at the
      // bottom of the card with its own Start Navigation + Call buttons;
      // that path bypassed the orchestrator-mounted foreground location
      // controller and so never actually broadcast GPS during the drive
      // (see commit history). It also doubled the action surface — same
      // verb on two surfaces with subtly different behaviour. The
      // dashboard's role is now strictly preview-and-tap-through: the
      // map + meta give the tech enough context to recognise the job,
      // the footer hint signals where to act, and tapping anywhere
      // opens the orchestrator where Start Navigation lives.
      behavior: HitTestBehavior.opaque,
      onTap: _openBooking,
      child: Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: JobLocationMap(
                lat: widget.job.lat,
                lng: widget.job.lng,
                height: 140,
                borderRadius: BorderRadius.circular(AppShapes.radiusSM),
              ),
            ),
            const _TapToOpenHint(),
          ],
        ),
      ),
    );
  }
}

/// Visual closure for the card body and a soft affordance reminder
/// that the whole card is tappable. Not a button — `GestureDetector`
/// on the parent already owns the tap; this row would otherwise
/// steal the gesture and split the action surface again.
///
/// Tone borrows the `primaryContainer` accent the card header uses
/// for its timer icon, so the footer reads as part of the same
/// accent family rather than a new colour introduced in isolation.
class _TapToOpenHint extends StatelessWidget {
  const _TapToOpenHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          const Icon(
            Icons.navigation_outlined,
            size: 14,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: 6),
          const Text(
            'Tap to start navigation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: AppColors.primaryContainer,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 11,
            color: AppColors.primaryContainer.withValues(alpha: 0.65),
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
          // "Starts" disambiguates from current-time at a glance. Bare
          // "UP NEXT • 5:57 AM" read like "it is 5:57 AM now" on the
          // tech's first scan.
          Text(
            'UP NEXT • Starts $formattedTime',
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

  // Backend builds `service_title` as "{parent service} — {gig name}"
  // when a gig is in play (e.g. "AC Repair & Service — Freon Gas
  // Top-up"). The em-dash form crammed both into a single bolded
  // string that wrapped to two lines and made the gig — the
  // identifier the tech actually scans for — fight the parent
  // category for visual weight. Splitting on the separator promotes
  // the gig to the headline and demotes the parent to a small
  // category-style eyebrow above it.
  //
  // Fragility note: this is wire-format coupling. If the backend
  // changes the separator (or stops including the parent), the
  // fall-through renders the unsplit string as-is — no breakage,
  // just no eyebrow.
  static const _kSep = ' — ';

  @override
  Widget build(BuildContext context) {
    final idx = title.indexOf(_kSep);
    final hasParent = idx > 0;
    final parent = hasParent ? title.substring(0, idx) : null;
    final gig = hasParent ? title.substring(idx + _kSep.length) : title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parent != null) ...[
            Text(
              parent.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            gig,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.44,
              height: 1.15,
              color: AppColors.onSurface,
            ),
          ),
        ],
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
    // Bottom padding bumped from 12 → 16 so the address row doesn't
    // crowd the map's top edge — minor but the previous spacing
    // read as tight in the v1 audit screenshot.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

/// Address row with an optional distance chip on the right.
///
/// The chip silently hides when:
///   - location service is disabled
///   - permission was denied (one-shot ask happens on first read)
///   - the geolocator timed out
/// All three cases are handled inside `currentPositionProvider` which simply
/// resolves to `null`. We never block the address on a missing position.
///
/// Distance was promoted from sub-text to a right-aligned chip after
/// audit feedback that "X.Y km away" was the smallest, lightest piece
/// of text on the card despite being one of the most decision-relevant
/// numbers for a tech about to drive. The chip uses the same
/// `primaryContainer` tint family the card header and footer hint use,
/// so the card reads as one accent system.
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
      distanceText = '${km.toStringAsFixed(1)} km';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            addressText,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (distanceText != null) ...[
          const SizedBox(width: 8),
          _DistanceChip(text: distanceText),
        ],
      ],
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppShapes.radiusSM),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryContainer,
          letterSpacing: 0.2,
        ),
      ),
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

// LiveTrackingMap — composed widget rendering the technician's live
// position, the route polyline, the ETA pill, the connection-quality
// strip, the phone-call shortcut, and the recentre FAB. Provider-
// agnostic (works with both OsmAppMap and GoogleAppMap via
// appMapBuilderProvider).
//
// UX brief: app's audience is illiterate technicians and customers, so:
//   • Map fills the body. Markers are oversized 56px bubbles with
//     instantly-recognisable Material icons (house / motorbike / walk).
//   • Smooth marker tween between 5s GPS frames — no teleport jumps.
//   • Big ETA pill with clock icon + headline minutes + small distance.
//   • Connection-quality strip uses colour + icon + plain copy.
//   • Phone-call FAB lets the customer (or tech) tap-call without
//     navigating away from the map.
//   • Recentre FAB appears whenever the user manually pans, lets them
//     re-engage auto-follow with one tap.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../realtime/presentation/notifiers/system_event_notifier.dart';
import 'directions_failures.dart';
import 'i_app_map.dart';
import 'i_directions_service.dart';
import 'map_provider.dart';

/// Whether the technician is actively driving (rotates marker to GPS
/// heading) or has arrived (stationary person icon, no rotation).
enum TrackingPhase { enRoute, arrived }

/// Connection-quality lozenge state.
enum _ConnectionQuality { good, weak, offline }

class LiveTrackingMap extends ConsumerStatefulWidget {
  /// Latest known technician position. `null` when no frame has
  /// arrived yet (renders the "waiting…" pill instead of a marker).
  final LatLng? technicianPosition;

  /// Heading of the latest GPS frame, in degrees clockwise from
  /// north. `null` when device returns no heading (stationary or
  /// indoor fix).
  final double? technicianHeadingDegrees;

  /// Wall-clock instant the latest frame arrived at the client. Used
  /// for the staleness banner — `null` until the first frame.
  final DateTime? lastFrameAt;

  /// Customer destination — fixed for the booking's lifetime.
  final LatLng destination;

  /// Drives the technician marker icon (motorbike vs walking person).
  final TrackingPhase phase;

  /// Phone number for the call FAB. When `null`, the FAB is hidden.
  /// Live tracking screens display this only when the booking has the
  /// counterparty's phone surfaced (server controls visibility).
  final String? callPhoneNumber;

  /// Copy shown on the call FAB tooltip and the snackbar if launching
  /// the dialler fails. Defaults to "Call".
  final String callTooltip;

  const LiveTrackingMap({
    super.key,
    required this.technicianPosition,
    required this.destination,
    required this.phase,
    this.technicianHeadingDegrees,
    this.lastFrameAt,
    this.callPhoneNumber,
    this.callTooltip = 'Call',
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap>
    with SingleTickerProviderStateMixin {
  // ─── Tunables (single source of truth) ─────────────────────────────
  static const double _kPolylineRefreshDistanceMeters = 500.0;
  static const int _kPolylineMinIntervalSeconds = 30;
  // Audit H7 (W-14): even when the tech hasn't moved, the polyline /
  // ETA must be refreshed past this max-staleness bound so a stationary
  // tech at a stoplight doesn't keep showing a 5-minute-old ETA.
  static const int _kPolylineMaxStaleSeconds = 300; // 5 minutes
  static const Duration _kStalenessWeakThreshold = Duration(seconds: 15);
  static const Duration _kStalenessOfflineThreshold = Duration(seconds: 60);
  // Slightly under the 5s GPS cadence so the tween settles before the
  // next frame lands — overshoot would make the marker look "jittery".
  static const Duration _kFrameTweenDuration = Duration(milliseconds: 4800);
  // Beyond this distance between frames we hard-set instead of
  // tweening — protects against GPS glitches that animate the marker
  // through the wrong streets mid-route.
  static const double _kHardJumpDistanceMeters = 200.0;
  static const double _kFollowZoom = 16.0;

  // ─── Marker tween ──────────────────────────────────────────────────
  late final AnimationController _markerAnim;
  LatLng? _renderedPosition; // currently-displayed marker position
  LatLng? _tweenFromPosition;
  LatLng? _tweenToPosition;
  double _renderedHeading = 0.0;

  // ─── Polyline fetch state ──────────────────────────────────────────
  DirectionsResult? _directions;
  LatLng? _polylineAnchor; // tech position when last fetch fired
  bool _fetching = false; // re-entry guard, set BEFORE await

  // ─── ETA tickdown ──────────────────────────────────────────────────
  int _etaCountdownSeconds = 0;
  Timer? _etaTicker;

  // ─── Staleness detection ──────────────────────────────────────────
  // Tick once every 5s to re-evaluate the staleness band so the
  // banner appears even if no new frame arrives.
  Timer? _stalenessTicker;
  // Audit H9 (W-2): memoize the last quality so the ticker only
  // triggers a rebuild when the quality band actually transitions —
  // the previous unconditional setState burned battery rebuilding
  // for a quality that hadn't changed in minutes.
  _ConnectionQuality _lastQuality = _ConnectionQuality.good;

  // ─── Camera follow ────────────────────────────────────────────────
  bool _autoFollow = true;
  bool _firstFitDone = false;
  // Programmatic camera target — setting this drives the underlying
  // map widget via `cameraTarget` prop. We `null`-out after fitting
  // to bounds so the user can pan freely afterward.
  LatLng? _cameraTarget;
  double? _cameraZoom;
  List<LatLng>? _cameraBounds;

  @override
  void initState() {
    super.initState();
    _markerAnim = AnimationController(
      vsync: this,
      duration: _kFrameTweenDuration,
    )..addListener(_onTweenTick);
    // Audit H9: only rebuild on a quality-band transition. Cheap getter
    // call, expensive setState — gating reduces the rebuild rate from
    // every-5s to "every time the band changes" (typically zero or
    // a handful of times in a booking).
    _stalenessTicker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = _quality;
      if (next != _lastQuality) {
        setState(() => _lastQuality = next);
      }
    });
    _lastQuality = _quality;
    // Seed marker rendering from initial widget state.
    _renderedPosition = widget.technicianPosition;
    _renderedHeading = widget.technicianHeadingDegrees ?? 0.0;
    if (widget.technicianPosition != null) {
      _scheduleInitialFit();
      _maybeFetchDirections();
    }
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPos = oldWidget.technicianPosition;
    final newPos = widget.technicianPosition;

    // Audit H6 (W-5): destination can change mid-tracking when admin
    // reschedules / corrects the address. Without this, the polyline
    // stays anchored to the OLD destination forever (cooldown +
    // distance gate both fail to refire). Force a fresh fetch by
    // clearing the prior result and bypassing the cooldown.
    if (oldWidget.destination != widget.destination) {
      _directions = null;
      _polylineAnchor = null;
      _maybeFetchDirections();
    }

    // Audit H9 (W-3): the ETA tickdown timer was never cancelled when
    // the booking transitioned EN_ROUTE → ARRIVED. Cancel here so the
    // 1Hz rebuild storm stops the moment the tech arrives.
    if (oldWidget.phase != widget.phase &&
        widget.phase == TrackingPhase.arrived) {
      _etaTicker?.cancel();
      _etaTicker = null;
      _etaCountdownSeconds = 0;
    }

    if (newPos != null && oldPos == null) {
      // First frame — hard-set, no tween.
      _renderedPosition = newPos;
      _renderedHeading = widget.technicianHeadingDegrees ?? 0.0;
      _scheduleInitialFit();
      _maybeFetchDirections();
      setState(() {});
      return;
    }

    if (newPos != null && oldPos != null && newPos != oldPos) {
      final jump = _haversineMeters(oldPos, newPos);
      if (jump > _kHardJumpDistanceMeters) {
        // Too far — likely a GPS glitch; hard-set rather than animate
        // the marker through unrelated streets.
        _renderedPosition = newPos;
        _renderedHeading = widget.technicianHeadingDegrees ?? _renderedHeading;
      } else {
        _tweenFromPosition = oldPos;
        _tweenToPosition = newPos;
        _markerAnim
          ..stop()
          ..value = 0.0
          ..forward();
        // Heading lerp would need angular wrap-around handling; v1
        // hard-sets heading to the latest value (visual is fine since
        // direction changes are usually correlated with movement).
        _renderedHeading = widget.technicianHeadingDegrees ?? _renderedHeading;
      }
      _maybeFetchDirections();
      _maybeFollowCamera();
    }
  }

  void _onTweenTick() {
    final from = _tweenFromPosition;
    final to = _tweenToPosition;
    if (from == null || to == null) return;
    final t = _markerAnim.value;
    final lat = from.latitude + (to.latitude - from.latitude) * t;
    final lng = from.longitude + (to.longitude - from.longitude) * t;
    setState(() {
      _renderedPosition = LatLng(lat, lng);
    });
    if (_markerAnim.value >= 1.0) {
      _renderedPosition = to;
    }
  }

  @override
  void dispose() {
    _markerAnim.dispose();
    _etaTicker?.cancel();
    _stalenessTicker?.cancel();
    super.dispose();
  }

  // ─── Initial camera fit ────────────────────────────────────────────

  void _scheduleInitialFit() {
    if (_firstFitDone) return;
    final tech = widget.technicianPosition;
    if (tech == null) return;
    _cameraBounds = [tech, widget.destination];
    _cameraTarget = null;
    _firstFitDone = true;
    // Schedule a follow-up to clear the bounds prop, otherwise rebuild
    // would re-fit on every frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _cameraBounds = null;
      });
    });
  }

  void _maybeFollowCamera() {
    if (!_autoFollow) return;
    final tech = widget.technicianPosition;
    if (tech == null) return;
    _cameraTarget = tech;
    _cameraZoom = _kFollowZoom;
    // Clear next frame so the user can pan thereafter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _cameraTarget = null;
      });
    });
  }

  void _onUserGesture() {
    if (_autoFollow) {
      setState(() => _autoFollow = false);
    }
  }

  void _recentre() {
    final tech = widget.technicianPosition;
    if (tech == null) return;
    setState(() {
      _autoFollow = true;
      _cameraTarget = tech;
      _cameraZoom = _kFollowZoom;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _cameraTarget = null;
      });
    });
  }

  // ─── Polyline fetch ────────────────────────────────────────────────

  Future<void> _maybeFetchDirections() async {
    final tech = widget.technicianPosition;
    if (tech == null || _fetching) return;

    final hasDirections = _directions != null && _polylineAnchor != null;
    final movedFar =
        hasDirections &&
        _haversineMeters(tech, _polylineAnchor!) >
            _kPolylineRefreshDistanceMeters;
    final ageSeconds = hasDirections
        ? DateTime.now().difference(_directions!.fetchedAt).inSeconds
        : 0;
    final cooldownPassed =
        !hasDirections || ageSeconds >= _kPolylineMinIntervalSeconds;
    // Audit H7 (W-14): the cooldown is a *minimum* — after 5 minutes
    // refetch unconditionally even if the tech hasn't moved. A
    // stationary tech at a stoplight would otherwise show the original
    // ETA from when the route was first computed.
    final maxStaleExceeded =
        hasDirections && ageSeconds >= _kPolylineMaxStaleSeconds;
    final shouldFetch =
        maxStaleExceeded || ((!hasDirections || movedFar) && cooldownPassed);
    if (!shouldFetch) return;

    _fetching = true; // before await — re-entry guard
    try {
      final svc = ref.read(directionsServiceProvider);
      final result = await svc.getRoute(
        origin: tech,
        destination: widget.destination,
      );
      if (!mounted) return;
      setState(() {
        _directions = result;
        _polylineAnchor = tech;
        _etaCountdownSeconds = result.etaSeconds;
      });
      _etaTicker?.cancel();
      // Don't start a 1Hz tick at all if we're already arrived — the
      // ETA pill is hidden in that phase.
      if (widget.phase == TrackingPhase.arrived) return;
      _etaTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        // Audit H9 (W-3): when countdown hits zero, cancel the ticker
        // — the previous version kept calling setState forever with
        // a clamped-zero value, churning rebuilds for no visual change.
        // Audit P2-2: cancel BEFORE the value would render as 0.
        // The pill formatter is "X min" — letting it tick to 0 paints
        // "0 min" for one frame before the next state change clears
        // it. Floor the displayed value at 1 min instead; the next
        // directions refresh resets it cleanly.
        final next = _etaCountdownSeconds - 1;
        if (next <= 0) {
          _etaTicker?.cancel();
          _etaTicker = null;
          return;
        }
        setState(() => _etaCountdownSeconds = next);
      });
    } on DirectionsFailure {
      // Soft-fail. Keep last polyline / ETA. Don't snackbar — routing
      // is best-effort polish, not load-bearing UX.
    } finally {
      if (mounted) {
        setState(() => _fetching = false);
      } else {
        _fetching = false;
      }
    }
  }

  // ─── Connection quality ───────────────────────────────────────────

  _ConnectionQuality get _quality {
    final last = widget.lastFrameAt;
    if (last == null) return _ConnectionQuality.good; // pre-first-frame
    // Audit H8 (W-13): server-anchored "now" so a device with a skewed
    // wall clock cannot flip a fresh frame to "offline." Paired with
    // `TechnicianLocationStreamNotifier` stamping `frameArrivedAt`
    // through the same anchor — both halves of `now - last` are on
    // the same clock.
    final now = ref.read(systemEventProvider.notifier).serverNow();
    final age = now.difference(last);
    if (age > _kStalenessOfflineThreshold) return _ConnectionQuality.offline;
    if (age > _kStalenessWeakThreshold) return _ConnectionQuality.weak;
    return _ConnectionQuality.good;
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final builder = ref.watch(appMapBuilderProvider);
    final renderedPos = _renderedPosition;

    final markers = <MapMarker>[
      MapMarker(
        id: 'destination',
        position: widget.destination,
        kind: MarkerKind.customer,
      ),
      if (renderedPos != null)
        MapMarker(
          id: 'technician',
          position: renderedPos,
          kind: widget.phase == TrackingPhase.enRoute
              ? MarkerKind.technicianMoving
              : MarkerKind.technicianStopped,
          rotationDegrees: widget.phase == TrackingPhase.enRoute
              ? _renderedHeading
              : 0.0,
        ),
    ];

    final polylines = _directions == null
        ? const <MapPolyline>[]
        : [
            MapPolyline(
              id: 'route',
              points: _directions!.polyline,
              color: const Color(0xFF1565C0), // material blue 800
              strokeWidth: 6.0,
            ),
          ];

    return Stack(
      fit: StackFit.expand,
      children: [
        builder(
          initialCenter: widget.technicianPosition ?? widget.destination,
          initialZoom: 14.0,
          markers: markers,
          polylines: polylines,
          cameraTarget: _cameraTarget,
          cameraZoom: _cameraZoom,
          cameraBounds: _cameraBounds,
          onUserGesture: _onUserGesture,
        ),
        // Connection-quality strip — lives at the top because the
        // bottom is reserved for ETA + FABs.
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              if (widget.technicianPosition == null)
                const _WaitingForFirstFramePill()
              else
                _ConnectionStrip(quality: _quality),
            ],
          ),
        ),
        // ETA pill — only when we have a polyline AND haven't gone
        // offline (offline shows "last known" position; ETA would lie).
        if (_directions != null &&
            renderedPos != null &&
            _quality != _ConnectionQuality.offline)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: _EtaPill(
                etaSeconds: _etaCountdownSeconds,
                distanceMeters: _directions!.distanceMeters,
              ),
            ),
          ),
        // Recentre FAB (bottom-right) — shown only when auto-follow
        // is off AND we have a tech position to recentre to.
        if (!_autoFollow && widget.technicianPosition != null)
          Positioned(
            right: 16,
            bottom: 96,
            child: FloatingActionButton(
              heroTag: 'recentre',
              onPressed: _recentre,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1565C0),
              tooltip: 'Recentre on technician',
              child: const Icon(Icons.my_location),
            ),
          ),
        // Phone-call FAB (bottom-left) — shown when a phone number is
        // surfaced by the parent. Big circle, phone icon, no text —
        // illiterate-user friendly.
        if (widget.callPhoneNumber != null)
          Positioned(
            left: 16,
            bottom: 96,
            child: FloatingActionButton(
              heroTag: 'call',
              onPressed: _onCallPressed,
              backgroundColor: const Color(0xFF1B873F),
              foregroundColor: Colors.white,
              tooltip: widget.callTooltip,
              child: const Icon(Icons.phone),
            ),
          ),
      ],
    );
  }

  Future<void> _onCallPressed() async {
    final raw = widget.callPhoneNumber;
    if (raw == null) return;
    // Audit W-9 (Batch A): use `Uri.parse('tel:$raw')` rather than
    // `Uri(scheme: 'tel', path: raw)`. The named-constructor form
    // percent-encodes `+` to `%2B`, which Samsung / Vivo dialers
    // (common in Pakistan) reject. `Uri.parse` keeps the leading
    // `+` intact, which is the dial-ready form every Android dialer
    // accepts.
    final uri = Uri.parse('tel:$raw');
    final launched = await ref.read(urlLauncherProvider).launch(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open dialler for $raw')),
      );
    }
  }

  // Cheap haversine — used for tween-jump and polyline-refresh
  // thresholds, never for display. dart:math `pi` keeps precision.
  static double _haversineMeters(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;
    final phi1 = a.latitude * math.pi / 180.0;
    final phi2 = b.latitude * math.pi / 180.0;
    final dPhi = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLambda = (b.longitude - a.longitude) * math.pi / 180.0;
    final h =
        math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusMeters * c;
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────

class _EtaPill extends StatelessWidget {
  final int etaSeconds;
  final int distanceMeters;
  const _EtaPill({required this.etaSeconds, required this.distanceMeters});

  @override
  Widget build(BuildContext context) {
    final mins = (etaSeconds / 60).ceil();
    final km = distanceMeters / 1000.0;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_filled_outlined,
              color: Color(0xFFEF6C00),
              size: 28,
            ),
            const SizedBox(width: 10),
            // Big number, small unit — works for users who can read
            // numerals but not English words.
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$mins',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'min',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF9AA0A6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${km.toStringAsFixed(1)} km',
              style: const TextStyle(fontSize: 16, color: Color(0xFF202124)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStrip extends StatelessWidget {
  final _ConnectionQuality quality;
  const _ConnectionStrip({required this.quality});

  @override
  Widget build(BuildContext context) {
    if (quality == _ConnectionQuality.good) {
      return const SizedBox.shrink();
    }
    final isOffline = quality == _ConnectionQuality.offline;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      color: isOffline
          ? const Color(0xFFFFEDDB) // soft orange wash
          : const Color(0xFFFFF8E1), // amber wash
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              isOffline
                  ? Icons.signal_wifi_off_rounded
                  : Icons.network_check_rounded,
              size: 22,
              color: isOffline
                  ? const Color(0xFFD84315)
                  : const Color(0xFFEF6C00),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isOffline
                    ? "Technician's phone seems to be offline. "
                          'Last position is shown.'
                    : 'Connection is weak…',
                style: TextStyle(
                  fontSize: 14,
                  color: isOffline
                      ? const Color(0xFFBF360C)
                      : const Color(0xFFE65100),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingForFirstFramePill extends StatelessWidget {
  const _WaitingForFirstFramePill();

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1565C0),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Waiting for technician's location…",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0D47A1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// P-PAN audit (Tier 1): snapshot of the rendered technician marker.
/// Drives a `ValueNotifier` so the 3.5s × 60Hz tween repaints ONLY
/// the inner `IAppMap` subtree (wrapped in `ValueListenableBuilder`
/// inside `build`) — not the surrounding Stack (connection strip,
/// ETA pill, recentre FAB, call FAB). Pre-fix `_onTweenTick` called
/// `setState` on the whole `LiveTrackingMap` 60 times per second,
/// which starved gesture recognition on the platform-view thread
/// and made the map feel slow to pan during active motion.
///
/// Value-equal (latlong2.LatLng compares lat+lng; heading is a
/// double). `ValueNotifier` short-circuits on `==` so writing the
/// same content twice does NOT fire listeners.
@immutable
class _MarkerFrame {
  final LatLng position;
  final double heading;
  const _MarkerFrame({required this.position, required this.heading});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MarkerFrame &&
          other.position == position &&
          other.heading == heading;

  @override
  int get hashCode => Object.hash(position, heading);
}

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

  /// P2: GPS accuracy in metres, fed straight from
  /// `TechGpsFrame.accuracyMeters`. When non-null + positive + finite,
  /// the widget draws a translucent blue ring around the technician
  /// marker whose radius IS the accuracy in metres (so it scales with
  /// zoom — at street level a 15m accuracy reads as a meaningful
  /// circle; at a wide zoom it shrinks to a dot). Null / non-positive
  /// / non-finite values hide the ring entirely.
  final double? accuracyMeters;

  const LiveTrackingMap({
    super.key,
    required this.technicianPosition,
    required this.destination,
    required this.phase,
    this.technicianHeadingDegrees,
    this.lastFrameAt,
    this.callPhoneNumber,
    this.callTooltip = 'Call',
    this.accuracyMeters,
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
  // P1.2: 3500ms (was 4800ms). With the 5s broadcaster cadence (P1.1)
  // and backend's 4s throttle, frames arrive every ~5s. 3500ms settles
  // ~1500ms before the next frame so:
  //   - tween-vs-frame collisions don't happen under normal jitter
  //   - the marker "lands" before the customer's eye stops tracking
  //     it, which reads as "the tech is actually moving" rather than
  //     "the tech is always sliding"
  // The previous 4800ms was calibrated for the 5s heartbeat we
  // *thought* we had with the 15s cadence — the audit caught the
  // mismatch in the same pass that tightened the broadcaster.
  static const Duration _kFrameTweenDuration = Duration(milliseconds: 3500);
  // Beyond this distance between frames we hard-set instead of
  // tweening — protects against GPS glitches that animate the marker
  // through the wrong streets mid-route.
  static const double _kHardJumpDistanceMeters = 200.0;
  // P2: dynamic bounds-follow tunables.
  //   - `_kBoundsRefitDistanceMeters`: how far the tech must move
  //     since the last bounds-fit anchor before we re-fit. Prevents
  //     per-frame refit jitter (the 5s GPS cadence + 60Hz marker
  //     tween rebuilds would otherwise produce micro-pan camera
  //     animations on every tick).
  //   - `_kCloseApproachZoom`: street-level zoom used in ARRIVED
  //     phase, where the tech IS the destination and bounds-fit
  //     would degenerate to a single point.
  static const double _kBoundsRefitDistanceMeters = 150.0;
  static const double _kCloseApproachZoom = 17.0;

  // ─── Marker tween ──────────────────────────────────────────────────
  late final AnimationController _markerAnim;
  LatLng? _renderedPosition; // currently-displayed marker position
  LatLng? _tweenFromPosition;
  LatLng? _tweenToPosition;
  double _renderedHeading = 0.0;
  // Audit W-12 (Batch B): shortest-arc heading lerp. Pre-fix the
  // marker hard-set heading on every frame which produced a visible
  // snap mid-position-tween (359° → 1° looked like a 358° backward
  // spin). When set, `_onTweenTick` lerps the heading along the
  // shortest arc using the same animation progress as the position
  // tween. Cleared (set to null) on hard-set paths (first frame,
  // hard jump > 200m, no-heading frames).
  double? _tweenFromHeading;
  double? _tweenToHeading;

  // P-PAN audit (Tier 1): marker render snapshot. See [_MarkerFrame]
  // docstring for the rationale. Seeded in initState from the first
  // widget value (when non-null) and updated by:
  //   - `_onTweenTick` (every tween frame),
  //   - first-frame branch in `didUpdateWidget`,
  //   - hard-jump (>200m) branch in `didUpdateWidget`,
  //   - ARRIVED-phase stop branch in `didUpdateWidget`.
  // `_renderedPosition` / `_renderedHeading` stay authoritative —
  // `didUpdateWidget` anchors the next tween off `_renderedPosition`.
  // The notifier mirrors them; it does NOT replace them.
  final ValueNotifier<_MarkerFrame?> _markerFrameNotifier =
      ValueNotifier<_MarkerFrame?>(null);

  // ─── Polyline fetch state ──────────────────────────────────────────
  DirectionsResult? _directions;
  LatLng? _polylineAnchor; // tech position when last fetch fired
  bool _fetching = false; // re-entry guard, set BEFORE await

  // P3 audit fix (Tier 3): memoize the polylines list. `_directions`
  // changes every ≥30s (per the cooldown). Pre-fix every build (60Hz
  // during the marker tween) constructed a fresh `MapPolyline` list,
  // which the underlying map adapter then diffed and converted to a
  // fresh provider-specific polyline Set. Caching keyed on
  // `identical(_cachedPolylinesSource, _directions)` means the build
  // hot path returns the same list reference on every tween tick,
  // and the adapter's `identical(old, new)` short-circuit skips the
  // diff entirely.
  List<MapPolyline> _cachedPolylines = const [];
  DirectionsResult? _cachedPolylinesSource;

  // ─── ETA tickdown ──────────────────────────────────────────────────
  // P3 audit fix (Tier 3): tickdown via ValueNotifier so the 1Hz tick
  // only rebuilds the `_EtaPill` (wrapped in ValueListenableBuilder)
  // — not the entire LiveTrackingMap. Pre-fix, every second's
  // `setState(() => _etaCountdownSeconds = next)` rebuilt the whole
  // widget which cascaded into a fresh underlying map widget every
  // second, redundantly diffing markers/polylines/circles.
  final ValueNotifier<int> _etaCountdownNotifier = ValueNotifier<int>(0);
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
  // P2: tech position at the last bounds-fit. The next frame only
  // triggers a re-fit when the tech has moved past
  // `_kBoundsRefitDistanceMeters` from this anchor.
  LatLng? _lastBoundsAnchor;
  // P2: applied-once on entry to ARRIVED phase so subsequent rebuilds
  // pass null zoom and preserve user pinch. Reset whenever we leave
  // ARRIVED (e.g. via destination change, or back into EN_ROUTE).
  bool _closeApproachZoomApplied = false;
  // Declarative camera state. The underlying adapter diffs old vs new
  // and only animates when these values change — passing the same
  // reference across rebuilds is a no-op.
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
      final next = _quality(_serverNow());
      if (next != _lastQuality) {
        setState(() => _lastQuality = next);
      }
    });
    _lastQuality = _quality(_serverNow());
    // Seed marker rendering from initial widget state.
    _renderedPosition = widget.technicianPosition;
    _renderedHeading = widget.technicianHeadingDegrees ?? 0.0;
    if (widget.technicianPosition != null) {
      _markerFrameNotifier.value = _MarkerFrame(
        position: widget.technicianPosition!,
        heading: _renderedHeading,
      );
      _updateCameraForFrame();
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
      // P2: destination moved → next bounds-fit must include the new
      // endpoint. Reset the anchor so `_updateCameraForFrame` refits
      // unconditionally on the next call.
      _lastBoundsAnchor = null;
      _maybeFetchDirections();
      // P2 audit bug 2: fire the refit immediately. Pre-fix the
      // camera stayed anchored on the OLD destination until the next
      // GPS frame (~5s) because `_cameraBounds` held the previous
      // LatLng by value. With `_lastBoundsAnchor = null` above, this
      // call refits without throttle and pulls `widget.destination`
      // (the new value) into the bounds list.
      _updateCameraForFrame();
    }

    // Audit H9 (W-3): the ETA tickdown timer was never cancelled when
    // the booking transitioned EN_ROUTE → ARRIVED. Cancel here so the
    // 1Hz rebuild storm stops the moment the tech arrives.
    if (oldWidget.phase != widget.phase &&
        widget.phase == TrackingPhase.arrived) {
      _etaTicker?.cancel();
      _etaTicker = null;
      _etaCountdownNotifier.value = 0;
      // LTM-17 (Batch I): stop the in-flight marker tween — without
      // this the marker keeps sliding for up to ~4.8s while the
      // "arrived" badge already shows.
      if (_markerAnim.isAnimating) {
        _markerAnim.stop();
        final to = _tweenToPosition;
        if (to != null) {
          _renderedPosition = to;
          // P-PAN audit (Tier 1): push the final tween target so the
          // marker lands at `to` immediately. With the notifier-driven
          // marker subtree, an in-flight `_onTweenTick` would otherwise
          // leave the marker at the last lerped value until the next
          // outer rebuild.
          _markerFrameNotifier.value = _MarkerFrame(
            position: to,
            heading: _renderedHeading,
          );
        }
        _tweenFromPosition = null;
        _tweenToPosition = null;
        _tweenFromHeading = null;
        _tweenToHeading = null;
      }
      // P2: phase flip to ARRIVED switches the camera from bounds-fit
      // to close-approach follow. Reset the anchor (no more bounds-fit
      // needed) and re-arm the one-shot zoom so the next
      // `_updateCameraForFrame` applies the close-approach zoom once.
      _lastBoundsAnchor = null;
      _closeApproachZoomApplied = false;
      // P2 audit bug 1: fire the camera transition immediately. Pre-fix
      // the customer's screen stayed on the wide bounds-fit view for
      // up to 5s after "Technician has arrived" before the next GPS
      // frame triggered the close-approach zoom. With the flags reset
      // above, this call lands cleanly on the ARRIVED branch.
      _updateCameraForFrame();
    }

    if (newPos != null && oldPos == null) {
      // First frame — hard-set, no tween.
      _renderedPosition = newPos;
      _renderedHeading = widget.technicianHeadingDegrees ?? 0.0;
      _tweenFromHeading = null; // audit W-12: clear any tween state
      _tweenToHeading = null;
      // P-PAN audit (Tier 1): push through the notifier so the inner
      // IAppMap subtree rebuilds with the new marker. Pre-fix this
      // path ended with an empty `setState(() {})` which rebuilt the
      // whole `LiveTrackingMap` — Flutter already schedules a rebuild
      // when widget props change, so that setState was redundant; the
      // notifier write is the real signal for the marker layer.
      _markerFrameNotifier.value = _MarkerFrame(
        position: newPos,
        heading: _renderedHeading,
      );
      _updateCameraForFrame();
      _maybeFetchDirections();
      return;
    }

    if (newPos != null && oldPos != null && newPos != oldPos) {
      final jump = _haversineMeters(oldPos, newPos);
      if (jump > _kHardJumpDistanceMeters) {
        // Too far — likely a GPS glitch; hard-set rather than animate
        // the marker through unrelated streets.
        _renderedPosition = newPos;
        _renderedHeading = widget.technicianHeadingDegrees ?? _renderedHeading;
        _tweenFromHeading = null;
        _tweenToHeading = null;
        // P-PAN audit (Tier 1): write through the notifier so the
        // marker subtree rebuilds at the new position. Flutter's
        // didUpdateWidget-driven outer rebuild also runs (since
        // widget props changed), but the notifier write is what
        // moves the actual marker without waiting for outer state
        // diffs to resolve.
        _markerFrameNotifier.value = _MarkerFrame(
          position: newPos,
          heading: _renderedHeading,
        );
      } else {
        // P1.2: when a frame arrives mid-tween, anchor the new tween's
        // FROM on the marker's currently-rendered position rather than
        // the widget's prior accepted frame (`oldPos`). Pre-fix the
        // marker visibly jumped forward from the lerp midpoint to
        // `oldPos` before tweening to `newPos`; using `_renderedPosition`
        // keeps the visual continuous from where the customer's eye
        // sees the marker. Falls back to `oldPos` defensively — in
        // this branch both fields are non-null (the first-frame path
        // is handled above).
        _tweenFromPosition = _renderedPosition ?? oldPos;
        _tweenToPosition = newPos;
        _markerAnim
          ..stop()
          ..value = 0.0
          ..forward();
        // Audit W-12 (Batch B): set up shortest-arc heading lerp
        // alongside the position tween. If the new frame has no
        // heading (compass dead), preserve the previous rendered
        // value AND clear the tween — null `_tweenToHeading` means
        // `_onTweenTick` skips the heading lerp branch. The position
        // still tweens.
        final newHeading = widget.technicianHeadingDegrees;
        if (newHeading != null) {
          _tweenFromHeading = _renderedHeading;
          _tweenToHeading = newHeading;
        } else {
          _tweenFromHeading = null;
          _tweenToHeading = null;
        }
      }
      _maybeFetchDirections();
      _updateCameraForFrame();
    }
  }

  /// Audit W-12: lerp `from` toward `to` along the shortest arc on
  /// the [0, 360) circle. Forwards to the top-level
  /// [shortestArcLerpDegrees] which is `@visibleForTesting`.
  static double _shortestArcLerp(double from, double to, double t) =>
      shortestArcLerpDegrees(from, to, t);

  void _onTweenTick() {
    final from = _tweenFromPosition;
    final to = _tweenToPosition;
    if (from == null || to == null) return;
    final t = _markerAnim.value;
    final lat = from.latitude + (to.latitude - from.latitude) * t;
    final lng = from.longitude + (to.longitude - from.longitude) * t;
    // Audit W-12: lerp heading along the shortest arc when both
    // endpoints are set. Skip if `_tweenToHeading` is null (frame
    // had no compass reading).
    final fromHeading = _tweenFromHeading;
    final toHeading = _tweenToHeading;
    final nextHeading = (fromHeading != null && toHeading != null)
        ? _shortestArcLerp(fromHeading, toHeading, t)
        : _renderedHeading;
    // P-PAN audit (Tier 1): write through `_markerFrameNotifier`
    // instead of `setState`. Only the inner `IAppMap` subtree
    // (wrapped in `ValueListenableBuilder` inside `build`) rebuilds
    // per tick — the surrounding Stack (strip / pill / FABs) stays
    // put, so the platform-view's gesture thread isn't preempted by
    // a full `LiveTrackingMap` repaint 60 times per second.
    //
    // On the final tick we land *exactly* on the tween target rather
    // than the lerp result — at t=1.0 the arithmetic is mathematically
    // identical, but using `to` directly avoids any cumulative
    // floating-point drift on the very last frame.
    final LatLng nextPos;
    if (_markerAnim.value >= 1.0) {
      nextPos = to;
      _renderedHeading = toHeading ?? nextHeading;
    } else {
      nextPos = LatLng(lat, lng);
      _renderedHeading = nextHeading;
    }
    _renderedPosition = nextPos;
    _markerFrameNotifier.value = _MarkerFrame(
      position: nextPos,
      heading: _renderedHeading,
    );
  }

  @override
  void dispose() {
    _markerAnim.dispose();
    _etaTicker?.cancel();
    _stalenessTicker?.cancel();
    // P3 audit fix (Tier 3): dispose the ValueNotifier so listeners
    // are flushed and the GC reclaims the listener list. Critical to
    // avoid: a pending `_etaCountdownNotifier.value = ...` write
    // posted in the timer callback after dispose would crash. The
    // `if (!mounted) return` at the top of the timer body already
    // guards this, but disposing is good citizenship.
    _etaCountdownNotifier.dispose();
    // P-PAN audit (Tier 1): dispose the marker-frame notifier for
    // the same reason — flushes listeners and prevents post-dispose
    // writes from `_onTweenTick` (the AnimationController disposes
    // above, but its listener queue may have a pending tick in
    // flight).
    _markerFrameNotifier.dispose();
    super.dispose();
  }

  // ─── Camera follow (P2: dynamic bounds-follow) ─────────────────────
  //
  // The previous design ran two methods:
  //   - `_scheduleInitialFit`: one-shot bounds-fit on first frame
  //     followed by a 3s grace, then
  //   - `_maybeFollowCamera`: snap to `_kFollowZoom = 16` centred on
  //     the tech, never looking at the destination again.
  //
  // The user-facing effect: the bounds-fit (wide "tech + dest" view)
  // was visible for ~3s, then the camera abruptly jumped to a fixed
  // zoom that often hid the destination off-screen for the rest of
  // the route. Foodpanda keeps both endpoints visible while the
  // courier is approaching, only tightening to street-level when
  // they get close.
  //
  // `_updateCameraForFrame` replaces both methods with one decision
  // tree:
  //   - ARRIVED: bounds would degenerate (tech IS dest), so follow
  //     the tech at `_kCloseApproachZoom` (one-shot — subsequent
  //     ticks pass null zoom so user pinch is preserved).
  //   - EN_ROUTE: fit bounds [tech, destination] so both stay in
  //     frame as the tech approaches. Refit only when the tech has
  //     moved > `_kBoundsRefitDistanceMeters` from the last anchor
  //     so we don't fire camera animations on every 5s GPS frame.
  //
  // Declarative state contract: `_cameraTarget` / `_cameraZoom` /
  // `_cameraBounds` persist on this State until the next legitimate
  // change. The underlying adapter diffs (identical short-circuit
  // first, then component-equal) so passing the same reference
  // across rebuilds is a free no-op.

  void _updateCameraForFrame() {
    if (!_autoFollow) return;
    final tech = widget.technicianPosition;
    if (tech == null) return;

    if (widget.phase == TrackingPhase.arrived) {
      // Tech is AT destination — bounds would be a single point.
      // Centre on tech with close-approach zoom. One-shot zoom so
      // user pinch is preserved on subsequent ticks.
      setState(() {
        _cameraTarget = tech;
        _cameraBounds = null;
        if (!_closeApproachZoomApplied) {
          _cameraZoom = _kCloseApproachZoom;
          _closeApproachZoomApplied = true;
        } else {
          _cameraZoom = null;
        }
      });
      return;
    }

    // EN_ROUTE — keep tech + destination in frame. Refit-throttle so
    // we don't fire a camera animation every 5s GPS frame.
    final anchor = _lastBoundsAnchor;
    final shouldRefit = anchor == null ||
        _haversineMeters(anchor, tech) > _kBoundsRefitDistanceMeters;
    if (!shouldRefit) return;
    setState(() {
      _cameraBounds = [tech, widget.destination];
      _cameraTarget = null;
      _cameraZoom = null;
      _lastBoundsAnchor = tech;
      // Re-arm the one-shot zoom so if we re-enter ARRIVED later it
      // applies fresh (rare — but a phase flip back to EN_ROUTE then
      // forward to ARRIVED would otherwise skip the zoom).
      _closeApproachZoomApplied = false;
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
    // P2: recentre re-engages auto-follow and resets the bounds
    // anchor + zoom-applied flag so the next `_updateCameraForFrame`
    // produces a fresh fit (EN_ROUTE) or a fresh close-approach
    // follow (ARRIVED). Pre-P2 we manually set target+zoom here; the
    // unified `_updateCameraForFrame` is now the only path that
    // mutates camera state.
    _autoFollow = true;
    _lastBoundsAnchor = null;
    _closeApproachZoomApplied = false;
    _updateCameraForFrame();
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
      // P3 audit fix: only the polyline + distance assignments need
      // a rebuild (the build() reads `_directions!.distanceMeters`
      // directly). The countdown is fed to `_etaCountdownNotifier`
      // which drives a ValueListenableBuilder around the pill —
      // 1Hz updates no longer reach LiveTrackingMap.setState.
      setState(() {
        _directions = result;
        _polylineAnchor = tech;
      });
      _etaCountdownNotifier.value = result.etaSeconds;
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
        final next = _etaCountdownNotifier.value - 1;
        if (next <= 0) {
          _etaTicker?.cancel();
          _etaTicker = null;
          return;
        }
        // P3 audit fix: write through the notifier — only the
        // ValueListenableBuilder around `_EtaPill` rebuilds, the
        // surrounding map tree does not.
        _etaCountdownNotifier.value = next;
      });
    } on DirectionsFailure {
      // Soft-fail. Keep last polyline / ETA. Don't snackbar — routing
      // is best-effort polish, not load-bearing UX.
    } finally {
      // LTM-5 (Batch I): _fetching is a re-entry guard, not a UI
      // input — don't trigger a frame rebuild just to flip it. The
      // success / failure branches above already setState when the
      // result needs to render.
      _fetching = false;
    }
  }

  // ─── Connection quality ───────────────────────────────────────────

  /// LTM-2 (Batch I): compute the band given an externally-supplied
  /// server-anchored `now` so each `build()` reads `serverNow()` once
  /// instead of per-Stack-child. Combined with the 60Hz tween-driven
  /// rebuilds, the prior `_quality` getter was re-reading the anchor
  /// dozens of times per second and could flip the band across two
  /// consecutive milliseconds in the same second.
  ///
  /// Audit H8 (W-13): the anchor is server-time, not local wall
  /// clock, so a device with skew cannot mis-classify a fresh frame
  /// as offline. Paired with `TechnicianLocationStreamNotifier`
  /// stamping `frameArrivedAt` through the same anchor — both halves
  /// of `now - last` are on the same clock.
  _ConnectionQuality _quality(DateTime now) {
    final last = widget.lastFrameAt;
    if (last == null) return _ConnectionQuality.good; // pre-first-frame
    final age = now.difference(last);
    if (age > _kStalenessOfflineThreshold) return _ConnectionQuality.offline;
    if (age > _kStalenessWeakThreshold) return _ConnectionQuality.weak;
    return _ConnectionQuality.good;
  }

  DateTime _serverNow() =>
      ref.read(systemEventProvider.notifier).serverNow();

  /// P3 audit fix (Tier 3): memoized polylines list. Pre-fix every
  /// build constructed a fresh `[MapPolyline(...)]`, which the
  /// underlying adapter then converted to a fresh provider-specific
  /// polyline Set with new `gmaps.Polyline` / `Polyline` instances.
  /// The plugin's internal diff handled equal content efficiently,
  /// but the Dart-side allocation churn was non-zero at 60Hz during
  /// the marker tween.
  ///
  /// Cache invalidates only when `_directions` is REASSIGNED (a new
  /// DirectionsResult lands every ≥30s per the cooldown). Between
  /// fetches every call returns the SAME list reference, so the
  /// adapter's `identical(old, new)` short-circuit returns true and
  /// the diff is skipped entirely.
  List<MapPolyline> _polylinesFor() {
    if (identical(_cachedPolylinesSource, _directions)) {
      return _cachedPolylines;
    }
    _cachedPolylinesSource = _directions;
    final dirs = _directions;
    _cachedPolylines = dirs == null
        ? const <MapPolyline>[]
        : <MapPolyline>[
            MapPolyline(
              id: 'route',
              points: dirs.polyline,
              color: const Color(0xFF1565C0), // material blue 800
              strokeWidth: 6.0,
            ),
          ];
    return _cachedPolylines;
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final builder = ref.watch(appMapBuilderProvider);
    // LTM-2 (Batch I): compute the connection-quality band ONCE per
    // build, not per Stack child. The prior `_quality` getter was
    // called from each Positioned that gated on it, and each call
    // re-read `serverNow()` — at 60Hz tween rebuilds the anchor was
    // sampled hundreds of times per second.
    final quality = _quality(_serverNow());

    // P3 audit fix (Tier 3): memoized polylines list. See `_polylinesFor`
    // docstring for the rebuild-minimization rationale. Polylines do
    // NOT depend on the tween-lerped marker position, so they live at
    // the outer build scope; the ValueListenableBuilder below captures
    // them.
    final polylines = _polylinesFor();

    // P-PAN audit (Tier 1, Stage 2): the inner `IAppMap` subtree (and
    // its tech-marker + accuracy-circle inputs, which both depend on
    // the tween-lerped position) lives inside a
    // `ValueListenableBuilder<_MarkerFrame?>` that listens to
    // `_markerFrameNotifier`. The 3.5s × 60Hz marker tween then only
    // rebuilds this single subtree — not the surrounding Stack
    // (connection strip / ETA pill / FABs / recentre FAB). Pre-fix
    // the whole `LiveTrackingMap` repainted 60Hz during motion, which
    // starved the platform-view's gesture recognizer and made the
    // map feel slow to pan and explore.
    //
    // The outer Stack rebuilds only on legitimate state changes:
    //   - auto-follow toggle (`_onUserGesture` / `_recentre`),
    //   - polyline fetch result (setState in `_maybeFetchDirections`),
    //   - staleness-band transition (setState in `_stalenessTicker`),
    //   - camera anchor update (setState in `_updateCameraForFrame`),
    //   - widget prop changes (parent didUpdateWidget).
    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<_MarkerFrame?>(
          valueListenable: _markerFrameNotifier,
          builder: (context, frame, _) {
            // Destination marker is constant for the booking's
            // lifetime; the technician marker comes from the
            // tween-driven frame. `frame == null` pre-first-frame →
            // only the destination renders.
            final markers = <MapMarker>[
              MapMarker(
                id: 'destination',
                position: widget.destination,
                kind: MarkerKind.customer,
              ),
              if (frame != null)
                MapMarker(
                  id: 'technician',
                  position: frame.position,
                  kind: widget.phase == TrackingPhase.enRoute
                      ? MarkerKind.technicianMoving
                      : MarkerKind.technicianStopped,
                  rotationDegrees: widget.phase == TrackingPhase.enRoute
                      ? frame.heading
                      : 0.0,
                ),
            ];

            // P2: GPS accuracy ring. Anchored on `frame.position`
            // (the tween-lerped marker location) so the ring tracks
            // the marker smoothly rather than jumping with each
            // accepted frame. Filter on positive + finite —
            // geolocator emits `0.0` for "unknown" and the broadcaster
            // passes null through, but we defend against wire-shape
            // drift (negative / NaN / infinity) at the render boundary.
            final accuracy = widget.accuracyMeters;
            final circles = (frame != null &&
                    accuracy != null &&
                    accuracy > 0 &&
                    accuracy.isFinite)
                ? <MapCircle>[
                    MapCircle(
                      id: 'accuracy',
                      center: frame.position,
                      radiusMeters: accuracy,
                    ),
                  ]
                : const <MapCircle>[];

            return builder(
              initialCenter: widget.technicianPosition ?? widget.destination,
              initialZoom: 14.0,
              markers: markers,
              polylines: polylines,
              circles: circles,
              cameraTarget: _cameraTarget,
              cameraZoom: _cameraZoom,
              cameraBounds: _cameraBounds,
              onUserGesture: _onUserGesture,
            );
          },
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
                _ConnectionStrip(quality: quality),
            ],
          ),
        ),
        // ETA pill — only when we have a polyline AND haven't gone
        // offline (offline shows "last known" position; ETA would lie).
        // P3 audit fix (Tier 3): wrap the pill in a
        // `ValueListenableBuilder<int>` watching the tickdown notifier
        // so the 1Hz countdown rebuilds ONLY the pill, not the entire
        // LiveTrackingMap (and through it the underlying map widget).
        // `distanceMeters` comes from `_directions` and only changes
        // when a new DirectionsResult lands — captured outside the
        // builder closure so the pill receives a stable value between
        // fetches.
        if (_directions != null &&
            _renderedPosition != null &&
            quality != _ConnectionQuality.offline)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: _etaCountdownNotifier,
                builder: (context, seconds, _) => _EtaPill(
                  etaSeconds: seconds,
                  distanceMeters: _directions!.distanceMeters,
                ),
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
    // LTM-9 (Batch I): floor the displayed minutes at 1. Without
    // this, an `etaSeconds: 0` first response (server thinks the
    // tech is already at destination) renders as "0 min" — looks
    // broken next to a non-zero distance. The 1Hz ticker already
    // cancels at `next <= 0`; this guards the very-first response
    // shape too.
    final mins = math.max(1, (etaSeconds / 60).ceil());
    final distanceText = formatDistanceMeters(distanceMeters);
    // Audit W-38 (Batch G): pre-fix TalkBack read each text node
    // independently ("5", "min", "·", "300 m"). The merged Semantics
    // label collapses them into one announcement and makes the pill
    // a single focusable element. `excludeSemantics: true` suppresses
    // the children's individual labels so we don't get a double-read.
    final minuteWord = mins == 1 ? 'minute' : 'minutes';
    final semanticsLabel =
        'Estimated arrival in $mins $minuteWord, $distanceText away';
    return Semantics(
      label: semanticsLabel,
      container: true,
      excludeSemantics: true,
      child: Material(
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
                distanceText,
                style: const TextStyle(fontSize: 16, color: Color(0xFF202124)),
              ),
            ],
          ),
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
    // Audit W-38 (Batch G): wrap with `Semantics(liveRegion: true)`
    // so TalkBack announces band transitions (good → weak → offline)
    // as soon as they appear. Without `liveRegion`, TalkBack stays
    // silent until the user navigates focus to the strip — defeats
    // the purpose of the surface as a live status indicator for
    // visually-impaired users on a stationary phone.
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
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
                    // Audit W-27 (Batch D): the previous weak-state text
                    // colour 0xFFE65100 against the 0xFFFFF8E1 wash gave
                    // ~4.6:1 contrast — borderline AA, fails AAA. Darkened
                    // to 0xFFAB3F00 for ~6.7:1 (clears AAA for normal
                    // text) while staying visually distinct from the
                    // offline state's deeper-red 0xFFBF360C.
                    color: isOffline
                        ? const Color(0xFFBF360C)
                        : const Color(0xFFAB3F00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingForFirstFramePill extends StatelessWidget {
  const _WaitingForFirstFramePill();

  @override
  Widget build(BuildContext context) {
    // Audit W-38 (Batch G): liveRegion announces the appearance to
    // TalkBack so a customer on the orchestrator screen knows the
    // app is waiting (vs sitting silently with a blank map).
    return Semantics(
      liveRegion: true,
      container: true,
      label: "Waiting for technician's location",
      excludeSemantics: true,
      child: Material(
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
      ),
    );
  }
}

/// Audit W-12 (Batch B): top-level helper for shortest-arc heading
/// interpolation. Lerp `from` toward `to` along the shortest arc on
/// the `[0, 360)` circle. Normalizes the delta to `[-180, 180]` so a
/// 359° → 1° transition takes the +2° path, not the -358° path.
///
/// Marked `@visibleForTesting` so a unit test can verify the math
/// without spinning up an `AnimationController` and pumping it to a
/// partial value.
/// Audit W-25 (Batch D): distance formatter for the ETA pill. < 1 km
/// renders as metres rounded to the nearest 10 ("300 m" — the concrete
/// walking-distance signal); ≥ 1 km renders as one-decimal kilometres
/// ("1.2 km"). Rounded-to-10 cuts jitter on a slow tech (300 m → 290 m
/// → 280 m feels precise) without losing meaningful precision.
///
/// Marked `@visibleForTesting` so a unit test can pin the formatter
/// without driving a `LiveTrackingMap` widget.
@visibleForTesting
String formatDistanceMeters(int distanceMeters) {
  // LTM-13 (Batch I): round-then-branch. Pre-fix, 999 m rounded to
  // 1000 m (a 4-digit metres reading right at the km boundary), and
  // 1000 m correctly formatted as "1.0 km" — visually inconsistent
  // either side of the cutover. Round first, then choose the unit
  // so values that round up to 1000 m flip to "1.0 km" cleanly.
  final rounded = (distanceMeters / 10).round() * 10;
  if (rounded < 1000) return '$rounded m';
  return '${(rounded / 1000.0).toStringAsFixed(1)} km';
}

@visibleForTesting
double shortestArcLerpDegrees(double from, double to, double t) {
  var delta = ((to - from + 540) % 360) - 180;
  // Antipodal edge case: an exactly-180° turn lands on `delta = -180`
  // by the normalization, which would rotate counterclockwise. Prefer
  // the forward (+180) direction for a more natural visual.
  if (delta == -180) delta = 180;
  final next = (from + delta * t) % 360;
  return next < 0 ? next + 360 : next;
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import '../../../../../core/realtime/presentation/state/connection_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../utils/urgency_palette.dart';

/// Slide-to-accept pill that absorbs the SLA countdown into the action surface
/// itself. Replaces the prior "tap accept + separate countdown ring" pair.
///
/// **Why a swipe.** The technician's accept is a real commitment (driving to
/// a location, taking on the work). A tap is too cheap to express that — and
/// in field testing, taps fired by accident from a phone in a tool belt
/// pocket. The horizontal-swipe affordance maps to the iPhone-call-answer
/// metaphor that even low-literacy users in this market reliably understand
/// from years of mobile-phone use, and it requires deliberate physical
/// motion that pockets don't reproduce. Decline stays a tap (asymmetric:
/// accept = commitment = swipe; decline = reversible = tap).
///
/// **Why a drain.** A separate countdown ring competes with content for the
/// eye. Encoding time pressure into the swipe track itself solves that with
/// no second visual: the colored fill recedes from the right edge as the
/// SLA elapses. When the fill gets short enough that the swipe runway can
/// no longer accept, the offer auto-expires. The fill color shifts
/// green → amber → red across the same band thresholds the rest of the
/// urgency palette uses, so "is this urgent?" answers itself.
///
/// **Layout.**
///   * Pill: full width × 72dp.
///   * Fill: clipped child of the pill, anchored left, width =
///     `(remaining / slaWindow) * trackInteriorWidth`.
///   * Caption: centered "Slide to accept · Rs. {payout}".
///   * Thumb: 60dp circle, positioned via [Positioned] inside the pill.
///     Drags horizontally. When released past the threshold, fires onAccept;
///     released before the threshold, snaps back.
///
/// **Threshold.** 80% of the swipe-able runway. Below the threshold the
/// thumb springs back; at-or-above, [onAccept] fires once and the thumb
/// animates to the right edge. The threshold lives at 80%, not 100%, so a
/// confident swipe doesn't have to nudge into the very last pixel — that
/// would be a finicky target on a budget Android device.
///
/// **Time.** A 250ms periodic ticker recomputes remaining time from
/// `DateTime.now()` (wall-clock — survives backgrounding correctly). Frame
/// count would drift if the app is backgrounded mid-drain. The ticker
/// stops when [onExpire] fires or when the widget unmounts.
///
/// **Connectivity gate (flag #19 family).** The widget watches
/// `wsConnectionProvider`. When the socket is anything other than
/// `connected`, the gesture handlers early-out and the caption switches to
/// `"Reconnecting…"`. Without this gate, a technician on the metro could
/// physically swipe accept while offline and the host's accept REST call
/// (`POST /api/bookings/<id>/accept/`) would fail with a network error —
/// the user would see a Retry snackbar but the underlying booking might
/// have SLA-expired by then. Worse on a sustained outage: the SLA Celery
/// task would expire the booking server-side, the customer would
/// re-dispatch to a different technician, and the offline technician would
/// arrive at the address to find the job already taken. Disabling at the
/// gesture level keeps the offer visible (technician can still see the
/// payout / location / countdown) but physically prevents the destructive
/// action until connectivity returns.
class IncomingJobSwipeToAccept extends ConsumerStatefulWidget {
  const IncomingJobSwipeToAccept({
    super.key,
    required this.expiresAt,
    required this.slaWindow,
    required this.payoutRupees,
    required this.onAccept,
    required this.onExpire,
  });

  /// Wall-clock instant the offer expires. Drives the drain.
  final DateTime expiresAt;

  /// Original SLA span. Denominator for the urgency-band fraction.
  final Duration slaWindow;

  /// Payout shown in the caption.
  final int payoutRupees;

  /// Fired exactly once when the user releases past the swipe threshold.
  /// Pre-conditions: not yet accepted, not yet expired, socket connected.
  final VoidCallback onAccept;

  /// Fired exactly once when the drain reaches zero. Pre-conditions: not
  /// yet accepted.
  final VoidCallback onExpire;

  @override
  ConsumerState<IncomingJobSwipeToAccept> createState() =>
      _IncomingJobSwipeToAcceptState();
}

class _IncomingJobSwipeToAcceptState
    extends ConsumerState<IncomingJobSwipeToAccept>
    with TickerProviderStateMixin {
  // ── Geometry ────────────────────────────────────────────────────────────
  static const double _pillHeight = 72;
  static const double _thumbDiameter = 60;
  static const double _trackPadding = 6;

  /// The fraction of the swipe-able runway at which a release fires
  /// onAccept. Below this, the thumb snaps back.
  static const double _acceptThreshold = 0.8;

  // ── State ───────────────────────────────────────────────────────────────
  Timer? _ticker;
  late final AnimationController _idleHint;
  late final AnimationController _snapBack;
  late final AnimationController _confirm;

  /// Position of the thumb's left edge relative to the inner-padded track.
  /// Range: 0 .. (fillWidth - thumbDiameter).
  double _thumbOffset = 0;

  /// Captured pointer x at pan start, in local pill coordinates.
  double? _dragStartX;

  /// _thumbOffset captured at pan start.
  double? _dragStartThumbOffset;

  /// True once onAccept has fired. The widget freezes (drain stops, thumb
  /// pinned right) until rebuilt with a new request.
  bool _accepted = false;

  /// True once onExpire has fired. The widget freezes red.
  bool _expired = false;

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _idleHint = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _confirm = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (_accepted || _expired) return;
      final remaining = _remaining();
      if (remaining <= Duration.zero) {
        _expired = true;
        _ticker?.cancel();
        widget.onExpire();
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant IncomingJobSwipeToAccept oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new offer arrived in the same widget slot — reset the swipe state so
    // the thumb starts at the left edge again. The host rebuilds with a
    // fresh request when the head changes.
    if (oldWidget.expiresAt != widget.expiresAt) {
      _accepted = false;
      _expired = false;
      _thumbOffset = 0;
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted) return;
        if (_accepted || _expired) return;
        final remaining = _remaining();
        if (remaining <= Duration.zero) {
          _expired = true;
          _ticker?.cancel();
          widget.onExpire();
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _idleHint.dispose();
    _snapBack.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // ── Derived values ──────────────────────────────────────────────────────

  Duration _remaining() {
    final r = widget.expiresAt.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  double _drainFraction() {
    final span = widget.slaWindow.inMilliseconds;
    if (span <= 0) return 0.0;
    final r = _remaining().inMilliseconds / span;
    return r.clamp(0.0, 1.0);
  }

  // ── Gesture handling ────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details, double maxThumbOffset) {
    if (_accepted || _expired) return;
    if (maxThumbOffset <= 0) return;
    _snapBack.stop();
    _dragStartX = details.localPosition.dx;
    _dragStartThumbOffset = _thumbOffset;
  }

  void _onPanUpdate(DragUpdateDetails details, double maxThumbOffset) {
    if (_accepted || _expired) return;
    if (_dragStartX == null || _dragStartThumbOffset == null) return;
    if (maxThumbOffset <= 0) return;
    final dx = details.localPosition.dx - _dragStartX!;
    final raw = _dragStartThumbOffset! + dx;
    setState(() {
      _thumbOffset = raw.clamp(0.0, maxThumbOffset);
    });
  }

  void _onPanEnd(DragEndDetails details, double maxThumbOffset) {
    if (_accepted || _expired) return;
    if (maxThumbOffset <= 0) {
      _thumbOffset = 0;
      return;
    }
    final progress = _thumbOffset / maxThumbOffset;
    if (progress >= _acceptThreshold) {
      _fireAccept(maxThumbOffset);
    } else {
      _animateSnapBack();
    }
    _dragStartX = null;
    _dragStartThumbOffset = null;
  }

  void _fireAccept(double maxThumbOffset) {
    HapticFeedback.mediumImpact();
    _accepted = true;
    _ticker?.cancel();
    final start = _thumbOffset;
    _confirm
      ..reset()
      ..addListener(() {
        if (!mounted) return;
        setState(() {
          _thumbOffset =
              start + (maxThumbOffset - start) * Curves.easeOut.transform(_confirm.value);
        });
      })
      ..forward();
    widget.onAccept();
  }

  void _animateSnapBack() {
    final start = _thumbOffset;
    _snapBack
      ..reset()
      ..addListener(() {
        if (!mounted) return;
        setState(() {
          _thumbOffset =
              start * (1.0 - Curves.easeOutCubic.transform(_snapBack.value));
        });
      })
      ..forward();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining();
    final accent = urgencyAccent(remaining, widget.slaWindow);
    final drainFraction = _drainFraction();

    // Connectivity gate. We early-out gestures and swap the caption when
    // the socket is anything other than `connected`. Reading the provider
    // here causes `build` to re-run when status changes, so the gate
    // updates promptly when the WS reconnects mid-offer.
    final wsStatus = ref.watch(wsConnectionProvider);
    final isConnected = wsStatus == WsConnectionStatus.connected;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final innerWidth = trackWidth - _trackPadding * 2;
        // Width of the colored fill in INNER coordinates.
        final fillWidthInner = innerWidth * drainFraction;
        // The thumb's leftmost-edge can travel from 0 to (fillWidth - thumbDiameter)
        // — the runway the user can swipe along. When the fill shrinks below
        // the thumb diameter, maxThumbOffset clamps to 0 and the swipe is no
        // longer possible (the offer is moments from auto-expiring).
        final maxThumbOffset =
            math.max(0.0, fillWidthInner - _thumbDiameter);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Connectivity gate: when offline, every gesture handler is a
          // no-op. We deliberately do NOT also check this inside
          // `_onPanStart` / `_onPanUpdate` / `_onPanEnd` — keeping the gate
          // at the GestureDetector closure means the body of those methods
          // has one less precondition to reason about, and the offline
          // semantics live next to the caption swap that surfaces them.
          onHorizontalDragStart: !isConnected
              ? null
              : (d) => _onPanStart(d, maxThumbOffset),
          onHorizontalDragUpdate: !isConnected
              ? null
              : (d) => _onPanUpdate(d, maxThumbOffset),
          onHorizontalDragEnd: !isConnected
              ? null
              : (d) => _onPanEnd(d, maxThumbOffset),
          child: Semantics(
            label: isConnected
                ? 'Swipe right to accept job offer for Rs. '
                    '${widget.payoutRupees}'
                : 'Reconnecting — accept disabled until the connection '
                    'recovers',
            button: true,
            enabled: isConnected,
            child: SizedBox(
              height: _pillHeight,
              width: trackWidth,
              child: Stack(
                children: [
                  // Outer pill — muted surface tone, full pill border radius.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(_pillHeight / 2),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Colored fill — anchored left, recedes from right as time
                  // elapses. Slightly smaller pill radius to inset cleanly
                  // inside the outer border. Dim slightly when offline so
                  // the disabled state reads as visually different from the
                  // ready-to-swipe state.
                  Positioned(
                    left: _trackPadding,
                    top: _trackPadding,
                    bottom: _trackPadding,
                    width: fillWidthInner,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        (_pillHeight - _trackPadding * 2) / 2,
                      ),
                      child: ColoredBox(
                        color: accent
                            .withValues(alpha: isConnected ? 0.85 : 0.45),
                      ),
                    ),
                  ),
                  // Caption — centered. Fades during drag so the thumb leads.
                  // Replaced wholesale by the offline caption when
                  // disconnected.
                  Positioned.fill(
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: (_accepted || !isConnected)
                            ? 0.0
                            : (_dragStartX != null ? 0.45 : 1.0),
                        child: _Caption(
                          payoutRupees: widget.payoutRupees,
                          onAccentForeground: accent,
                          drainFraction: drainFraction,
                        ),
                      ),
                    ),
                  ),
                  // Confirmed-state caption (replaces the slide caption once
                  // onAccept fires).
                  if (_accepted)
                    const Positioned.fill(
                      child: Center(child: _AcceptedCaption()),
                    ),
                  // Offline caption — shown whenever the WS is not in the
                  // `connected` state. Mutually exclusive with the accepted
                  // caption (a tech can't reach `_accepted == true` while
                  // offline because the gesture is gated upstream).
                  if (!isConnected && !_accepted)
                    const Positioned.fill(
                      child: Center(child: _OfflineCaption()),
                    ),
                  // Thumb — circle the user drags. Position is in OUTER
                  // coordinates (track padding + inner offset). When offline
                  // the idle-hint shimmer pauses (a moving chevron under
                  // the offline caption would read as "this is interactive
                  // — try harder," exactly the wrong message).
                  Positioned(
                    left: _trackPadding + _thumbOffset,
                    top: _trackPadding,
                    width: _thumbDiameter,
                    height: _thumbDiameter,
                    child: _Thumb(
                      accent: accent,
                      idleHint: _idleHint,
                      isDragging: _dragStartX != null,
                      isAccepted: _accepted,
                      isConnected: isConnected,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Caption (idle / dragging) ─────────────────────────────────────────────

class _Caption extends StatelessWidget {
  const _Caption({
    required this.payoutRupees,
    required this.onAccentForeground,
    required this.drainFraction,
  });

  final int payoutRupees;
  final Color onAccentForeground;
  final double drainFraction;

  @override
  Widget build(BuildContext context) {
    final formatted = 'Rs. ${NumberFormat('#,##0').format(payoutRupees)}';
    // Caption sits above the colored fill on the left and the muted track on
    // the right. White (high contrast on saturated accent) reads cleanly on
    // the fill side; on the muted side, white would disappear, so we lerp
    // toward a darker tone where the fill ends.
    //
    // For UX simplicity at this iteration: caption stays white. The fill is
    // wide enough early in the SLA that the caption sits over color; when
    // the fill shrinks late in the SLA, the caption is mostly over the
    // muted track, and white-on-muted-tone is OK for a 4-letter word.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 88),
      child: Text(
        'Slide to accept · $formatted',
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.white,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _AcceptedCaption extends StatelessWidget {
  const _AcceptedCaption();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_rounded, size: 22, color: Colors.white),
        SizedBox(width: 8),
        Text(
          'Accepted',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Caption shown when the WS is anything other than `connected`. The
/// signal-icon-plus-text combination reads as "we're trying to come back"
/// rather than "you tapped wrong" — a soft, recoverable state. The string
/// stays the same across all non-connected statuses (connecting,
/// reconnecting, failed, disconnected) on purpose: technicians don't need
/// the distinction, only that they should wait for the system to recover
/// before swiping.
class _OfflineCaption extends StatelessWidget {
  const _OfflineCaption();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded, size: 18, color: Colors.white),
        SizedBox(width: 8),
        Text(
          'Reconnecting…',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─── Thumb ─────────────────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.accent,
    required this.idleHint,
    required this.isDragging,
    required this.isAccepted,
    required this.isConnected,
  });

  final Color accent;
  final AnimationController idleHint;
  final bool isDragging;
  final bool isAccepted;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idleHint,
      builder: (context, _) {
        // Idle hint: subtle horizontal nudge on the chevron icon (NOT the
        // thumb itself — moving the thumb would change the perceived swipe
        // distance). 0..1 sawtooth, lerped to a 0..3px shift. Pauses while
        // dragging, after accept, and while disconnected.
        final t = idleHint.value;
        final shift = (isDragging || isAccepted || !isConnected)
            ? 0.0
            : 3.0 * 0.5 * (1 - math.cos(t * 2 * math.pi));
        return Container(
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.32),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(shift, 0),
            child: Icon(
              isAccepted
                  ? Icons.check_rounded
                  : Icons.chevron_right_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

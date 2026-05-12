import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/animations/loop_mode.dart';
import '_palette/orchestrator_palette.dart';

/// InDrive-style countdown button — the primary "I'm coming out" CTA on
/// the customer's ARRIVED view, and a passive mirror on the tech side.
///
/// **Why a custom button instead of an ElevatedButton?** The 5-minute
/// meeting window needs to be visually present on the action surface
/// itself — a separate strip above the map split the user's attention.
/// Fusing the timer INTO the button turns the customer's primary CTA
/// into the countdown.
///
/// **Visual contract (production polish):**
///   * 56px tall, 16px radius, brand-blue drop-shadow. Matches the
///     rest of the orchestrator's ElevatedButton recipe.
///   * **Gradient fill** — `brandPrimaryDeep` (top) → `brandPrimary`
///     (bottom). The lit-from-top feel anchors the button in the
///     orchestrator's brand-blue language.
///   * **Eased drain** — the left-anchored fill rectangle's width
///     fraction tweens (Curves.easeOutCubic, 950ms) between ticker
///     ticks instead of stepping. Plus the second pass: between
///     consecutive seconds the visible fill smoothly retreats rather
///     than jumping per-second.
///   * **Track** — the right-of-fill region is a soft brand-blue tint
///     (22% alpha) so the drained portion still reads as "this button",
///     not "white emptiness".
///   * **Inner top highlight** — a 1px-tall white-at-12% strip across
///     the top edge gives the button that injection-moulded look you
///     see on premium iOS toggles.
///   * **Pulse** — outer scale pulses 1.0↔1.012 over 2.2s; speeds up
///     to 1.1s in the last 30 seconds.
///   * **Last-30s drama** — `_isFinalCountdown` flips the fill to an
///     amber gradient (`warningAmber` → `warningAmberDeep`) and the
///     drop shadow tints amber. Communicates urgency without changing
///     the button's geometry or label.
///   * **Expiry** — single damped horizontal shake. Fill stays amber,
///     label becomes `expiredLabel`, time pill is hidden.
///
/// **Interactive vs read-only:**
///   * Default constructor — supplies [onTap] + [busy]; renders an
///     `InkWell` over the visual stack so taps splash through the
///     content. `busy=true` swaps the label for a spinner.
///   * [MeetingCountdownButton.readOnly] — no [onTap], no spinner.
///     Same animation. Used by the tech-side body to mirror the
///     customer's countdown without offering an action there.
class MeetingCountdownButton extends StatefulWidget {
  const MeetingCountdownButton({
    super.key,
    required this.arrivedAt,
    required this.label,
    required this.expiredLabel,
    required this.icon,
    required this.onTap,
    required this.busy,
    this.meetingWindow = const Duration(minutes: 5),
  });

  const MeetingCountdownButton.readOnly({
    super.key,
    required this.arrivedAt,
    required this.label,
    required this.expiredLabel,
    required this.icon,
    this.meetingWindow = const Duration(minutes: 5),
  }) : onTap = null,
       busy = false;

  /// Server-stamped arrival time. When null (defensive — backend always
  /// stamps before flipping to ARRIVED) the widget shows the full window
  /// remaining and never transitions to expired.
  final DateTime? arrivedAt;

  /// Action label, e.g. "I'm coming out" or "Customer notified".
  final String label;

  /// Label shown after the window elapses.
  final String expiredLabel;

  /// Icon to the left of the label. Hidden during busy state.
  final IconData icon;

  /// Tap handler. Null on the read-only constructor.
  final VoidCallback? onTap;

  /// Busy spinner. Suppresses taps and replaces the label.
  final bool busy;

  /// 5 minutes by default (InDrive's window).
  final Duration meetingWindow;

  @override
  State<MeetingCountdownButton> createState() => _MeetingCountdownButtonState();
}

class _MeetingCountdownButtonState extends State<MeetingCountdownButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shake;
  Timer? _ticker;
  bool _wasExpired = false;

  /// Last fill fraction we rendered. The drain Tween smoothly
  /// interpolates from this value to the current `_fillFraction` over
  /// the second between ticks, so the bar retreats rather than steps.
  double _renderedFillFraction = 1.0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    // Guard the looping pulse under flutter_test — `pumpAndSettle`
    // deadlocks otherwise. The countdown is still functional in tests
    // (the per-second ticker drives the drain Tween + label/expiry
    // logic); only the gentle scale pulse is suppressed.
    if (shouldLoopAnimations()) _pulse.repeat(reverse: true);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _wasExpired = _expired;
    _renderedFillFraction = _fillFraction;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _onTick();
    });
  }

  @override
  void didUpdateWidget(MeetingCountdownButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arrivedAt != widget.arrivedAt) {
      // Server pushed a new arrivedAt mid-life (rare — only on a
      // re-arrival edge). Reset the expired latch + drain anchor so
      // the next window animates from the new starting point.
      _wasExpired = _expired;
      _renderedFillFraction = _fillFraction;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  Duration get _remaining {
    final arrived = widget.arrivedAt;
    if (arrived == null) return widget.meetingWindow;
    return arrived.add(widget.meetingWindow).difference(DateTime.now());
  }

  bool get _expired => _remaining.inSeconds <= 0;

  /// True in the last 30s — drives the amber gradient drama.
  bool get _isFinalCountdown =>
      !_expired && _remaining.inSeconds <= 30;

  double get _fillFraction {
    final total = widget.meetingWindow.inSeconds;
    if (total <= 0) return 0;
    final remaining = _remaining.inSeconds.clamp(0, total);
    return remaining / total;
  }

  String get _mmss {
    final r = _remaining.isNegative ? Duration.zero : _remaining;
    final mm = r.inMinutes.toString().padLeft(1, '0');
    final ss = (r.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _onTick() {
    final isExpired = _expired;
    if (isExpired && !_wasExpired) {
      _wasExpired = true;
      _shake.forward(from: 0);
    }
    final speedUp = _isFinalCountdown;
    final desired = speedUp
        ? const Duration(milliseconds: 1100)
        : const Duration(milliseconds: 2200);
    if (_pulse.duration != desired) {
      _pulse.duration = desired;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shake]),
      builder: (context, _) {
        // Triangle wave in [0,1]: 1 - |2v - 1|. Drives the gentle scale.
        final pulseT = 1 - (_pulse.value - 0.5).abs() * 2;
        final pulseScale = 1.0 + 0.012 * pulseT;
        // Damped horizontal sine on the shake controller.
        final shakeOffset = _shake.isAnimating
            ? 10 * (1 - _shake.value) * math.sin(_shake.value * math.pi * 6)
            : 0.0;

        // Gradient ends. The "deep" stop is on top so the surface reads
        // as lit from above — matches the rest of the brand-blue
        // surfaces (action button, hero header pill).
        final (Color gradTop, Color gradBottom, Color shadowColor) =
            _expired || _isFinalCountdown
                ? (
                    OrchestratorPalette.warningAmberDeep,
                    OrchestratorPalette.warningAmber,
                    OrchestratorPalette.warningAmber,
                  )
                : (
                    OrchestratorPalette.brandPrimaryDeep,
                    OrchestratorPalette.brandPrimary,
                    OrchestratorPalette.brandPrimary,
                  );
        final trackColor = _expired
            ? OrchestratorPalette.warningAmber.withValues(alpha: 0.30)
            : OrchestratorPalette.brandPrimaryTrack;

        final labelText = _expired ? widget.expiredLabel : widget.label;
        final showTimePill = !_expired && !widget.busy;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(
            scale: pulseScale,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.42),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: trackColor),
                      // Drained fill — left-anchored. The fill's width
                      // tween over the second between ticks smooths
                      // the per-second drop into a continuous retreat.
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: _renderedFillFraction,
                            end: _fillFraction.clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 950),
                          curve: Curves.easeOutCubic,
                          onEnd: () {
                            _renderedFillFraction =
                                _fillFraction.clamp(0.0, 1.0);
                          },
                          builder: (context, value, _) {
                            return FractionallySizedBox(
                              widthFactor: value,
                              heightFactor: 1.0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [gradTop, gradBottom],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Top inner highlight — 1px strip of white@12%
                      // across the top edge. Gives the button the
                      // moulded look the rest of the brand-blue
                      // surfaces have.
                      const Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: 1,
                          child: ColoredBox(color: Color(0x1FFFFFFF)),
                        ),
                      ),
                      Center(
                        child: widget.busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _expired
                                        ? Icons.error_outline_rounded
                                        : widget.icon,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      labelText,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                  if (showTimePill) ...[
                                    const SizedBox(width: 12),
                                    _TimePill(text: _mmss),
                                  ],
                                ],
                              ),
                      ),
                      // Tap layer on top — Material+InkWell paints its
                      // ripple above the colored content. Read-only mode
                      // skips this entirely so there's no hover/focus
                      // affordance suggesting interactivity.
                      if (widget.onTap != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            highlightColor: Colors.white.withValues(alpha: 0.08),
                            splashColor: Colors.white.withValues(alpha: 0.18),
                            onTap: widget.busy ? null : widget.onTap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mm:ss pill on the right side of the countdown button. Tabular
/// figures so 4:09 and 4:10 don't shift sideways.
class _TimePill extends StatelessWidget {
  const _TimePill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontFeatures: [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

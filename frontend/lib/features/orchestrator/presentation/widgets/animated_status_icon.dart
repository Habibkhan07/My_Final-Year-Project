// Per-status hero animations for the orchestrator body. Replaces the
// flat `Icon(...)` heroes the stubs used previously. Each status has a
// tailored micro-animation so state changes feel alive — pulsing radar
// for AWAITING (the "waiting for tech accept" feel), scale-bounce for
// CONFIRMED, rotating wrench for IN_PROGRESS, etc.
//
// Built on the standard Flutter animation primitives (AnimationController
// + Tween) rather than Lottie — keeps the bundle tiny and lets us style
// the icons with the app's theme colour scheme. Lottie can swap in later
// for richer artwork; the public widget signature stays.
//
// Usage: `AnimatedStatusIcon(status: BookingStatus.awaiting, size: 180)`.
// Size is the bounding circle diameter — pick ~180 for body heroes,
// smaller for inline use.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/animations/loop_mode.dart';
import '../../../customer/bookings/domain/entities/booking_status.dart';

/// Hero animation for a booking-status body. Wraps a centered icon in
/// a tinted circular surface and runs a per-status loop or one-shot
/// animation tailored to convey the meaning of that state.
class AnimatedStatusIcon extends StatelessWidget {
  const AnimatedStatusIcon({
    super.key,
    required this.status,
    this.size = 180,
  });

  final BookingStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      // Defensive fallbacks for statuses whose body widgets no
      // longer route here. AwaitingBodyStub, InspectingBodyStub,
      // InProgressBodyStub stopped passing through AnimatedStatusIcon
      // in Chunk D.1; QuotedBodyStub stopped in Chunk F. The cases
      // remain for exhaustiveness — if a future caller ever passes
      // these statuses, they get a static muted icon rather than a
      // (now-deleted) animated hero. Visual downgrade is acceptable
      // for a defensive path.
      BookingStatus.awaiting => _MutedHero(
        size: size,
        icon: Icons.hourglass_bottom,
        tint: const Color(0xFFE89B25),
      ),
      BookingStatus.confirmed => _ConfirmedHero(size: size),
      BookingStatus.enRoute => _EnRouteHero(size: size),
      BookingStatus.arrived => _ArrivedHero(size: size),
      BookingStatus.inspecting => _MutedHero(
        size: size,
        icon: Icons.search_rounded,
        tint: const Color(0xFF3A6BC2),
      ),
      BookingStatus.quoted => _MutedHero(
        size: size,
        icon: Icons.receipt_long_rounded,
        tint: const Color(0xFF3A6BC2),
      ),
      BookingStatus.inProgress => _MutedHero(
        size: size,
        icon: Icons.build_circle_rounded,
        tint: const Color(0xFF3A6BC2),
      ),
      BookingStatus.completed => _CompletedHero(size: size),
      BookingStatus.completedInspectionOnly => _InspectionOnlyHero(size: size),
      BookingStatus.cancelled => _MutedHero(
        size: size,
        icon: Icons.event_busy,
        tint: Colors.grey,
      ),
      BookingStatus.techDeclined => _MutedHero(
        size: size,
        icon: Icons.do_not_disturb,
        tint: Colors.grey,
      ),
      BookingStatus.techNoResponse => _MutedHero(
        size: size,
        icon: Icons.hourglass_disabled,
        tint: Colors.grey,
      ),
      BookingStatus.noShow => _MutedHero(
        size: size,
        icon: Icons.person_off_outlined,
        tint: Colors.grey,
      ),
      BookingStatus.disputed => _DisputedHero(size: size),
      BookingStatus.pending ||
      BookingStatus.unknown => _MutedHero(
        size: size,
        icon: Icons.help_outline,
        tint: Colors.grey,
      ),
    };
  }
}

// ─── Shared frame ──────────────────────────────────────────────────────────

/// Common circular surface every hero sits on. Keeps geometry + tint
/// logic in one place so per-status widgets focus on the animation.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

// ─── CONFIRMED — scale-bounce check ───────────────────────────────────────

class _ConfirmedHero extends StatelessWidget {
  const _ConfirmedHero({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFF2EA567); // confident green
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, _) {
        final scale = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: _Surface(
            size: size,
            color: tint,
            child: Icon(
              Icons.check_circle_rounded,
              size: size * 0.55,
              color: tint,
            ),
          ),
        );
      },
    );
  }
}

// ─── EN_ROUTE — moving motorbike (rarely shown; map replaces this) ────────

class _EnRouteHero extends StatefulWidget {
  const _EnRouteHero({required this.size});
  final double size;

  @override
  State<_EnRouteHero> createState() => _EnRouteHeroState();
}

class _EnRouteHeroState extends State<_EnRouteHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (shouldLoopAnimations()) _slide.repeat();
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFFE85A2C); // active orange (the "in motion" tone)
    return _Surface(
      size: widget.size,
      color: tint,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, _) {
          final t = _slide.value;
          // Gentle horizontal wobble + slight bob so the motorbike looks
          // like it's traveling, not just sitting there.
          final dx = math.sin(t * 2 * math.pi) * 8;
          final dy = math.sin(t * 4 * math.pi) * 2;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Icon(
              Icons.two_wheeler_rounded,
              size: widget.size * 0.5,
              color: tint,
            ),
          );
        },
      ),
    );
  }
}

// ─── ARRIVED — settling person (rarely shown; map replaces this) ──────────

class _ArrivedHero extends StatelessWidget {
  const _ArrivedHero({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFF2EA567);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: _Surface(
            size: size,
            color: tint,
            child: Icon(
              Icons.directions_walk_rounded,
              size: size * 0.5,
              color: tint,
            ),
          ),
        );
      },
    );
  }
}

// ─── COMPLETED — celebratory scale-bounce + soft glow ─────────────────────

class _CompletedHero extends StatefulWidget {
  const _CompletedHero({required this.size});
  final double size;

  @override
  State<_CompletedHero> createState() => _CompletedHeroState();
}

class _CompletedHeroState extends State<_CompletedHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (shouldLoopAnimations()) _shine.repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFF2EA567);
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _shine,
          builder: (context, _) {
            final t = _shine.value;
            return Container(
              width: widget.size * (1.0 + 0.05 * math.sin(t * 2 * math.pi)),
              height: widget.size * (1.0 + 0.05 * math.sin(t * 2 * math.pi)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tint.withValues(alpha: 0.20),
                    tint.withValues(alpha: 0.0),
                  ],
                ),
              ),
            );
          },
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, value, _) {
            return Transform.scale(
              scale: value.clamp(0.0, 1.0),
              child: _Surface(
                size: widget.size,
                color: tint,
                child: Icon(
                  Icons.verified_rounded,
                  size: widget.size * 0.6,
                  color: tint,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── COMPLETED_INSPECTION_ONLY — softer completion ────────────────────────

class _InspectionOnlyHero extends StatelessWidget {
  const _InspectionOnlyHero({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFF6E7787); // neutral slate (job ended without repair)
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: _Surface(
            size: size,
            color: tint,
            child: Icon(
              Icons.receipt_rounded,
              size: size * 0.5,
              color: tint,
            ),
          ),
        );
      },
    );
  }
}

// ─── DISPUTED — bouncing gavel ────────────────────────────────────────────

class _DisputedHero extends StatefulWidget {
  const _DisputedHero({required this.size});
  final double size;

  @override
  State<_DisputedHero> createState() => _DisputedHeroState();
}

class _DisputedHeroState extends State<_DisputedHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (shouldLoopAnimations()) _bounce.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFFE89B25); // alert amber
    return _Surface(
      size: widget.size,
      color: tint,
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_bounce.value);
          return Transform.translate(
            offset: Offset(0, -t * 8),
            child: Transform.rotate(
              angle: -0.2 + t * 0.4,
              child: Icon(
                Icons.gavel_rounded,
                size: widget.size * 0.5,
                color: tint,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Muted hero (cancelled / rejected / no_show / unknown) ────────────────

class _MutedHero extends StatelessWidget {
  const _MutedHero({
    required this.size,
    required this.icon,
    required this.tint,
  });

  final double size;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: (value * 0.85).clamp(0.0, 1.0),
          child: _Surface(
            size: size,
            color: tint,
            child: Icon(icon, size: size * 0.5, color: tint),
          ),
        );
      },
    );
  }
}

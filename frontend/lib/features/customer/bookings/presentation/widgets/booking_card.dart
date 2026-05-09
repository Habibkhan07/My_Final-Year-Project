import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/icon_assets.dart';
import '../../domain/entities/booking_segment.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/customer_booking.dart';
import '../utils/booking_date_formatter.dart';
import 'booking_status_pill.dart';
import 'booking_tech_avatar.dart';

/// Single booking card — the centerpiece of the My Bookings list.
///
/// One widget renders **every status** (AWAITING, CONFIRMED, COMPLETED,
/// CANCELLED, REJECTED, PENDING). Differences across statuses are
/// expressed via:
///   * `booking.ui.badgeText` + `booking.ui.badgeTone` (server-driven)
///   * `booking.ui.headline` (server-driven)
///   * Cancelled visual decay (one local modifier — see §5.6)
///
/// **Never switch on raw [BookingStatus] for copy.** The widget reads
/// `booking.ui.*` verbatim. The whole data-sprint exists to make this
/// widget dumb. See session_4 §17 + §13.
///
/// Stateful so we can:
///   * Pulse the card background once when `booking.status` changes
///     between rebuilds (realtime patch animation, §8.3).
///   * Collapse + fade out when the patched status no longer matches
///     the current segment's predicate (§8.4 — e.g. `bookingRejected`
///     lands while the user is on Upcoming, the card animates away).
class BookingCard extends StatefulWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.segment,
    required this.serverTime,
  });

  final CustomerBooking booking;
  final BookingSegment segment;

  /// Server-anchored "now" used by the date formatter. Pulled from
  /// `CustomerBookingsListState.serverTime` — never `DateTime.now()`.
  final DateTime serverTime;

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _collapse;
  bool _collapsedDone = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _collapse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _collapse.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _collapsedDone = true);
      }
    });

    // If the card mounts already in a wrong-segment state (rare —
    // typically only after a hot reload or notifier-supplied list), we
    // still want it gone gracefully on the first frame. Schedule the
    // collapse for after layout so the user sees a fade rather than a
    // sudden disappearance.
    if (_belongsToWrongSegment(widget.booking.status, widget.segment)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _collapse.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant BookingCard old) {
    super.didUpdateWidget(old);

    final statusChanged = old.booking.status != widget.booking.status;
    if (statusChanged) {
      _pulse.forward(from: 0);
    }

    if (_belongsToWrongSegment(widget.booking.status, widget.segment) &&
        _collapse.status == AnimationStatus.dismissed) {
      _collapse.forward();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _collapse.dispose();
    super.dispose();
  }

  /// Decide whether a card with [s] should animate away from the [seg] tab.
  ///
  /// Authoritative segment classification (post-orchestrator):
  ///   * **Upcoming** — active lifecycle: `awaiting`, `confirmed`, `enRoute`,
  ///     `arrived`, `inspecting`, `quoted`, `inProgress`.
  ///   * **Past** — terminal or paused: `completed`, `completedInspectionOnly`,
  ///     `cancelled`, `rejected`, `noShow`, `disputed`.
  ///   * `pending` (legacy) and `unknown` are deliberately not classified —
  ///     leave them on whichever segment the server returned them on.
  static bool _belongsToWrongSegment(BookingStatus s, BookingSegment seg) {
    return switch ((seg, s)) {
      (BookingSegment.upcoming, BookingStatus.completed) => true,
      (BookingSegment.upcoming, BookingStatus.completedInspectionOnly) => true,
      (BookingSegment.upcoming, BookingStatus.cancelled) => true,
      (BookingSegment.upcoming, BookingStatus.rejected) => true,
      (BookingSegment.upcoming, BookingStatus.noShow) => true,
      (BookingSegment.upcoming, BookingStatus.disputed) => true,
      (BookingSegment.past, BookingStatus.awaiting) => true,
      (BookingSegment.past, BookingStatus.confirmed) => true,
      (BookingSegment.past, BookingStatus.enRoute) => true,
      (BookingSegment.past, BookingStatus.arrived) => true,
      (BookingSegment.past, BookingStatus.inspecting) => true,
      (BookingSegment.past, BookingStatus.quoted) => true,
      (BookingSegment.past, BookingStatus.inProgress) => true,
      _ => false,
    };
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    context.push('/booking/${widget.booking.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (_collapsedDone) return const SizedBox.shrink();

    final isCancelled = widget.booking.status == BookingStatus.cancelled;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _collapse]),
      builder: (context, _) {
        // Pulse: lerp bg from low → lowest as the controller advances 0→1.
        // Effect is "card was tinted, now it's normal" — a subtle settle.
        final pulseColor = Color.lerp(
          AppColors.surfaceContainerLow,
          AppColors.surfaceContainerLowest,
          _pulse.value,
        )!;
        final cardBg = _pulse.isAnimating || _pulse.value > 0
            ? pulseColor
            : AppColors.surfaceContainerLowest;

        final collapseFactor = 1 - _collapse.value;

        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: collapseFactor.clamp(0, 1).toDouble(),
            child: Opacity(
              opacity: collapseFactor.clamp(0, 1).toDouble(),
              child: _buildCardBody(context, cardBg, isCancelled),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardBody(BuildContext context, Color cardBg, bool isCancelled) {
    final body = RepaintBoundary(
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppShapes.radiusMD),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(booking: widget.booking),
                const SizedBox(height: AppSpacing.s3),
                _Headline(booking: widget.booking),
                const SizedBox(height: AppSpacing.s3),
                const _Divider(),
                const SizedBox(height: AppSpacing.s3),
                _Meta(
                  booking: widget.booking,
                  serverTime: widget.serverTime,
                  isCancelled: isCancelled,
                ),
                const SizedBox(height: AppSpacing.s2),
                const _Divider(),
                const SizedBox(height: AppSpacing.s2),
                _PriceRow(booking: widget.booking, isCancelled: isCancelled),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isCancelled) return body;
    // Cancelled cards: subtle global opacity decay (§5.6). Keep layout,
    // copy, and structure identical — never line-through the headline.
    return Opacity(opacity: 0.85, child: body);
  }
}

// ───────────────────────── Header row ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.booking});
  final CustomerBooking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Hero(
                tag: 'booking-icon-${booking.id}',
                child: SvgPicture.asset(
                  IconAssets.path(booking.service.iconName),
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    AppColors.outline,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  booking.service.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.96,
                    color: AppColors.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        // Pill morphs cleanly across realtime status patches: the key
        // drives AnimatedSwitcher to crossfade old → new.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: BookingStatusPill(
            key: ValueKey('${booking.ui.badgeText}-${booking.ui.badgeTone}'),
            text: booking.ui.badgeText,
            tone: booking.ui.badgeTone,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Headline row ─────────────────────────

class _Headline extends StatelessWidget {
  const _Headline({required this.booking});
  final CustomerBooking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BookingTechAvatar(
          imageUrl: booking.technician.profilePictureUrl,
          displayName: booking.technician.displayName,
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Text(
            booking.ui.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              height: 24 / 17,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Meta row ─────────────────────────

class _Meta extends StatelessWidget {
  const _Meta({
    required this.booking,
    required this.serverTime,
    required this.isCancelled,
  });
  final CustomerBooking booking;
  final DateTime serverTime;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final dateLabel = formatBookingDate(
      scheduledStart: booking.scheduledStart,
      serverNow: serverTime,
      status: booking.status,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaRow(
          icon: Icons.schedule,
          text: dateLabel,
          opacity: isCancelled ? 0.85 : 1.0,
        ),
        if (booking.addressLabel != null) ...[
          const SizedBox(height: 6),
          _MetaRow(
            icon: Icons.location_on_outlined,
            text: booking.addressLabel!,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
            opacity: isCancelled ? 0.85 : 1.0,
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.decoration,
    this.opacity = 1.0,
  });
  final IconData icon;
  final String text;
  final TextDecoration? decoration;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.outline),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant,
                decoration: decoration,
                decorationColor: AppColors.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Price row ─────────────────────────

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.booking, required this.isCancelled});
  final CustomerBooking booking;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final hasContext = booking.price.context.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasContext)
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppColors.outline,
                ),
                const SizedBox(width: AppSpacing.s2),
                Flexible(
                  child: Text(
                    booking.price.context,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: AppSpacing.s2),
        Opacity(
          opacity: isCancelled ? 0.7 : 1.0,
          child: Text(
            booking.price.uiLabel,
            style: const TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Divider ─────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.outlineVariant.withValues(alpha: 0.30),
    );
  }
}

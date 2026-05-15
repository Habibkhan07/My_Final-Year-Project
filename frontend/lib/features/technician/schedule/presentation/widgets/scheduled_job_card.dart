import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/icon_assets.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../customer/bookings/presentation/utils/booking_date_formatter.dart';
import '../../../../customer/bookings/presentation/utils/bookings_palette.dart';
import '../../../../customer/bookings/presentation/widgets/booking_status_pill.dart';
import '../../../../customer/bookings/presentation/widgets/booking_tech_avatar.dart';
import '../../domain/entities/scheduled_job.dart';

/// Single scheduled-job card — the centerpiece of the tech's Schedule
/// screen.
///
/// One widget renders **every status**. Differences across statuses are
/// expressed via:
///   * `job.ui.badgeText` + `job.ui.badgeTone` (server-driven)
///   * `job.ui.headline` (server-driven)
///   * Terminal greyscale + opacity (one local modifier)
///
/// **Never switch on raw [BookingStatus] for copy.** The widget reads
/// `job.ui.*` verbatim. The whole BE selector exists to make this widget
/// dumb (see SCHEDULED_JOBS_API.md §1.8).
///
/// **Diffs from customer side:**
///   * Customer block instead of technician block (`job.customer` not
///     `booking.technician`).
///   * Payout block instead of price block — the secondary line reads
///     "After Rs. X commission" / "Inspection fee (cash)" / "Forgone"
///     instead of "Total" / "Cash to collect".
///   * No collapse-on-segment-mismatch animation: the list refreshes on
///     state-machine events, so segment mismatch is rare — by the time
///     the user notices, the refetch has already removed the row.
///   * No pulse-on-status-change animation: same reason. The animation
///     was for inline patches; this list does full refetch.
///
/// Stateful for the server-time ticker only — the date formatter needs
/// a fresh "now" anchor so "In 30 min" doesn't stick at 30 forever.
class ScheduledJobCard extends StatefulWidget {
  const ScheduledJobCard({
    super.key,
    required this.job,
    required this.serverTime,
  });

  final ScheduledJob job;

  /// Server-anchored "now" pulled from `ScheduledJobsListState.serverTime`.
  /// The ticker anchors a stopwatch off this and adds elapsed wall-clock
  /// to render "In 30 min" → "In 5 min" → "Now" without device-clock skew.
  final DateTime serverTime;

  @override
  State<ScheduledJobCard> createState() => _ScheduledJobCardState();
}

class _ScheduledJobCardState extends State<ScheduledJobCard> {
  Timer? _ticker;
  late Stopwatch _stopwatch;
  late DateTime _serverTimeAnchor;

  @override
  void initState() {
    super.initState();
    _serverTimeAnchor = widget.serverTime;
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ScheduledJobCard old) {
    super.didUpdateWidget(old);
    if (old.serverTime != widget.serverTime) {
      _serverTimeAnchor = widget.serverTime;
      _stopwatch
        ..reset()
        ..start();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  DateTime get _serverNow => _serverTimeAnchor.add(_stopwatch.elapsed);

  /// Statuses where the tech is mid-job — show a pulsing dot beside the
  /// pill so the row reads as "active" even on the Past tab during the
  /// brief overlap between a state transition and the count refresh.
  static bool _isLiveStatus(BookingStatus s) => switch (s) {
    BookingStatus.enRoute ||
    BookingStatus.arrived ||
    BookingStatus.inspecting ||
    BookingStatus.quoted ||
    BookingStatus.inProgress => true,
    _ => false,
  };

  /// Tap target. Non-terminal rows push the shared
  /// `BookingOrchestratorScreen` (same route the dashboard's up-next card
  /// uses; the screen resolves the tech's view server-side). Terminal
  /// rows have no detail screen yet — null disables the InkWell and the
  /// card reads as non-interactive.
  void _handleTap() {
    HapticFeedback.lightImpact();
    context.push('/booking/${widget.job.id}');
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isCancelled = job.status == BookingStatus.cancelled;
    final isTerminal = job.status.isTerminal;
    final accentColor = BookingsPalette.toneAccent(job.ui.badgeTone);
    final isLive = _isLiveStatus(job.status);
    final onTap = isTerminal ? null : _handleTap;

    final body = RepaintBoundary(
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppShapes.radiusMD),
              border: Border.all(
                color: BookingsPalette.brandPrimaryTint12,
                width: 1,
              ),
              boxShadow: BookingsPalette.brandSoftShadow,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: accentColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(job: job, isLive: isLive),
                          const SizedBox(height: AppSpacing.s3),
                          _Headline(job: job),
                          const SizedBox(height: AppSpacing.s3),
                          const _Divider(),
                          const SizedBox(height: AppSpacing.s3),
                          _Meta(
                            job: job,
                            serverTime: _serverNow,
                            isCancelled: isCancelled,
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          const _Divider(),
                          const SizedBox(height: AppSpacing.s2),
                          _PayoutRow(job: job, isCancelled: isCancelled),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final wrapped = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: body,
    );

    if (!isTerminal) return wrapped;
    return Opacity(
      opacity: 0.70,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_kGreyscaleMatrix),
        child: wrapped,
      ),
    );
  }
}

/// Luminosity-preserving greyscale matrix (Rec. 709). Same constants the
/// customer card uses — terminal rows read as archived.
const List<double> _kGreyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

// ───────────────────────── Header row ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.job, required this.isLive});
  final ScheduledJob job;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              SvgPicture.asset(
                IconAssets.path(job.service.iconName),
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.outline,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  job.service.name.toUpperCase(),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLive) ...[
              _LivePulseDot(
                color: BookingsPalette.toneAccent(job.ui.badgeTone),
              ),
              const SizedBox(width: 6),
            ],
            BookingStatusPill(
              text: job.ui.badgeText,
              tone: job.ui.badgeTone,
            ),
          ],
        ),
      ],
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot({required this.color});
  final Color color;

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Opacity(
                opacity: (1.0 - t) * 0.55,
                child: Container(
                  width: 6 + (10 * t),
                  height: 6 + (10 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.55),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Headline row ─────────────────────────

class _Headline extends StatelessWidget {
  const _Headline({required this.job});
  final ScheduledJob job;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Audience-agnostic avatar — same widget the customer side uses
        // for the technician, here it shows the customer's initials.
        BookingTechAvatar(
          imageUrl: job.customer.profilePictureUrl,
          displayName: job.customer.displayName,
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Text(
            job.ui.headline,
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
    required this.job,
    required this.serverTime,
    required this.isCancelled,
  });
  final ScheduledJob job;
  final DateTime serverTime;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final dateLabel = formatBookingDate(
      scheduledStart: job.scheduledStart,
      serverNow: serverTime,
      status: job.status,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaRow(
          icon: Icons.schedule,
          text: dateLabel,
          opacity: isCancelled ? 0.85 : 1.0,
        ),
        if (job.addressLabel != null) ...[
          const SizedBox(height: 6),
          _MetaRow(
            icon: Icons.location_on_outlined,
            text: job.addressLabel!,
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

// ───────────────────────── Payout row ─────────────────────────

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.job, required this.isCancelled});
  final ScheduledJob job;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final hasContext = job.payout.context.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasContext)
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: AppColors.outline,
                ),
                const SizedBox(width: AppSpacing.s2),
                Flexible(
                  child: Text(
                    job.payout.context,
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
            job.payout.uiLabel,
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

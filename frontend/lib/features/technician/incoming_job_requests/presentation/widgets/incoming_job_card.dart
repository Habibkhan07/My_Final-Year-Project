import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/booking_type.dart';
import '../../domain/entities/job_new_request.dart';
import 'incoming_job_swipe_to_accept.dart';

/// Default-snap content for [IncomingJobSheet]. Five blocks, top to bottom:
///
///   1. Eyebrow tonal bar (drag handle + INCOMING REQUEST + day/time line)
///   2. Service title — what the customer asked for
///   3. Address row — locality. Hidden when [JobNewRequest.locationLabel] is
///      null (legacy bookings, address detached).
///   4. EXPECTED PAYOUT hero block (rupee number + floor-condition subtext)
///   5. Action stack (Accept primary CTA + Decline secondary)
///
/// **Discipline.** All booking types share the same chrome and accent. The
/// card never names the engagement model ("Inspection" / "Fixed Gig" /
/// "Labor Gig" do not appear anywhere). Behavioural difference is carried
/// only by one line of payout subtext; everything else is identical across
/// types.
///
/// **No countdown ring on the card.** Time-pressure lives entirely inside
/// the swipe-to-accept widget's draining track — a separate ring would
/// compete with the action surface for the same role.
///
/// **No multi-request indicator.** No "+N pending" pill, no peek strip
/// rendered above. The host shows ONE offer at a time; subsequent offers
/// queue in the notifier and surface only when the head resolves.
class IncomingJobCard extends StatelessWidget {
  const IncomingJobCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onExpire,
  });

  /// The head offer rendered as the four-block card.
  final JobNewRequest request;

  /// Fired once when the technician completes the swipe-to-accept gesture.
  final VoidCallback onAccept;

  /// Fired when the technician taps Decline.
  final VoidCallback onDecline;

  /// Fired once when the swipe-track's drain reaches zero — the offer's SLA
  /// has elapsed and the technician didn't act in time. Same end-state as
  /// decline (offer leaves the queue) but distinct semantically: when the
  /// accept endpoint lands the host will decline-POST on user decline and
  /// no-op on expire (server-side Celery task fires authoritative).
  final VoidCallback onExpire;

  @override
  Widget build(BuildContext context) {
    final locationLabel = request.locationLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EyebrowBar(request: request),
        _ServiceTitleRow(request: request),
        if (locationLabel != null) _AddressRow(label: locationLabel),
        _ExpectedPayoutBlock(request: request),
        _ActionStack(
          request: request,
          onAccept: onAccept,
          onDecline: onDecline,
          onExpire: onExpire,
        ),
      ],
    );
  }
}

// ─── 1. Eyebrow bar ────────────────────────────────────────────────────────

class _EyebrowBar extends StatelessWidget {
  const _EyebrowBar({required this.request});
  final JobNewRequest request;

  @override
  Widget build(BuildContext context) {
    final parts = eyebrowTimeParts(request);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(AppShapes.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 14,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'INCOMING REQUEST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.outline,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _EyebrowTimeLine(parts: parts),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The headline of the eyebrow — the day part is heavy and lands first; the
/// clock recedes to muted detail. ASAP collapses both to a single bold red
/// line because there is no clock value worth showing.
class _EyebrowTimeLine extends StatelessWidget {
  const _EyebrowTimeLine({required this.parts});
  final ({String day, String? clock, bool isAsap}) parts;

  @override
  Widget build(BuildContext context) {
    if (parts.isAsap) {
      return const Text(
        'ASAP',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.error,
          letterSpacing: 0.3,
          height: 1.2,
        ),
        maxLines: 1,
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: parts.day,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.1,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: '  ·  ${parts.clock}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0,
              height: 1.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─── 2. Service title row ──────────────────────────────────────────────────

class _ServiceTitleRow extends StatelessWidget {
  const _ServiceTitleRow({required this.request});
  final JobNewRequest request;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        request.serviceName,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.44,
          color: AppColors.onSurface,
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── 3. Address row ────────────────────────────────────────────────────────

/// Pin icon + locality-leading address. The label arrives pre-composed by the
/// backend (`Locality, City` — e.g. `'Bahria Town, Rawalpindi'`). We split it
/// on the first comma so the locality reads heavy and the city recedes to
/// context — locality is the bit a tech navigates to, city is just framing.
///
/// Mounted only when `request.locationLabel != null` — there is no fallback
/// string for legacy bookings; the row is simply absent. Full street address
/// is intentionally not shown pre-accept (privacy + anti-poach); only the
/// suburb-level locality the backend has pre-composed.
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final commaIdx = label.indexOf(',');
    final hasCity = commaIdx > 0 && commaIdx < label.length - 1;
    final locality = hasCity ? label.substring(0, commaIdx) : label;
    final cityTail = hasCity ? label.substring(commaIdx) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 14,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: locality,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      height: 1.3,
                    ),
                  ),
                  if (cityTail != null)
                    TextSpan(
                      text: cityTail,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 4. Expected Payout hero block ─────────────────────────────────────────

class _ExpectedPayoutBlock extends StatelessWidget {
  const _ExpectedPayoutBlock({required this.request});
  final JobNewRequest request;

  @override
  Widget build(BuildContext context) {
    final formatted =
        'Rs. ${NumberFormat('#,##0').format(request.payoutRupees)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPECTED PAYOUT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.outline,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.36,
              color: AppColors.onSurface,
              height: 1.1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _payoutSubtext(request.bookingType),
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _payoutSubtext(BookingType type) {
  switch (type) {
    case BookingType.inspection:
      return 'Visit fee — yours even if your on-site quote is declined.';
    case BookingType.fixedGig:
      return 'Yours when you complete the booked service.';
    case BookingType.laborGig:
      return 'Yours when you complete the agreed labor.';
  }
}

// ─── 5. Action stack ───────────────────────────────────────────────────────

/// Swipe-to-accept (primary, 72dp) over Decline (secondary tap, 48dp).
/// Asymmetric: accept = commitment = swipe; decline = reversible = tap.
class _ActionStack extends StatelessWidget {
  const _ActionStack({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onExpire,
  });

  final JobNewRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onExpire;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          IncomingJobSwipeToAccept(
            expiresAt: request.expiresAt,
            slaWindow: request.slaWindow,
            payoutRupees: request.payoutRupees,
            onAccept: onAccept,
            onExpire: onExpire,
          ),
          const SizedBox(height: 8),
          _SecondaryDeclineButton(onTap: onDecline),
        ],
      ),
    );
  }
}

class _SecondaryDeclineButton extends StatelessWidget {
  const _SecondaryDeclineButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppShapes.radiusXL),
        ),
        child: const Center(
          child: Text(
            'Decline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Eyebrow time formatting ───────────────────────────────────────────────

/// "Right now" threshold: any booking whose [JobNewRequest.scheduledStart] is
/// within this window of the present clock reads as ASAP. Sized generously to
/// absorb dispatch latency — a customer pressing "book now" produces a
/// `scheduledStart` close to server-time, but by the time the offer reaches
/// the technician's queue (WS hop + render) several minutes may have elapsed.
const Duration _asapWindow = Duration(minutes: 30);

/// Structured parts of the eyebrow time so the widget can render the day and
/// clock segments with separate styles — the eye lands on the day, the clock
/// recedes to detail.
///
///   * `isAsap == true` → [JobNewRequest.scheduledStart] is within
///     [_asapWindow] of `now`. `day = 'ASAP'`, `clock = null`.
///   * Otherwise `day` is `'Today'`, `'Tomorrow'`, or a dated `'EEE, MMM d'`
///     fallback, and `clock` is the localized `h:mm a` string.
///
/// **Why scheduledStart, not slaWindow.** An earlier version of this helper
/// gated ASAP on `slaWindow.inSeconds <= 90`. That worked accidentally — it
/// inferred "right now" from "tight response window" — but the two are
/// independent dimensions on the wire. With the 5-minute SLA floor enforced
/// by the backend (see flag.md), every offer's `slaWindow` is now ≥ 5min, and
/// the slaWindow proxy always returns false. `scheduledStart` is the actual
/// signal: it answers "when does the customer want this?".
@visibleForTesting
({String day, String? clock, bool isAsap}) eyebrowTimeParts(
  JobNewRequest request, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final start = request.scheduledStart.toLocal();
  final referenceLocal = reference.toLocal();
  final delta = start.difference(referenceLocal);

  if (delta <= _asapWindow) {
    return (day: 'ASAP', clock: null, isAsap: true);
  }

  final today = DateTime(referenceLocal.year, referenceLocal.month, referenceLocal.day);
  final startDay = DateTime(start.year, start.month, start.day);
  final clock = DateFormat.jm().format(start);

  if (startDay == today) {
    return (day: 'Today', clock: clock, isAsap: false);
  }
  if (startDay == today.add(const Duration(days: 1))) {
    return (day: 'Tomorrow', clock: clock, isAsap: false);
  }
  return (
    day: DateFormat('EEE, MMM d').format(start),
    clock: clock,
    isAsap: false,
  );
}

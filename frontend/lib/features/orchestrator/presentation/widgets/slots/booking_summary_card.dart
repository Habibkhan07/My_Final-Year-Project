import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/map/map_provider.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_orchestrator_role.dart';
import '../_palette/orchestrator_palette.dart';
import '../feedback/orchestrator_snack.dart';
import '../sheets/booking_summary_details_sheet.dart';

/// Slim identity strip — the always-visible "who you're dealing with"
/// row rendered just above the action bar.
///
/// **Why this widget got slim.** Pre-L it was a ~276-px panel with
/// avatar + service line + schedule line + 3-line address + a
/// full-width Call button. On a 720-px phone that's ~37% of viewport
/// dedicated to identity + recovery info — leaving the map / quote /
/// receipt with ~25%. The audit's Section 6.2 prescribed collapsing
/// to a single row; Chunk L delivers that.
///
/// **What ships now (~64 px):**
///   * 36-px avatar (letter-initial fallback when no photo)
///   * Name (titleSmall w800) + service-line subtitle (1 line)
///   * Rating chip (★ N.N) when the customer is viewing an accepted
///     booking with a non-zero `ratingAverage`
///   * Icon-only [📞] call button — same tap target, same launcher
///     logic, same hide-on-terminal / hide-on-awaiting-customer
///     guards as before
///   * Tiny chevron hinting "tap to expand"
///
/// **What disappeared.** Schedule line, 3-line address, full-width
/// labelled Call button. They all live one tap away in
/// [BookingSummaryDetailsSheet] — opens when the user taps anywhere on
/// the strip body (not the call icon, which always dials).
///
/// **Why the strip is still a real card.** The brand-blue hairline +
/// soft shadow keep visual continuity with the rest of the
/// orchestrator's surface family. A bare row without chrome would feel
/// like it had drifted out of the design system.
class BookingSummaryCard extends ConsumerWidget {
  const BookingSummaryCard({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCustomerView =
        booking.viewerRole == BookingOrchestratorRole.customer;

    // Same identity-resolution + reachability gating as the previous
    // panel — preserved verbatim because the strip's affordances and
    // their visibility have to match the production rules. The only
    // visual difference is the layout below this point.
    final isAwaitingCustomerView =
        isCustomerView && booking.status == BookingStatus.awaiting;
    final rawCounterpartyName = isCustomerView
        ? booking.technician.displayName
        : booking.customer.fullName;
    final counterpartyName = rawCounterpartyName.trim().isEmpty
        ? (isCustomerView ? 'Your technician' : 'Customer')
        : rawCounterpartyName;
    final counterpartyPhoto =
        isCustomerView ? booking.technician.profilePictureUrl : null;
    final counterpartyPhone = isCustomerView
        ? booking.technician.phoneNo
        : booking.customer.phoneNo;
    final showRating = isCustomerView &&
        booking.technician.ratingAverage > 0 &&
        !isAwaitingCustomerView;
    final ratingAverage = booking.technician.ratingAverage;
    final subService = booking.subService;
    final serviceLine = subService == null
        ? booking.service.name
        : '${booking.service.name} · ${subService.name}';
    final canCall = counterpartyPhone.isNotEmpty &&
        !booking.status.isTerminal &&
        !isAwaitingCustomerView;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              BookingSummaryDetailsSheet.show(context, booking),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: OrchestratorPalette.brandPrimary
                    .withValues(alpha: 0.10),
              ),
              boxShadow: OrchestratorPalette.brandSoftShadow,
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(
                  name: counterpartyName,
                  photoUrl: counterpartyPhoto,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              counterpartyName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: OrchestratorPalette.inkPrimary,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showRating) ...[
                            const SizedBox(width: 6),
                            _RatingChip(value: ratingAverage),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        serviceLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: OrchestratorPalette.inkSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (canCall)
                  _CallIconButton(
                    onTap: () =>
                        _launchDialler(ref, context, counterpartyPhone),
                  ),
                Icon(
                  Icons.expand_less_rounded,
                  size: 18,
                  color: OrchestratorPalette.inkTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchDialler(
    WidgetRef ref,
    BuildContext context,
    String phone,
  ) async {
    final launcher = ref.read(urlLauncherProvider);
    final ok = await launcher.launch(Uri(scheme: 'tel', path: phone));
    if (!ok && context.mounted) {
      OrchestratorSnack.error(context, 'Could not open dialler for $phone');
    }
  }
}

/// 36-px avatar. Same `CircleAvatar` recipe as the panel had — letter
/// initial fallback when no photo URL, no-op error handler so a 404
/// from the network doesn't crash the widget.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial =
        (name.isNotEmpty ? name.characters.first : '?').toUpperCase();
    final ImageProvider? avatarImage =
        (photoUrl != null && photoUrl!.isNotEmpty)
            ? NetworkImage(photoUrl!)
            : null;
    return CircleAvatar(
      radius: 18,
      backgroundColor: OrchestratorPalette.brandPrimary,
      foregroundImage: avatarImage,
      // Flutter asserts onForegroundImageError demands a non-null
      // foregroundImage. Only attach the no-op handler when the URL
      // was actually present — otherwise the framework throws the
      // moment this widget builds.
      onForegroundImageError: avatarImage == null ? null : (_, _) {},
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Compact star+number pill. Same colors as the pre-L panel for
/// continuity with the design-system pass tracked in
/// `project_ui_cleanup_planned`.
class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB400).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 12,
            color: Color(0xFFCC8A00),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFF7A4F01),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon-only call affordance on the right of the strip. Brand-blue
/// 12% fill so it doesn't compete with the orchestrator's primary
/// action button below.
///
/// Sits inside the strip's tap-to-expand surface but absorbs taps
/// independently — the InkWell's `onTap` fires the dialler, not the
/// sheet. (Material's gesture arena resolves the inner InkWell first.)
class _CallIconButton extends StatelessWidget {
  const _CallIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.phone_rounded,
            size: 20,
            color: OrchestratorPalette.brandPrimary,
          ),
        ),
      ),
    );
  }
}

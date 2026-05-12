import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/map/map_provider.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_orchestrator_role.dart';
import '../_palette/orchestrator_palette.dart';
import '../feedback/orchestrator_snack.dart';

/// "Booking summary" card — the always-visible context strip rendered
/// at the BOTTOM of the orchestrator screen (just above the action
/// area), per the layout rule: hero / map leads, booking info trails.
///
/// **Design notes (post-screenshot critique):**
///   * No dividers, no row-stacking — those made the previous version
///     feel like a stacked list of unrelated bits.
///   * One padded surface, top-to-bottom flow: identity → context →
///     action. The call button is a proper labelled CTA (icon + name),
///     not a floating circular icon.
///   * Service icon is dropped — the service / subservice text under
///     the counterparty's name does the same job without a competing
///     visual element next to the avatar.
///   * The call CTA is a *tinted* button (brand-blue 12% fill,
///     brand-blue text/icon). That keeps it clearly secondary to the
///     orchestrator's primary action button which sits directly below
///     this card — two solid brand-blue buttons stacked would compete.
///
/// **Avatar.** `CircleAvatar` with `foregroundImage` + a no-op
/// `onForegroundImageError`. The child (letter initial) renders as the
/// fallback when the URL is missing OR when the image fails to load.
class BookingSummaryCard extends ConsumerWidget {
  const BookingSummaryCard({super.key, required this.booking});

  final BookingDetail booking;

  static const _brandBlue = OrchestratorPalette.brandPrimary;
  static const _ink = OrchestratorPalette.inkPrimary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCustomerView =
        booking.viewerRole == BookingOrchestratorRole.customer;

    final counterpartyName = isCustomerView
        ? booking.technician.displayName
        : booking.customer.fullName;
    final counterpartyPhoto =
        isCustomerView ? booking.technician.profilePictureUrl : null;
    final counterpartyPhone = isCustomerView
        ? booking.technician.phoneNo
        : booking.customer.phoneNo;
    final showRating =
        isCustomerView && booking.technician.ratingAverage > 0;
    final ratingAverage = booking.technician.ratingAverage;
    final subService = booking.subService;
    final serviceLine = subService == null
        ? booking.service.name
        : '${booking.service.name} · ${subService.name}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: _brandBlue.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IdentityRow(
                name: counterpartyName,
                photoUrl: counterpartyPhoto,
                serviceLine: serviceLine,
                showRating: showRating,
                ratingAverage: ratingAverage,
              ),
              const SizedBox(height: 14),
              _InfoLine(
                icon: Icons.schedule_rounded,
                text: _formatSlot(booking.scheduledStart, booking.scheduledEnd),
              ),
              if (booking.address != null) ...[
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.location_on_rounded,
                  text: booking.address!.addressText,
                ),
              ],
              // Live-relationship affordance — gated to non-terminal
              // bookings. Once the booking is cancelled / rejected /
              // no-show / disputed / completed, the working
              // relationship is over and a permanently-dial-able phone
              // link on a stale snapshot is both UX-misleading ("am I
              // still allowed to call them?") and a low-grade privacy
              // regression. Customer reaches the tech for follow-up
              // via a new booking, not the dead orchestrator screen.
              if (counterpartyPhone.isNotEmpty &&
                  !booking.status.isTerminal) ...[
                const SizedBox(height: 14),
                _CallButton(
                  label: 'Call ${_firstName(counterpartyName)}',
                  onTap: () => _launchDialler(ref, context, counterpartyPhone),
                ),
              ],
            ],
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

  static String _firstName(String full) {
    final trimmed = full.trim();
    if (trimmed.isEmpty) return 'them';
    final firstSpace = trimmed.indexOf(' ');
    return firstSpace < 0 ? trimmed : trimmed.substring(0, firstSpace);
  }

  /// "Today · 3:00 PM – 5:00 PM" / "Tomorrow · …" / "Mon, 12 May · …".
  static String _formatSlot(DateTime start, DateTime end) {
    final timeFmt = DateFormat.jm();
    final timeRange = '${timeFmt.format(start)} – ${timeFmt.format(end)}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final startDay = DateTime(start.year, start.month, start.day);
    if (startDay == today) return 'Today · $timeRange';
    if (startDay == tomorrow) return 'Tomorrow · $timeRange';
    final dateFmt = DateFormat('EEE, d MMM');
    return '${dateFmt.format(start)} · $timeRange';
  }
}

/// Top hero: avatar (with letter fallback) + name + optional rating
/// chip + service-line subtitle. No dividers.
class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.name,
    required this.photoUrl,
    required this.serviceLine,
    required this.showRating,
    required this.ratingAverage,
  });

  final String name;
  final String? photoUrl;
  final String serviceLine;
  final bool showRating;
  final double ratingAverage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        (name.isNotEmpty ? name.characters.first : '?').toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFF0051AE),
          foregroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
              ? NetworkImage(photoUrl!)
              : null,
          // No-op so a 404 / offline / test-isolate failure cleanly
          // falls back to the letter child instead of bubbling as an
          // unhandled framework exception.
          onForegroundImageError: (_, _) {},
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: BookingSummaryCard._ink,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showRating) _RatingChip(value: ratingAverage),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                serviceLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: BookingSummaryCard._ink.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small star+number pill. Rendered only when the tech has reviews
/// (`ratingAverage > 0`).
class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB400).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFCC8A00)),
          const SizedBox(width: 3),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFF7A4F01),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon + text info line. Used for the scheduled-slot and address rows.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 16,
            color: BookingSummaryCard._brandBlue.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: BookingSummaryCard._ink.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Full-width tinted call button.
///
/// Tinted (brand-blue 12% bg + brand-blue label/icon) rather than solid
/// so it doesn't compete with the orchestrator's primary action button
/// which sits directly below this card. The orchestrator's primary
/// action is the solid brand-blue ElevatedButton language; this is the
/// "informational action" variant.
class _CallButton extends StatelessWidget {
  const _CallButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: BookingSummaryCard._brandBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_rounded,
                  size: 18,
                  color: BookingSummaryCard._brandBlue,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: BookingSummaryCard._brandBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

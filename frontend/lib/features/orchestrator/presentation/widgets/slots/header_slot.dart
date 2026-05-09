import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../customer/bookings/domain/entities/booking_ui_tone.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_orchestrator_role.dart';

/// Top-of-screen banner: status label + counterparty name + tone tint.
///
/// All copy comes from `booking.ui.statusLabel` and the participant's
/// display name on the opposite side of the role. Tone selection maps
/// to a [ColorScheme] role token — never to a hardcoded color.
class HeaderSlot extends StatelessWidget {
  const HeaderSlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final counterpartyName =
        booking.viewerRole == BookingOrchestratorRole.customer
            ? booking.technician.displayName
            : booking.customer.fullName;

    final tonePalette = _palette(colors, booking.ui.tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: tonePalette.background,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tonePalette.foreground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                booking.ui.statusLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tonePalette.foreground,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            counterpartyName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (booking.parentBookingId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Rescheduled from #${booking.parentBookingId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          // Forward-pointer to the child of a reschedule chain. Only
          // rendered when this booking is CANCELLED with a known child
          // — i.e., the user is sitting on a now-defunct original.
          // Without this surface they are stranded; the in-app
          // `bookingRescheduledNotifier` only fires for events that
          // arrive while this screen is mounted, so a stale FCM tap or
          // back-nav after the redirect lands here without a way out.
          if (booking.childBookingId != null &&
              booking.status == BookingStatus.cancelled) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: colors.primary,
                ),
                onPressed: () =>
                    GoRouter.of(context).push('/booking/${booking.childBookingId}'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text('Continued on #${booking.childBookingId}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _Palette _palette(ColorScheme colors, BookingUiTone tone) => switch (tone) {
        BookingUiTone.positive => _Palette(
            background: colors.primaryContainer.withValues(alpha: 0.45),
            foreground: colors.primary,
          ),
        BookingUiTone.warning => _Palette(
            background: colors.tertiaryContainer.withValues(alpha: 0.45),
            foreground: colors.tertiary,
          ),
        BookingUiTone.negative => _Palette(
            background: colors.errorContainer.withValues(alpha: 0.45),
            foreground: colors.error,
          ),
        BookingUiTone.info => _Palette(
            background: colors.secondaryContainer.withValues(alpha: 0.45),
            foreground: colors.secondary,
          ),
        BookingUiTone.neutral || BookingUiTone.unknown => _Palette(
            background: colors.surfaceContainerLow,
            foreground: colors.onSurfaceVariant,
          ),
      };
}

class _Palette {
  final Color background;
  final Color foreground;
  const _Palette({required this.background, required this.foreground});
}

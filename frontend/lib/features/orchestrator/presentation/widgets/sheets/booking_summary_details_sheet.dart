import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/map/map_provider.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_orchestrator_role.dart';
import '../_palette/orchestrator_palette.dart';
import '../feedback/orchestrator_snack.dart';

/// Bottom sheet that surfaces the booking details the slim
/// [BookingSummaryCard] strip can no longer afford to render inline.
///
/// **Why this exists.** Chunk L collapsed the always-on summary panel
/// from a ~276-px stack (avatar + service line + schedule + 3-line
/// address + full-width Call button) into a ~64-px strip — making
/// room for the map / quote / receipt to dominate the screen. The
/// fields that disappeared from the always-on view live here, one tap
/// away: schedule, full address, and the full-width labelled Call
/// button. The strip's icon-only call button is still the daily-driver
/// affordance; this sheet is the "I want details" form.
class BookingSummaryDetailsSheet extends ConsumerWidget {
  const BookingSummaryDetailsSheet({super.key, required this.booking});

  final BookingDetail booking;

  static Future<void> show(BuildContext context, BookingDetail booking) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => BookingSummaryDetailsSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCustomerView =
        booking.viewerRole == BookingOrchestratorRole.customer;
    final rawName = isCustomerView
        ? booking.technician.displayName
        : booking.customer.fullName;
    final counterpartyName = rawName.trim().isEmpty
        ? (isCustomerView ? 'Your technician' : 'Customer')
        : rawName;
    final counterpartyPhone = isCustomerView
        ? booking.technician.phoneNo
        : booking.customer.phoneNo;
    final subService = booking.subService;
    final serviceLine = subService == null
        ? booking.service.name
        : '${booking.service.name} · ${subService.name}';
    // Same gates as the strip: terminal bookings + customer-side AWAITING
    // suppress the call button (no live relationship yet).
    final isAwaitingCustomerView =
        isCustomerView && booking.status == BookingStatus.awaiting;
    final canCall = counterpartyPhone.isNotEmpty &&
        !booking.status.isTerminal &&
        !isAwaitingCustomerView;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                counterpartyName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: OrchestratorPalette.inkPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                serviceLine,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: OrchestratorPalette.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                icon: Icons.schedule_rounded,
                title: 'Scheduled',
                body: _formatSlot(
                  booking.scheduledStart,
                  booking.scheduledEnd,
                ),
              ),
              if (booking.address != null) ...[
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.location_on_rounded,
                  title: 'Address',
                  body: booking.address!.addressText,
                ),
              ],
              if (canCall) ...[
                const SizedBox(height: 20),
                _FullCallButton(
                  label: 'Call ${_firstName(counterpartyName)}',
                  onTap: () =>
                      _launchDialler(ref, context, counterpartyPhone),
                ),
              ] else
                const SizedBox(height: 8),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: OrchestratorPalette.brandPrimary,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
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

/// Two-line detail row: small icon + title (caption) + body (regular).
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 18,
            color: OrchestratorPalette.brandPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: OrchestratorPalette.inkTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: OrchestratorPalette.inkPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-width tinted Call button — same recipe as the pre-Chunk-L
/// `_CallButton` inside the summary card. Re-homed here because the
/// sheet recovers the labelled-CTA affordance; the slim strip uses an
/// icon-only button.
class _FullCallButton extends StatelessWidget {
  const _FullCallButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_rounded,
                  size: 18,
                  color: OrchestratorPalette.brandPrimary,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: OrchestratorPalette.brandPrimary,
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

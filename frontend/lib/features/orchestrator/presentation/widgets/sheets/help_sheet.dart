import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_ui_block.dart';
import '../../providers/booking_action_executor.dart';
import '../../providers/booking_detail_provider.dart';
import 'booking_action_pending_sheet.dart';
import 'cancel_reason_sheet.dart';

/// "Help" bottom sheet — the one place from which destructive / exit /
/// schedule-change actions are reachable on the orchestrator screen.
///
/// Replaces the older pattern where Cancel / Reschedule / "Tech didn't
/// show" rendered as peer TextButtons next to forward actions like
/// "Start inspection". That was a UX bug (per `feedback_cancel_vs_no_show`
/// memory): the happy-path action row should only contain forward verbs;
/// exit ramps and time-change verbs live one tap away under Help.
///
/// Contents (top-to-bottom, all conditional):
///   * **Reschedule booking** — only when the server emits a
///     `/reschedule/` action (AWAITING + CONFIRMED on customer side).
///     Today opens a "coming soon" pending sheet; session 6 swaps in a
///     real date/time picker.
///   * **Cancel booking** — opens [CancelReasonSheet] with a radio
///     picker; submits the selected destructive action (the server's
///     own `/cancel/` or `/tech-cancel/`) with no body (backend stamps
///     the phase-mapped reason itself; the picker is for UX clarity).
///   * **Contact support** — only when `booking.ui.showDisputeButton` is
///     True (server gates this to post-cash terminal states: COMPLETED
///     and COMPLETED_INSPECTION_ONLY). Today opens a placeholder
///     snackbar; Wed 2026-05-13 wires the AI chatbot dispute-intake
///     flow (narrative + photos + bank mini-form → `DisputeTicket` +
///     `RefundIntent`). See `project_chatbot_scope` memory.
///
/// Removed deliberately:
///   * FAQ — free-form info-giving was cut; static FAQ doesn't pull
///     enough weight to keep a row for. Reach customer-care through
///     Contact support post-completion or via the home help screen.
///   * "Open a dispute" — subsumed by Contact support (the chatbot
///     intake IS the dispute flow). Two entry points for one workflow
///     would just confuse the user.
class HelpSheet extends ConsumerWidget {
  const HelpSheet({super.key, required this.booking});

  final BookingDetail booking;

  static Future<void> show(BuildContext context, {required BookingDetail booking}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => HelpSheet(booking: booking),
    );
  }

  /// Cancel actions hide under Help, but the server still emits them as
  /// secondary actions on the UI block (style=destructive). We surface
  /// whichever destructive cancel is present; on cancelled/completed
  /// bookings the list is empty.
  BookingUiAction? _cancelAction() {
    for (final action in booking.ui.secondaryActions) {
      if (action.style == BookingUiActionStyle.destructive) return action;
    }
    return null;
  }

  /// Reschedule actions also hide under Help. Same wire contract — the
  /// server still emits it on `ui.secondaryActions`; SecondaryActionsSlot
  /// filters by endpoint suffix and the Help sheet surfaces it here.
  BookingUiAction? _rescheduleAction() {
    for (final action in booking.ui.secondaryActions) {
      if (action.endpoint.endsWith('/reschedule/')) return action;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cancel = _cancelAction();
    final reschedule = _rescheduleAction();
    final showDispute = booking.ui.showDisputeButton;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Need help?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (reschedule != null)
              _HelpRow(
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFF0051AE),
                title: reschedule.label,
                subtitle: 'Pick a new date and time',
                onTap: () {
                  Navigator.of(context).pop();
                  BookingActionPendingSheet.show(
                    context,
                    title: 'Rescheduling coming soon',
                    body:
                        "Rescheduling isn't available yet. To change the "
                        'time, cancel and rebook from the home screen.',
                  );
                },
              ),
            if (cancel != null) ...[
              if (reschedule != null) const Divider(height: 24),
              _HelpRow(
                icon: Icons.cancel_outlined,
                iconColor: theme.colorScheme.error,
                title: cancel.label,
                subtitle: 'Pick a reason on the next screen',
                onTap: () async {
                  // Capture container + navigator BEFORE popping the
                  // HelpSheet. After Navigator.pop the HelpSheet element
                  // is disposed and using its `ref` / `context` throws a
                  // StateError that falls into CancelReasonSheet's
                  // generic catch — the user sees "Could not cancel the
                  // booking." for every reason even though the POST
                  // would otherwise succeed.
                  final container = ProviderScope.containerOf(
                    context, listen: false,
                  );
                  final navigator = Navigator.of(context);
                  final rootContext = navigator.context;
                  navigator.pop();
                  final result = await CancelReasonSheet.show(
                    rootContext,
                    booking: booking,
                    action: cancel,
                    onConfirm: (body) => container
                        .read(bookingActionExecutorProvider)
                        .execute(cancel, body: body),
                  );
                  if (result == true) {
                    container.invalidate(bookingDetailProvider(booking.id));
                  }
                },
              ),
            ],
            // Contact support is post-completion only. Same gate as the
            // old "Open a dispute" row, since the chatbot IS the dispute
            // intake — two entry points for one workflow would just
            // confuse the customer.
            if (showDispute) ...[
              if (reschedule != null || cancel != null)
                const Divider(height: 24),
              _HelpRow(
                icon: Icons.support_agent_rounded,
                iconColor: const Color(0xFF0051AE),
                title: 'Contact support',
                subtitle: 'Report a problem with this job',
                onTap: () {
                  // Capture the router BEFORE popping the sheet —
                  // after pop, the sheet's element is disposed and
                  // looking up GoRouter through it would race.
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(
                    '/customer/bookings/${booking.id}/dispute-chat',
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

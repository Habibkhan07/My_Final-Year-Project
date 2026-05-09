import 'package:flutter/material.dart';

import '../../../domain/entities/booking_detail.dart';
import '../booking_orchestrator_action_button.dart';
import '../sheets/booking_action_pending_sheet.dart';

/// Renders [BookingDetail.ui.secondaryActions] as text buttons stacked
/// above the primary action.
///
/// Also surfaces the `show_dispute_button` UI flag — the server emits
/// this for IN_PROGRESS / COMPLETED / COMPLETED_INSPECTION_ONLY / NO_SHOW.
/// Today the button opens a "Dispute form coming soon" pending sheet
/// (the full intake form ships in session 6); this keeps the surface
/// reachable for QA without a concrete endpoint to POST to. When the
/// backend adds a `disputes/` action to `secondary_actions`, the action
/// button widget's classifier will pick that path up automatically and
/// this inline button becomes redundant — at which point we drop it.
class SecondaryActionsSlot extends StatelessWidget {
  const SecondaryActionsSlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final actions = booking.ui.secondaryActions;
    final showDispute = booking.ui.showDisputeButton;
    if (actions.isEmpty && !showDispute) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        // Positive runSpacing — negative values cause adjacent rows to
        // overlap visually when the wrap reflows (e.g., QUOTED has 3+
        // secondary actions on narrow phones). 4 keeps rows visually
        // separated without taking too much vertical real estate above
        // the primary action.
        runSpacing: 4,
        children: [
          for (final action in actions)
            BookingOrchestratorActionButton(
              action: action,
              booking: booking,
              isPrimary: false,
            ),
          if (showDispute) _OpenDisputeButton(),
        ],
      ),
    );
  }
}

class _OpenDisputeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: () {
        BookingActionPendingSheet.show(
          context,
          title: 'Dispute form coming soon',
          body:
              'The full dispute form (intake reason + optional photo upload) ships in session 6. The button is shown so you can verify the surface; submission is disabled.',
        );
      },
      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: const Text('Open dispute'),
    );
  }
}

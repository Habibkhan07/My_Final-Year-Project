import 'package:flutter/material.dart';

import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_ui_block.dart';
import '../booking_orchestrator_action_button.dart';

/// Renders [BookingDetail.ui.secondaryActions] as text buttons stacked
/// above the primary action.
///
/// **Filtered out (moved to [HelpSheet]):**
///   * **Destructive actions** — Cancel / Tech-cancel. Per
///     `feedback_cancel_vs_no_show.md`, exits live behind Help so the
///     happy-path row only contains forward verbs.
///   * **`/reschedule/`** — same rationale; reschedule is a time-change
///     verb, not a forward step of the booking. It's a Help affordance.
///   * **Dispute** — was previously inline via `show_dispute_button`;
///     also moved to Help (`feedback_dispute_visibility.md`).
///
/// **Face-to-face quote negotiation (post-arrival model):**
///
/// In this market customer + tech are physically together from ARRIVED
/// onward. On QUOTED the customer reviews the line items with the tech
/// standing right there — there is no remote "Ask for a revision"
/// workflow; the customer verbally bargains ("yaar, isko kuch kam
/// karo") and the tap below is just the signal that flips the quote
/// back so the tech can rebuild it on their own device.
///
/// The wire's "Ask for a revision" carries ticket-style framing of a
/// remote workflow, so when the endpoint is `/request-revision/` we
/// override the label to "Negotiate price" — a hint that this is an
/// in-person ask, not a support ticket. Wire contract is otherwise
/// unchanged; the endpoint still POSTs `/request-revision/`.
///
/// **Visibility is server-driven** (Dumb UI). The backend's
/// `_customer_quoted()` selector iterates the active quote's line
/// items and omits the request-revision action entirely when every
/// line item references a fixed-price (catalog) sub-service —
/// because in that case there's no labor band the tech can lower
/// within, so there is nothing to negotiate. We don't reproduce that
/// check here; we trust the wire.
class SecondaryActionsSlot extends StatelessWidget {
  const SecondaryActionsSlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final forwardActions = <BookingUiAction>[];
    for (final action in booking.ui.secondaryActions) {
      // Destructive-style actions are normally filtered out of the
      // happy-path row (cancels live behind Help). The exception is
      // /decline/: the backend tags `decline_quote` and `decline upsell`
      // as destructive because they have material financial impact
      // (Rs. 500 inspection fee, work refused), but they ARE the
      // customer's expected response to the QUOTED screen — without
      // surfacing decline the customer has no way to refuse a quote.
      // Cancel/tech-cancel remain hidden (they exit the booking, not
      // forward verbs).
      final isDecline = action.endpoint.endsWith('/decline/');
      if (action.style == BookingUiActionStyle.destructive && !isDecline) {
        continue;
      }
      if (action.endpoint.endsWith('/reschedule/')) continue;
      if (action.endpoint.endsWith('/request-revision/')) {
        forwardActions.add(action.copyWith(label: 'Negotiate price'));
        continue;
      }
      forwardActions.add(action);
    }
    if (forwardActions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        // Positive runSpacing — negative values cause adjacent rows to
        // overlap visually when the wrap reflows (e.g., the tech's
        // IN_PROGRESS view shows "Add upsell" alongside any future
        // upsell-counterpart action). 4 keeps rows visually separated
        // without taking too much vertical real estate above the
        // primary action.
        runSpacing: 4,
        children: [
          for (final action in forwardActions)
            BookingOrchestratorActionButton(
              action: action,
              booking: booking,
              isPrimary: false,
            ),
        ],
      ),
    );
  }
}

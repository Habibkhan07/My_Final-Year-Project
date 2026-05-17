import 'package:flutter/material.dart';

import '_palette/orchestrator_palette.dart';
import 'meeting_countdown_button.dart';

/// Pinned bottom card on customer-side ARRIVED — fuses the "tech has
/// arrived" message AND the countdown CTA into ONE surface.
///
/// **Why this exists.** Previously the arrival message lived in the body
/// (above the map) and the countdown button lived in the action bar
/// (below the map). With the map between them, the customer's eye had
/// to bounce: read message → look at map → drop down to tap → look back
/// up to confirm they understood. Merging them lets the eye land on the
/// card once and see both the message and the action together.
///
/// **Where this renders.** Inside [PrimaryActionSlot] on
/// customer-arriving. It replaces the bare [MeetingCountdownButton] that
/// used to be the only primary-action element for this branch. The
/// surrounding [OrchestratorActionBar] still provides the lifted-action
/// surface treatment (top border + soft top shadow + safe-area bottom
/// inset) — this card sits on top of it as a self-contained brand-blue
/// surface.
///
/// **Pinned, not scrollable.** The map and any peek-at-the-tech-card
/// scrolling happen above this card; the card itself stays anchored at
/// the bottom of the screen, so the time-pressure CTA can never drift
/// off-screen with scroll. That is the whole reason the description
/// merged INTO this card instead of staying inside the body — if the
/// description were scrollable, the user could lose sight of the
/// countdown by scrolling down to peek at the tech card.
///
/// **Visual.**
///   * Surface — white, 18px radius, brand-blue 10% hairline border,
///     soft brand drop-shadow. Sits in the same surface family as the
///     [BookingSummaryCard] and the body [BodyShell].
///   * Header row — a 40px brand-blue gradient badge with the
///     `person_pin_circle` icon (visually anchors "your technician is
///     here at this spot"), then a two-tier text block: the
///     server-resolved [bodyText] in bold ink, and a fixed UI microcopy
///     line below explaining the action.
///   * Action — the [MeetingCountdownButton] sits as the bottom row of
///     the card. The button's own gradient + drop-shadow do the heavy
///     visual lifting; the card is the calm container.
///
/// **Dumb-UI principle.** The title comes from server-resolved
/// `booking.ui.bodyText`; only the helper microcopy
/// ("Tap below to head out and meet them.") is a fixed UI affordance
/// because it describes the verb of the button rather than booking
/// state.
class ArrivalActionCard extends StatelessWidget {
  const ArrivalActionCard({
    super.key,
    required this.bodyText,
    required this.arrivedAt,
    required this.actionLabel,
    required this.onTap,
    required this.busy,
  });

  /// Server-resolved arrival message, typically along the lines of
  /// "Your technician has arrived at your location." Falls back to a
  /// generic message when empty.
  final String bodyText;

  /// Server-stamped `arrived_at` timestamp. Drives the 5-minute
  /// countdown inside the button. Null is defensive — the backend
  /// always stamps this before transitioning to ARRIVED.
  final DateTime? arrivedAt;

  /// Server-resolved action verb (e.g. "I'm coming out"). The countdown
  /// button uses this until expiry, then switches to its own expired
  /// label.
  final String actionLabel;

  /// Tap handler — fires the customer-arriving endpoint via the
  /// `BookingActionExecutor`. Wired by [_CustomerArrivingPrimaryAction].
  final VoidCallback onTap;

  /// In-flight indicator — replaces the countdown button label with a
  /// spinner. Driven by the parent's `_busy` state during the network
  /// round-trip.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = bodyText.isEmpty
        ? 'Your technician has arrived'
        : bodyText;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.10),
        ),
        boxShadow: OrchestratorPalette.brandSoftShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _ArrivalBadge(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: OrchestratorPalette.inkPrimary,
                          height: 1.2,
                        ),
                        // 3 lines absorbs the longer server-resolved
                        // arrival messages (e.g. "Test Technician is
                        // parked at your address. Please walk out to
                        // meet them.") without cutting mid-word. The
                        // map above adapts to whatever height this
                        // card takes.
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap below to head out and meet them.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: OrchestratorPalette.inkSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            MeetingCountdownButton(
              arrivedAt: arrivedAt,
              label: actionLabel,
              expiredLabel: 'Come out — tech is waiting',
              icon: Icons.directions_walk_rounded,
              onTap: onTap,
              busy: busy,
            ),
          ],
        ),
      ),
    );
  }
}

/// 40px brand-blue gradient badge with `person_pin_circle` glyph.
///
/// Why a gradient badge instead of a flat colored circle: the rest of
/// the orchestrator's brand-blue surfaces (action button, countdown,
/// hero pill) are lit-from-top gradients. Matching the language here
/// keeps the screen reading as one surface family. The drop shadow at
/// 32% brand-blue gives the badge a small physical lift — anchors the
/// eye on the start of the message row.
class _ArrivalBadge extends StatelessWidget {
  const _ArrivalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OrchestratorPalette.brandPrimaryDeep,
            OrchestratorPalette.brandPrimary,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_pin_circle_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

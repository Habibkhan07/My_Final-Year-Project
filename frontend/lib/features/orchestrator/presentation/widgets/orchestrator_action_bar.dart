import 'package:flutter/material.dart';

import '../../domain/entities/booking_detail.dart';
import 'slots/primary_action_slot.dart';
import 'slots/secondary_actions_slot.dart';

/// Lifted bottom action area.
///
/// Wraps [SecondaryActionsSlot] + [PrimaryActionSlot] in a surface-coloured
/// container with a thin top border and a soft top shadow — visually
/// separates the always-on action region from the scrollable body above,
/// even though it lives in the same column flow.
///
/// **Why the lift.** Without it, the primary CTA blends into the body and
/// the user has to hunt for the next step on busy statuses (QUOTED,
/// CONFIRMED). The shadow lifts the action area above the body in a way
/// that reads as "this is your next action."
///
/// **Safe area.** Honors `MediaQuery.viewPadding.bottom` so the primary
/// button sits clear of gesture-nav bars on modern Android devices. The
/// screen wraps the body in a SafeArea — we explicitly disable that
/// padding here and restore the bottom inset ourselves so the surface
/// colour reaches the system gesture region instead of revealing the
/// page background.
class OrchestratorActionBar extends StatelessWidget {
  const OrchestratorActionBar({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecondaryActionsSlot(booking: booking),
            PrimaryActionSlot(booking: booking),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../domain/entities/booking_detail.dart';
import '../booking_orchestrator_action_button.dart';

/// Renders [BookingDetail.ui.primaryAction] at the bottom of the screen.
/// Hidden when the action is null (server-side decision: this user/role
/// has no actionable verb at this status).
class PrimaryActionSlot extends StatelessWidget {
  const PrimaryActionSlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final action = booking.ui.primaryAction;
    if (action == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: BookingOrchestratorActionButton(
        action: action,
        booking: booking,
        isPrimary: true,
      ),
    );
  }
}

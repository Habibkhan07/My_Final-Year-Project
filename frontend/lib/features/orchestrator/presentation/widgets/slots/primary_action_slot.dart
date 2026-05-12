import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../technician/dashboard/presentation/notifiers/technician_dashboard_notifier.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_orchestrator_role.dart';
import '../../../domain/entities/booking_ui_block.dart';
import '../../providers/booking_action_executor.dart';
import '../../providers/booking_detail_provider.dart';
import '../arrival_action_card.dart';
import '../booking_orchestrator_action_button.dart';
import '../feedback/orchestrator_snack.dart';

/// Renders [BookingDetail.ui.primaryAction] at the bottom of the screen.
/// Hidden when the action is null (server-side decision: this user/role
/// has no actionable verb at this status).
///
/// **Special cases:**
///
/// 1. Customer's "I'm coming out" on ARRIVED → [ArrivalActionCard]
///    (fuses server-resolved arrival message + countdown CTA into one
///    pinned surface so the customer's eye doesn't split across map and
///    action bar). Detection on endpoint suffix `/customer-arriving/`.
///
/// 2. **Tech viewer on CONFIRMED for the dashboard's up-next job**.
///    Suppress the "I'm on my way" button here because the body's
///    `TechNavigationPanel` already owns that verb (its Start Navigation
///    button POSTs `/en-route/` AND launches Maps in one tap). Showing
///    both would mean two buttons for the same verb on the same screen.
///    The body's panel is the single source of truth; this slot bows out.
class PrimaryActionSlot extends ConsumerWidget {
  const PrimaryActionSlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = booking.ui.primaryAction;
    if (action == null) return const SizedBox.shrink();

    if (action.endpoint.endsWith('/customer-arriving/') &&
        booking.viewerRole == BookingOrchestratorRole.customer) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _CustomerArrivingPrimaryAction(
          booking: booking,
          action: action,
        ),
      );
    }

    // Tech + CONFIRMED + this booking IS the dashboard's up-next → the
    // body renders TechNavigationPanel which owns the en-route verb.
    // Bow out so the verb isn't duplicated. Non-up-next CONFIRMED jobs
    // keep this button as the only way to mark themselves en route.
    if (booking.status == BookingStatus.confirmed &&
        booking.viewerRole == BookingOrchestratorRole.technician) {
      final dash = ref.watch(technicianDashboardProvider);
      final isUpNext = dash.value?.dashboard.upNextJob?.jobId == booking.id;
      if (isUpNext) return const SizedBox.shrink();
    }

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

/// Bridges [ArrivalActionCard] (which embeds [MeetingCountdownButton])
/// to the standard `BookingActionExecutor` +
/// `bookingDetailProvider` invalidation path.
///
/// Mirrors the error handling in `BookingOrchestratorActionButton`:
/// SocketException → "no connection" snack, HttpFailure → server
/// message, anything else → generic snack. On success we invalidate the
/// detail provider; the rebuild drops this widget (post-ack the
/// backend no longer emits `/customer-arriving/` as primary_action).
class _CustomerArrivingPrimaryAction extends ConsumerStatefulWidget {
  const _CustomerArrivingPrimaryAction({
    required this.booking,
    required this.action,
  });

  final BookingDetail booking;
  final BookingUiAction action;

  @override
  ConsumerState<_CustomerArrivingPrimaryAction> createState() =>
      _CustomerArrivingPrimaryActionState();
}

class _CustomerArrivingPrimaryActionState
    extends ConsumerState<_CustomerArrivingPrimaryAction> {
  bool _busy = false;

  Future<void> _onTap() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(bookingActionExecutorProvider)
          .execute(widget.action, body: null);
      if (mounted) {
        ref.invalidate(bookingDetailProvider(widget.booking.id));
      }
    } on SocketException {
      _snack('No connection. Try again when online.');
    } on HttpFailure catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not complete action.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    OrchestratorSnack.error(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return ArrivalActionCard(
      bodyText: widget.booking.ui.bodyText,
      arrivedAt: widget.booking.phaseTimestamps.arrivedAt,
      actionLabel: widget.action.label,
      onTap: _onTap,
      busy: _busy,
    );
  }
}

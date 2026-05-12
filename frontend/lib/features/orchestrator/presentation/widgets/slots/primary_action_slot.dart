import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/common/errors/http_failure.dart';
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
/// **Special case** — the customer's "I'm coming out" action on ARRIVED
/// renders as [ArrivalActionCard] instead of the generic
/// [BookingOrchestratorActionButton]. The card fuses the server-resolved
/// arrival message AND the countdown CTA into ONE pinned surface, so
/// the customer's eye lands on the map (above) then drops to ONE place
/// for message + action — no split attention across the map. Detection
/// is on endpoint suffix (`/customer-arriving/`) so the wire contract
/// is unchanged.
class PrimaryActionSlot extends StatelessWidget {
  const PrimaryActionSlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
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

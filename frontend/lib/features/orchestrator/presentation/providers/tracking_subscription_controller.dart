// Customer-side WS upstream subscription controller for `tech_gps`.
//
// Lifecycle:
//   • Watches `bookingDetailProvider(jobId)` — when status enters
//     {EN_ROUTE, ARRIVED} and viewerRole == customer, sends
//     `{action: 'subscribe_tracking', booking_id: jobId}` upstream.
//   • When status leaves that window (or screen pops) sends
//     `{action: 'unsubscribe_tracking', booking_id: jobId}`.
//   • Listens to `wsConnectionProvider.connectionEvents` (broadcast
//     Stream) — replays `subscribe_tracking` on every WsConnected
//     while we're in the should-be-subscribed window. Backend's
//     subscribe handler is idempotent (per-channel set membership).
//
// Why a Stream, not a Riverpod listener on connection status:
// Riverpod debounces equal-value writes; a fast disconnect→reconnect
// could be coalesced into a single observation, missing the
// transition. The broadcast Stream fires once per WsConnected event,
// preserving the replay opportunity.
//
// SECURITY: subscription is gated on viewerRole == customer; backend
// `_can_subscribe` enforces booking-participant + non-terminal status
// at the consumer layer regardless. Defence-in-depth.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import '../../../customer/bookings/domain/entities/booking_status.dart';
import '../../domain/entities/booking_orchestrator_role.dart';
import 'booking_detail_provider.dart';

part 'tracking_subscription_controller.g.dart';

/// keepAlive: false — owned by the orchestrator screen lifecycle.
/// The screen `ref.watch`-es this provider in `build()`; popping the
/// screen disposes the provider, which sends a final unsubscribe.
@Riverpod(keepAlive: false)
class TrackingSubscriptionController extends _$TrackingSubscriptionController {
  static const _kSubscribableStatuses = <BookingStatus>{
    BookingStatus.enRoute,
    BookingStatus.arrived,
  };

  bool _subscribed = false;
  StreamSubscription<WsConnectionEvent>? _wsEventsSub;

  @override
  void build(int jobId) {
    final ws = ref.read(wsConnectionProvider.notifier);

    // (1) status × role gate — drives subscribe/unsubscribe transitions.
    ref.listen(bookingDetailProvider(jobId), (previous, next) {
      next.whenData((booking) {
        final shouldSubscribe =
            booking.viewerRole == BookingOrchestratorRole.customer &&
            _kSubscribableStatuses.contains(booking.status);

        if (shouldSubscribe && !_subscribed) {
          _send(ws, 'subscribe_tracking', jobId);
          _subscribed = true;
        } else if (!shouldSubscribe && _subscribed) {
          _send(ws, 'unsubscribe_tracking', jobId);
          _subscribed = false;
        }
      });
    });

    // (2) WS reconnect re-subscribe (audit P1-06). Listens to the
    // broadcast Stream; ignores WsDisconnected (the next reconnect
    // will re-subscribe).
    _wsEventsSub = ws.connectionEvents.listen((event) {
      if (event is WsConnected && _subscribed) {
        _send(ws, 'subscribe_tracking', jobId);
      }
    });

    ref.onDispose(() {
      _wsEventsSub?.cancel();
      _wsEventsSub = null;
      if (_subscribed) {
        _send(ws, 'unsubscribe_tracking', jobId);
        _subscribed = false;
      }
    });
  }

  static void _send(WsConnectionNotifier ws, String action, int jobId) {
    ws.sendUpstream({'action': action, 'booking_id': jobId});
  }
}

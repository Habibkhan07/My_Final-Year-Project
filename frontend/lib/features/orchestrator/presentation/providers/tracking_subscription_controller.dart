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
import '../../domain/entities/booking_detail.dart';
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

  /// Audit S-12 (Batch F): semantically this is "intent to be
  /// subscribed", NOT "currently subscribed on the wire." A
  /// `_send(subscribe_tracking)` while the WS is disconnected is a
  /// no-op (sendUpstream silently drops on null channel — audit R-12).
  /// We still flip `_subscribed = true` so the connectionEvents
  /// listener replays the subscribe on the next WsConnected. If we
  /// gated the flag on connection state, the replay would never fire
  /// and a customer who opened the orchestrator screen during a
  /// reconnect window would never receive frames.
  bool _subscribed = false;
  StreamSubscription<WsConnectionEvent>? _wsEventsSub;

  @override
  void build(int jobId) {
    // Audit R-16 (Batch F): caching the notifier instance at build()
    // time is safe in this controller because `wsConnectionProvider`
    // is `keepAlive: true` — the same notifier instance survives
    // every connect/disconnect/reconnect cycle within a session. The
    // only path that would invalidate this reference is a logout,
    // which pops the orchestrator screen (disposing this controller
    // before the cached `ws` could be re-used). Verified by the
    // dispose-when-not-subscribed regression test.
    final ws = ref.read(wsConnectionProvider.notifier);

    // (1) status × role gate — drives subscribe/unsubscribe transitions.
    //
    // `fireImmediately: true` is load-bearing: a plain `ref.listen` only
    // fires on future *transitions*. If `bookingDetailProvider` is already
    // resolved when this controller is built (e.g. the screen rebuilt and
    // the detail provider had cached data, or a subsequent widget mounts
    // this controller after the detail resolved), the listener would
    // never see the existing AsyncData and the customer would silently
    // never subscribe to tracking. Fire-immediately evaluates the gate
    // against the current value the moment the listener is installed.
    //
    // Audit R-18 (Batch B): we deliberately use `whenData` only — i.e.
    // an AsyncError on `bookingDetailProvider` does NOT unsubscribe.
    // Transient backend 500s would otherwise drop the customer's
    // tech_gps subscription and surface "tech offline" until the
    // detail provider recovered. Staying subscribed during error
    // costs nothing (WS subgroup membership is server-side state)
    // and lets the next AsyncData seamlessly resume frames. If the
    // booking genuinely terminates, the next AsyncData fires
    // _evaluate with a non-tracking status and unsubscribes cleanly.
    ref.listen(
      bookingDetailProvider(jobId),
      (previous, next) => next.whenData((b) => _evaluate(b, ws, jobId)),
      fireImmediately: true,
    );

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
        // Audit R-13 (Batch F): this is BEST-EFFORT. If the WS is
        // currently disconnected (logout cascade often disposes the
        // socket BEFORE popping the orchestrator screen), this
        // upstream message will silently drop — sendUpstream returns
        // immediately on a null channel. That's acceptable because:
        //   • The backend's `tracking_job_<id>` group membership is
        //     auto-cleaned when the underlying channel disconnects.
        //   • An orphan membership only wastes a Redis-backed
        //     subscription slot until the channel layer reaps it.
        // So a missing unsubscribe is at worst a brief Redis cleanup
        // delay, never a leak. If you see this comment because you
        // need the unsubscribe to be guaranteed (e.g. backend rate
        // limits per-channel-group memberships), the proper fix is
        // an authenticated REST `DELETE /bookings/<id>/tracking/`
        // endpoint — not WS-side at all.
        _send(ws, 'unsubscribe_tracking', jobId);
        _subscribed = false;
      }
    });
  }

  /// Pure gate function: evaluates whether `booking` should be tracked
  /// and emits the matching subscribe / unsubscribe upstream message.
  /// Idempotent against `_subscribed` — calling on the same data twice
  /// is a no-op for the second call.
  ///
  /// Both viewer roles subscribe. The customer needs the stream to render
  /// the tech's live marker; the tech also needs it so their own
  /// `LiveTrackingMap` populates (the foreground broadcaster pushes
  /// frames out — they don't loop back locally, so the only way for the
  /// tech's UI to see the marker is to receive it back through the
  /// shared `tracking_job_<id>` group). The backend consumer authorises
  /// on booking-participant + non-terminal status, so allowing the tech
  /// here doesn't widen the security surface — that gate is server-side.
  void _evaluate(BookingDetail booking, WsConnectionNotifier ws, int jobId) {
    final shouldSubscribe = _kSubscribableStatuses.contains(booking.status);

    if (shouldSubscribe && !_subscribed) {
      _send(ws, 'subscribe_tracking', jobId);
      _subscribed = true;
    } else if (!shouldSubscribe && _subscribed) {
      _send(ws, 'unsubscribe_tracking', jobId);
      _subscribed = false;
    }
  }

  static void _send(WsConnectionNotifier ws, String action, int jobId) {
    ws.sendUpstream({'action': action, 'booking_id': jobId});
  }
}

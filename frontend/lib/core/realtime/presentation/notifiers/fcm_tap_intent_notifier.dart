import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/system_event_entity.dart';

part 'fcm_tap_intent_notifier.g.dart';

/// Single-slot channel for user-initiated FCM notification taps.
///
/// **Why this exists separately from [SystemEventNotifier]:**
/// `SystemEventNotifier` is the funnel for **automatic** event delivery
/// (WS push, FCM foreground arrival, REST sync replay, BG-isolate queue
/// drain). It dedups, filters by expiry/recipient, and rejects out-of-order
/// frames — protective behavior that's correct for *automatic* ingestion.
///
/// A user-initiated tap on a tray notification is fundamentally different:
/// the user has explicitly asked to be routed to that booking. Letting it
/// pass through `SystemEventNotifier` would risk:
///   * being silently dropped on dedup (same event already seen via WS),
///   * being silently dropped on expiry (notification sat in tray > SLA),
///   * being routed via the banner path with a "View" button (forcing a
///     second tap the user already implicitly made).
///
/// So tap-intent gets its own dedicated channel: one slot, set on tap,
/// listened to by `AppLifecycleOrchestrator`, consumed (cleared) after
/// routing so a stale value doesn't replay on re-mount.
///
/// Both entry paths (`onMessageOpenedApp` listener + `getInitialMessage`
/// on cold-start) feed this notifier from `FCMHandler`.
///
/// `keepAlive: true` because tap-intent can arrive at app boot (cold-start
/// from terminated state via `getInitialMessage`) BEFORE the orchestrator
/// is mounted; the value must survive until the listener subscribes.
@Riverpod(keepAlive: true)
class FcmTapIntentNotifier extends _$FcmTapIntentNotifier {
  @override
  SystemEventEntity? build() => null;

  /// Records a user tap on a tray FCM notification. Idempotent on identical
  /// repeat calls (`==` on `SystemEventEntity` compares by id) — though a
  /// duplicate tap is itself a no-op event from the orchestrator's view.
  void setTapIntent(SystemEventEntity event) {
    state = event;
  }

  /// Clears the slot. Called by the orchestrator after routing so the
  /// listener doesn't re-fire on subsequent unrelated state changes.
  void clear() {
    state = null;
  }
}

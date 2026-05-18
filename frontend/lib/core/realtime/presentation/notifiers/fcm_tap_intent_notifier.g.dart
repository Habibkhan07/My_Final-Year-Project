// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_tap_intent_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(FcmTapIntentNotifier)
final fcmTapIntentProvider = FcmTapIntentNotifierProvider._();

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
final class FcmTapIntentNotifierProvider
    extends $NotifierProvider<FcmTapIntentNotifier, SystemEventEntity?> {
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
  FcmTapIntentNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fcmTapIntentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fcmTapIntentNotifierHash();

  @$internal
  @override
  FcmTapIntentNotifier create() => FcmTapIntentNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SystemEventEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemEventEntity?>(value),
    );
  }
}

String _$fcmTapIntentNotifierHash() =>
    r'f4656a040fff121c941985499c61d131f40d83e6';

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

abstract class _$FcmTapIntentNotifier extends $Notifier<SystemEventEntity?> {
  SystemEventEntity? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SystemEventEntity?, SystemEventEntity?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SystemEventEntity?, SystemEventEntity?>,
              SystemEventEntity?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

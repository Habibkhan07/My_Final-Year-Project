// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_job_queue_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds every `job_new_request` event observed since wake-up.
///
/// `keepAlive: true` is load-bearing: the notifier MUST be subscribed to
/// `systemEventProvider` BEFORE any event arrives. The `AppLifecycleOrchestrator`
/// performs an eager `ref.read(...)` in `bootAfterAuth` for exactly this reason —
/// otherwise an event landing during the WS connect cascade would be missed
/// because `ref.listen` only fires on transitions that occur after subscription.
///
/// Dedup belt-and-suspenders: `SystemEventNotifier` already dedupes by event id
/// (so the same broadcast arriving via WS + FCM is filtered upstream); the
/// per-`jobId` guard here covers the unlikely case of a re-broadcast with a
/// fresh event id for the same booking.

@ProviderFor(IncomingJobQueueNotifier)
final incomingJobQueueProvider = IncomingJobQueueNotifierProvider._();

/// Holds every `job_new_request` event observed since wake-up.
///
/// `keepAlive: true` is load-bearing: the notifier MUST be subscribed to
/// `systemEventProvider` BEFORE any event arrives. The `AppLifecycleOrchestrator`
/// performs an eager `ref.read(...)` in `bootAfterAuth` for exactly this reason —
/// otherwise an event landing during the WS connect cascade would be missed
/// because `ref.listen` only fires on transitions that occur after subscription.
///
/// Dedup belt-and-suspenders: `SystemEventNotifier` already dedupes by event id
/// (so the same broadcast arriving via WS + FCM is filtered upstream); the
/// per-`jobId` guard here covers the unlikely case of a re-broadcast with a
/// fresh event id for the same booking.
final class IncomingJobQueueNotifierProvider
    extends $NotifierProvider<IncomingJobQueueNotifier, IncomingJobQueueState> {
  /// Holds every `job_new_request` event observed since wake-up.
  ///
  /// `keepAlive: true` is load-bearing: the notifier MUST be subscribed to
  /// `systemEventProvider` BEFORE any event arrives. The `AppLifecycleOrchestrator`
  /// performs an eager `ref.read(...)` in `bootAfterAuth` for exactly this reason —
  /// otherwise an event landing during the WS connect cascade would be missed
  /// because `ref.listen` only fires on transitions that occur after subscription.
  ///
  /// Dedup belt-and-suspenders: `SystemEventNotifier` already dedupes by event id
  /// (so the same broadcast arriving via WS + FCM is filtered upstream); the
  /// per-`jobId` guard here covers the unlikely case of a re-broadcast with a
  /// fresh event id for the same booking.
  IncomingJobQueueNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingJobQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingJobQueueNotifierHash();

  @$internal
  @override
  IncomingJobQueueNotifier create() => IncomingJobQueueNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IncomingJobQueueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IncomingJobQueueState>(value),
    );
  }
}

String _$incomingJobQueueNotifierHash() =>
    r'a46e56573ff8dc183367c18c3418629016789519';

/// Holds every `job_new_request` event observed since wake-up.
///
/// `keepAlive: true` is load-bearing: the notifier MUST be subscribed to
/// `systemEventProvider` BEFORE any event arrives. The `AppLifecycleOrchestrator`
/// performs an eager `ref.read(...)` in `bootAfterAuth` for exactly this reason —
/// otherwise an event landing during the WS connect cascade would be missed
/// because `ref.listen` only fires on transitions that occur after subscription.
///
/// Dedup belt-and-suspenders: `SystemEventNotifier` already dedupes by event id
/// (so the same broadcast arriving via WS + FCM is filtered upstream); the
/// per-`jobId` guard here covers the unlikely case of a re-broadcast with a
/// fresh event id for the same booking.

abstract class _$IncomingJobQueueNotifier
    extends $Notifier<IncomingJobQueueState> {
  IncomingJobQueueState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<IncomingJobQueueState, IncomingJobQueueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IncomingJobQueueState, IncomingJobQueueState>,
              IncomingJobQueueState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

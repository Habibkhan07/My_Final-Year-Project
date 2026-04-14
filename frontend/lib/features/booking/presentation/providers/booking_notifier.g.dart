// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the instant booking creation mutation.
///
/// **State**: starts as [AsyncData(null)] — no booking attempted yet.
/// Transitions: null → AsyncLoading → AsyncData(entity) or AsyncError.
///
/// **Tier 3 (crash recovery)**: on [AsyncData], the UI layer must immediately
/// write [CreatedBookingEntity.bookingId] to SharedPreferences so the Active
/// Job Screen can be restored after a crash. This is intentionally a UI
/// responsibility — the notifier only owns the network result.
///
/// **409 UX**: when state is [AsyncError] with [BookingSlotUnavailableFailure],
/// the UI must pop back to the availability screen so the customer can
/// pick a different slot.

@ProviderFor(InstantBookingNotifier)
final instantBookingProvider = InstantBookingNotifierProvider._();

/// Manages the instant booking creation mutation.
///
/// **State**: starts as [AsyncData(null)] — no booking attempted yet.
/// Transitions: null → AsyncLoading → AsyncData(entity) or AsyncError.
///
/// **Tier 3 (crash recovery)**: on [AsyncData], the UI layer must immediately
/// write [CreatedBookingEntity.bookingId] to SharedPreferences so the Active
/// Job Screen can be restored after a crash. This is intentionally a UI
/// responsibility — the notifier only owns the network result.
///
/// **409 UX**: when state is [AsyncError] with [BookingSlotUnavailableFailure],
/// the UI must pop back to the availability screen so the customer can
/// pick a different slot.
final class InstantBookingNotifierProvider
    extends
        $NotifierProvider<
          InstantBookingNotifier,
          AsyncValue<CreatedBookingEntity?>
        > {
  /// Manages the instant booking creation mutation.
  ///
  /// **State**: starts as [AsyncData(null)] — no booking attempted yet.
  /// Transitions: null → AsyncLoading → AsyncData(entity) or AsyncError.
  ///
  /// **Tier 3 (crash recovery)**: on [AsyncData], the UI layer must immediately
  /// write [CreatedBookingEntity.bookingId] to SharedPreferences so the Active
  /// Job Screen can be restored after a crash. This is intentionally a UI
  /// responsibility — the notifier only owns the network result.
  ///
  /// **409 UX**: when state is [AsyncError] with [BookingSlotUnavailableFailure],
  /// the UI must pop back to the availability screen so the customer can
  /// pick a different slot.
  InstantBookingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'instantBookingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$instantBookingNotifierHash();

  @$internal
  @override
  InstantBookingNotifier create() => InstantBookingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<CreatedBookingEntity?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<CreatedBookingEntity?>>(
        value,
      ),
    );
  }
}

String _$instantBookingNotifierHash() =>
    r'99d4a980b96e0f7ebc0559894dc7e0495179f58e';

/// Manages the instant booking creation mutation.
///
/// **State**: starts as [AsyncData(null)] — no booking attempted yet.
/// Transitions: null → AsyncLoading → AsyncData(entity) or AsyncError.
///
/// **Tier 3 (crash recovery)**: on [AsyncData], the UI layer must immediately
/// write [CreatedBookingEntity.bookingId] to SharedPreferences so the Active
/// Job Screen can be restored after a crash. This is intentionally a UI
/// responsibility — the notifier only owns the network result.
///
/// **409 UX**: when state is [AsyncError] with [BookingSlotUnavailableFailure],
/// the UI must pop back to the availability screen so the customer can
/// pick a different slot.

abstract class _$InstantBookingNotifier
    extends $Notifier<AsyncValue<CreatedBookingEntity?>> {
  AsyncValue<CreatedBookingEntity?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CreatedBookingEntity?>,
              AsyncValue<CreatedBookingEntity?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CreatedBookingEntity?>,
                AsyncValue<CreatedBookingEntity?>
              >,
              AsyncValue<CreatedBookingEntity?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

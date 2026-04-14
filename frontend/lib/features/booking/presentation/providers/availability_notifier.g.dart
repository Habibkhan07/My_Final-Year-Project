// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages available time slots for a technician on a specific date.
///
/// **Family design**: parameterised by [technicianId] + [date] so that changing
/// the selected date in the UI simply watches a new provider instance — no
/// explicit refresh method needed. Stale instances are auto-disposed.
///
/// **Intent**: [selectSlot] only mutates the in-memory [selectedSlot] — it does
/// not re-fetch. The selected slot's [isoStart]/[isoEnd] are passed verbatim
/// to [InstantBookingNotifier.book] — no timezone conversion.

@ProviderFor(AvailabilityNotifier)
final availabilityProvider = AvailabilityNotifierFamily._();

/// Manages available time slots for a technician on a specific date.
///
/// **Family design**: parameterised by [technicianId] + [date] so that changing
/// the selected date in the UI simply watches a new provider instance — no
/// explicit refresh method needed. Stale instances are auto-disposed.
///
/// **Intent**: [selectSlot] only mutates the in-memory [selectedSlot] — it does
/// not re-fetch. The selected slot's [isoStart]/[isoEnd] are passed verbatim
/// to [InstantBookingNotifier.book] — no timezone conversion.
final class AvailabilityNotifierProvider
    extends $AsyncNotifierProvider<AvailabilityNotifier, AvailabilityState> {
  /// Manages available time slots for a technician on a specific date.
  ///
  /// **Family design**: parameterised by [technicianId] + [date] so that changing
  /// the selected date in the UI simply watches a new provider instance — no
  /// explicit refresh method needed. Stale instances are auto-disposed.
  ///
  /// **Intent**: [selectSlot] only mutates the in-memory [selectedSlot] — it does
  /// not re-fetch. The selected slot's [isoStart]/[isoEnd] are passed verbatim
  /// to [InstantBookingNotifier.book] — no timezone conversion.
  AvailabilityNotifierProvider._({
    required AvailabilityNotifierFamily super.from,
    required ({
      int technicianId,
      String date,
      int? serviceId,
      int? subServiceId,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'availabilityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$availabilityNotifierHash();

  @override
  String toString() {
    return r'availabilityProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AvailabilityNotifier create() => AvailabilityNotifier();

  @override
  bool operator ==(Object other) {
    return other is AvailabilityNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availabilityNotifierHash() =>
    r'c40b5df309aa0f41bf0a88f6cd3de4c6d66050d1';

/// Manages available time slots for a technician on a specific date.
///
/// **Family design**: parameterised by [technicianId] + [date] so that changing
/// the selected date in the UI simply watches a new provider instance — no
/// explicit refresh method needed. Stale instances are auto-disposed.
///
/// **Intent**: [selectSlot] only mutates the in-memory [selectedSlot] — it does
/// not re-fetch. The selected slot's [isoStart]/[isoEnd] are passed verbatim
/// to [InstantBookingNotifier.book] — no timezone conversion.

final class AvailabilityNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AvailabilityNotifier,
          AsyncValue<AvailabilityState>,
          AvailabilityState,
          FutureOr<AvailabilityState>,
          ({int technicianId, String date, int? serviceId, int? subServiceId})
        > {
  AvailabilityNotifierFamily._()
    : super(
        retry: null,
        name: r'availabilityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages available time slots for a technician on a specific date.
  ///
  /// **Family design**: parameterised by [technicianId] + [date] so that changing
  /// the selected date in the UI simply watches a new provider instance — no
  /// explicit refresh method needed. Stale instances are auto-disposed.
  ///
  /// **Intent**: [selectSlot] only mutates the in-memory [selectedSlot] — it does
  /// not re-fetch. The selected slot's [isoStart]/[isoEnd] are passed verbatim
  /// to [InstantBookingNotifier.book] — no timezone conversion.

  AvailabilityNotifierProvider call({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  }) => AvailabilityNotifierProvider._(
    argument: (
      technicianId: technicianId,
      date: date,
      serviceId: serviceId,
      subServiceId: subServiceId,
    ),
    from: this,
  );

  @override
  String toString() => r'availabilityProvider';
}

/// Manages available time slots for a technician on a specific date.
///
/// **Family design**: parameterised by [technicianId] + [date] so that changing
/// the selected date in the UI simply watches a new provider instance — no
/// explicit refresh method needed. Stale instances are auto-disposed.
///
/// **Intent**: [selectSlot] only mutates the in-memory [selectedSlot] — it does
/// not re-fetch. The selected slot's [isoStart]/[isoEnd] are passed verbatim
/// to [InstantBookingNotifier.book] — no timezone conversion.

abstract class _$AvailabilityNotifier
    extends $AsyncNotifier<AvailabilityState> {
  late final _$args =
      ref.$arg
          as ({
            int technicianId,
            String date,
            int? serviceId,
            int? subServiceId,
          });
  int get technicianId => _$args.technicianId;
  String get date => _$args.date;
  int? get serviceId => _$args.serviceId;
  int? get subServiceId => _$args.subServiceId;

  FutureOr<AvailabilityState> build({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AvailabilityState>, AvailabilityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AvailabilityState>, AvailabilityState>,
              AsyncValue<AvailabilityState>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        technicianId: _$args.technicianId,
        date: _$args.date,
        serviceId: _$args.serviceId,
        subServiceId: _$args.subServiceId,
      ),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_location_picker_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the technician work-location picker screen.
///
/// build() seeds map state in this priority:
///   1. saved tech work location (so re-entering the screen shows the last pick),
///   2. device GPS (for first-time setup),
///   3. on permission denial / GPS off → a Lahore fallback so the user can
///      still pan to their location.
///
/// The geocoding / search / current-location use cases are reused from the
/// customer-addresses feature — they're effectively generic location utilities
/// that happen to live there. Cross-feature import is intentional; duplicating
/// the geocoding stack would inflate the binary and the codebase for no UX win.

@ProviderFor(WorkLocationPickerNotifier)
final workLocationPickerProvider = WorkLocationPickerNotifierProvider._();

/// Drives the technician work-location picker screen.
///
/// build() seeds map state in this priority:
///   1. saved tech work location (so re-entering the screen shows the last pick),
///   2. device GPS (for first-time setup),
///   3. on permission denial / GPS off → a Lahore fallback so the user can
///      still pan to their location.
///
/// The geocoding / search / current-location use cases are reused from the
/// customer-addresses feature — they're effectively generic location utilities
/// that happen to live there. Cross-feature import is intentional; duplicating
/// the geocoding stack would inflate the binary and the codebase for no UX win.
final class WorkLocationPickerNotifierProvider
    extends
        $AsyncNotifierProvider<
          WorkLocationPickerNotifier,
          WorkLocationPickerState
        > {
  /// Drives the technician work-location picker screen.
  ///
  /// build() seeds map state in this priority:
  ///   1. saved tech work location (so re-entering the screen shows the last pick),
  ///   2. device GPS (for first-time setup),
  ///   3. on permission denial / GPS off → a Lahore fallback so the user can
  ///      still pan to their location.
  ///
  /// The geocoding / search / current-location use cases are reused from the
  /// customer-addresses feature — they're effectively generic location utilities
  /// that happen to live there. Cross-feature import is intentional; duplicating
  /// the geocoding stack would inflate the binary and the codebase for no UX win.
  WorkLocationPickerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workLocationPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workLocationPickerNotifierHash();

  @$internal
  @override
  WorkLocationPickerNotifier create() => WorkLocationPickerNotifier();
}

String _$workLocationPickerNotifierHash() =>
    r'4b63a436b0494298e408c450e2105babe71951c7';

/// Drives the technician work-location picker screen.
///
/// build() seeds map state in this priority:
///   1. saved tech work location (so re-entering the screen shows the last pick),
///   2. device GPS (for first-time setup),
///   3. on permission denial / GPS off → a Lahore fallback so the user can
///      still pan to their location.
///
/// The geocoding / search / current-location use cases are reused from the
/// customer-addresses feature — they're effectively generic location utilities
/// that happen to live there. Cross-feature import is intentional; duplicating
/// the geocoding stack would inflate the binary and the codebase for no UX win.

abstract class _$WorkLocationPickerNotifier
    extends $AsyncNotifier<WorkLocationPickerState> {
  FutureOr<WorkLocationPickerState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<WorkLocationPickerState>,
              WorkLocationPickerState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<WorkLocationPickerState>,
                WorkLocationPickerState
              >,
              AsyncValue<WorkLocationPickerState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

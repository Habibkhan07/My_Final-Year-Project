// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_picker_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the Uber-style map picker screen.
///
/// build() fetches the device's current GPS position to centre the map.
/// The full screen shows a loading skeleton until GPS resolves.
///
/// Intentionally uses `AsyncNotifier<MapPickerState>` so the initial GPS fetch
/// is handled by the framework — no manual loading state needed in build().

@ProviderFor(MapPickerNotifier)
final mapPickerProvider = MapPickerNotifierProvider._();

/// Drives the Uber-style map picker screen.
///
/// build() fetches the device's current GPS position to centre the map.
/// The full screen shows a loading skeleton until GPS resolves.
///
/// Intentionally uses `AsyncNotifier<MapPickerState>` so the initial GPS fetch
/// is handled by the framework — no manual loading state needed in build().
final class MapPickerNotifierProvider
    extends $AsyncNotifierProvider<MapPickerNotifier, MapPickerState> {
  /// Drives the Uber-style map picker screen.
  ///
  /// build() fetches the device's current GPS position to centre the map.
  /// The full screen shows a loading skeleton until GPS resolves.
  ///
  /// Intentionally uses `AsyncNotifier<MapPickerState>` so the initial GPS fetch
  /// is handled by the framework — no manual loading state needed in build().
  MapPickerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapPickerNotifierHash();

  @$internal
  @override
  MapPickerNotifier create() => MapPickerNotifier();
}

String _$mapPickerNotifierHash() => r'419da549706d632e2aaa8b7f865fafb8bd9cd9b4';

/// Drives the Uber-style map picker screen.
///
/// build() fetches the device's current GPS position to centre the map.
/// The full screen shows a loading skeleton until GPS resolves.
///
/// Intentionally uses `AsyncNotifier<MapPickerState>` so the initial GPS fetch
/// is handled by the framework — no manual loading state needed in build().

abstract class _$MapPickerNotifier extends $AsyncNotifier<MapPickerState> {
  FutureOr<MapPickerState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MapPickerState>, MapPickerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MapPickerState>, MapPickerState>,
              AsyncValue<MapPickerState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

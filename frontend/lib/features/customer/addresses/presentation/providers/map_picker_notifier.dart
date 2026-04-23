import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dependency_injection.dart';
import 'map_picker_state.dart';

part 'map_picker_notifier.g.dart';

/// Drives the Uber-style map picker screen.
///
/// build() fetches the device's current GPS position to centre the map.
/// The full screen shows a loading skeleton until GPS resolves.
///
/// Intentionally uses `AsyncNotifier<MapPickerState>` so the initial GPS fetch
/// is handled by the framework — no manual loading state needed in build().
@riverpod
class MapPickerNotifier extends _$MapPickerNotifier {
  Timer? _debounce;

  @override
  FutureOr<MapPickerState> build() async {
    ref.onDispose(() => _debounce?.cancel());

    final location =
        await ref.read(getCurrentLocationUseCaseProvider).call();

    return MapPickerState(
      latitude: location.latitude,
      longitude: location.longitude,
      streetAddress: location.streetAddress,
    );
  }

  /// Called when the map finishes a pan gesture.
  ///
  /// Updates coordinates immediately so the pin visually tracks the map center.
  /// Debounces the reverse-geocode call by 600 ms to avoid firing on every
  /// frame during an active drag.
  void onMapPanEnd(double lat, double lng) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(latitude: lat, longitude: lng, isGeocoding: true),
    );

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final address =
          await ref.read(reverseGeocodeUseCaseProvider).call(lat, lng);

      final s = state.value;
      if (s == null) return;
      state = AsyncData(s.copyWith(streetAddress: address, isGeocoding: false));
    });
  }

  void setLabel(String label) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(selectedLabel: label));
  }

  /// Saves the current map pin location with the selected label.
  ///
  /// Sets saveState to AsyncLoading then AsyncData/AsyncError so the UI can
  /// react without touching the map state. On AsyncData the screen pops.
  Future<void> save({required bool isDefault}) async {
    final current = state.requireValue;

    state = AsyncData(
      current.copyWith(saveState: const AsyncLoading()),
    );

    final saveResult = await AsyncValue.guard(
      () => ref.read(saveAddressUseCaseProvider).call(
            label: current.selectedLabel,
            streetAddress: current.streetAddress,
            latitude: current.latitude,
            longitude: current.longitude,
            isDefault: isDefault,
          ),
    );

    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(saveState: saveResult));
  }
}

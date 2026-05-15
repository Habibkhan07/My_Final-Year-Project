import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../customer/addresses/data/models/place_details.dart';
import '../../../../customer/addresses/presentation/providers/dependency_injection.dart'
    as customer_addresses_di;
import '../../domain/entities/work_location_entity.dart';
import '../providers/dependency_injection.dart';
import '../state/work_location_picker_state.dart';

part 'work_location_picker_notifier.g.dart';

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
@riverpod
class WorkLocationPickerNotifier extends _$WorkLocationPickerNotifier {
  Timer? _debounce;

  @override
  FutureOr<WorkLocationPickerState> build() async {
    ref.onDispose(() => _debounce?.cancel());

    final saved = await ref.read(getWorkLocationUseCaseProvider).call();

    if (saved.isSet && saved.latitude != null && saved.longitude != null) {
      // Re-entry path: prefill from the saved row. Skip the GPS round-trip.
      return WorkLocationPickerState(
        latitude: saved.latitude!,
        longitude: saved.longitude!,
        streetAddress: saved.workAddressLabel ?? _coordsLabel(
          saved.latitude!, saved.longitude!,
        ),
        maxTravelRadiusKm: saved.maxTravelRadiusKm,
      );
    }

    // First-time setup. Try device GPS; fall back to a Lahore-anchored center
    // so the user can still pan if location services are off.
    try {
      final details = await ref
          .read(customer_addresses_di.getCurrentLocationUseCaseProvider)
          .call();
      return WorkLocationPickerState(
        latitude: details.latitude,
        longitude: details.longitude,
        streetAddress: details.formattedAddress,
        maxTravelRadiusKm: saved.maxTravelRadiusKm,
        details: details,
      );
    } catch (_) {
      const fallbackLat = 31.5204;
      const fallbackLng = 74.3587;
      return WorkLocationPickerState(
        latitude: fallbackLat,
        longitude: fallbackLng,
        streetAddress: _coordsLabel(fallbackLat, fallbackLng),
        maxTravelRadiusKm: saved.maxTravelRadiusKm,
      );
    }
  }

  String _coordsLabel(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  /// Pan-end → debounced reverse-geocode. Mirrors the customer picker's flow.
  void onMapPanEnd(double lat, double lng) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(latitude: lat, longitude: lng, isGeocoding: true),
    );

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final details = await ref
            .read(customer_addresses_di.reverseGeocodeUseCaseProvider)
            .call(lat, lng);
        final s = state.value;
        if (s == null) return;
        state = AsyncData(
          s.copyWith(
            streetAddress: details.formattedAddress,
            details: details,
            isGeocoding: false,
          ),
        );
      } catch (_) {
        final s = state.value;
        if (s == null) return;
        state = AsyncData(
          s.copyWith(
            streetAddress: _coordsLabel(lat, lng),
            isGeocoding: false,
          ),
        );
      }
    });
  }

  /// Called from the search overlay when the user taps a prediction.
  void updateLocation(PlaceDetails details) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        latitude: details.latitude,
        longitude: details.longitude,
        streetAddress: details.formattedAddress,
        details: details,
        isGeocoding: false,
      ),
    );
  }

  void setRadius(int km) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(maxTravelRadiusKm: km));
  }

  /// Persists the current pin + radius via PATCH. Sets saveState so the
  /// screen can render the spinner / error inline without touching the map.
  Future<void> save() async {
    final current = state.requireValue;

    state = AsyncData(current.copyWith(saveState: const AsyncLoading()));

    // Backend's ``work_address_label`` column is CharField(max_length=200).
    // The reverse-geocoder's ``formatted_address`` regularly exceeds that
    // (Nominatim returns the full "Block 12, DHA Phase 4, Defence Housing
    // Authority, Lahore Cantonment, Lahore District, Punjab, 54810, Pakistan"
    // string). Without this truncation a Save would 400 with a confusing
    // validation error and the tech would be stuck. ``localityLabel`` is
    // always short ("Suburb, City"), so prefer it.
    final rawLabel =
        current.details?.localityLabel ?? current.streetAddress;
    final label = rawLabel.length > 200 ? rawLabel.substring(0, 200) : rawLabel;

    final result = await AsyncValue.guard<WorkLocationEntity?>(() async {
      return ref.read(saveWorkLocationUseCaseProvider).call(
            latitude: current.latitude,
            longitude: current.longitude,
            maxTravelRadiusKm: current.maxTravelRadiusKm,
            workAddressLabel: label,
          );
    });

    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(saveState: result));
  }
}

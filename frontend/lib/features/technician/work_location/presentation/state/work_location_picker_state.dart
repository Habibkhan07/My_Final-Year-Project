import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../customer/addresses/data/models/place_details.dart';
import '../../domain/entities/work_location_entity.dart';

part 'work_location_picker_state.freezed.dart';

/// UI state for the technician work-location picker screen.
///
/// Mirrors the customer-side ``MapPickerState`` but is keyed to a single
/// per-tech record — no label chips, no is_default. Instead carries the
/// matchmaker's travel-radius (slider in the bottom card).
///
/// [details] holds the last reverse-geocode result. Its ``localityLabel`` is
/// what we send as ``work_address_label`` so the format matches the customer
/// side (consistency only — backend doesn't otherwise couple them).
///
/// [saveState] is a write-result tracker, kept distinct from the screen's
/// load state so a failed save can be surfaced without re-flickering the map.
@freezed
abstract class WorkLocationPickerState with _$WorkLocationPickerState {
  const factory WorkLocationPickerState({
    required double latitude,
    required double longitude,
    required String streetAddress,
    required int maxTravelRadiusKm,
    PlaceDetails? details,
    @Default(false) bool isGeocoding,
    @Default(AsyncValue<WorkLocationEntity?>.data(null))
    AsyncValue<WorkLocationEntity?> saveState,
  }) = _WorkLocationPickerState;
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/place_details.dart';
import '../../domain/entities/address_entity.dart';

part 'map_picker_state.freezed.dart';

/// UI state for the Uber-style map picker screen.
///
/// [latitude] / [longitude] track the current map centre (the pin position).
/// [streetAddress] is the geocoder's `formatted_address` shown to the user.
/// [details] holds the *full* PlaceDetails returned by the last reverse-geocode
/// — the structured locality fields are sent to the backend on save.
/// [isGeocoding] drives the inline spinner while a reverse-geocode is in flight.
/// [selectedLabel] is the active label chip ("Home" | "Office" | "Other").
/// [saveState] wraps the save operation so the UI can react to success/failure
/// without conflating it with the map state.
@freezed
abstract class MapPickerState with _$MapPickerState {
  const MapPickerState._();

  const factory MapPickerState({
    required double latitude,
    required double longitude,
    required String streetAddress,
    PlaceDetails? details,
    @Default(false) bool isGeocoding,
    @Default('Home') String selectedLabel,
    @Default(AsyncValue<CustomerAddressEntity?>.data(null))
    AsyncValue<CustomerAddressEntity?> saveState,
  }) = _MapPickerState;
}

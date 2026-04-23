import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/address_entity.dart';

part 'map_picker_state.freezed.dart';

/// UI state for the Uber-style map picker screen.
///
/// [latitude] / [longitude] track the current map centre (the pin position).
/// [streetAddress] is reverse-geocoded from those coordinates.
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
    @Default(false) bool isGeocoding,
    @Default('Home') String selectedLabel,
    @Default(AsyncValue<CustomerAddressEntity?>.data(null))
    AsyncValue<CustomerAddressEntity?> saveState,
  }) = _MapPickerState;
}

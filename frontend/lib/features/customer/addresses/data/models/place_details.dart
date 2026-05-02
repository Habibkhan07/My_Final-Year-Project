import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_details.freezed.dart';

/// The result of reverse-geocoding a coordinate or fetching place details.
///
/// Carries the geocoder's [formattedAddress] (display string), the resolved
/// [latitude]/[longitude], and the 7 structured locality fields the backend
/// stores verbatim. Every structured field is nullable — geocoders return
/// partial coverage (rural areas have no suburb, some places lack a postcode).
///
/// [country] is ISO-3166 alpha-2 (e.g. "PK"), to match the backend column.
@freezed
abstract class PlaceDetails with _$PlaceDetails {
  const PlaceDetails._();

  const factory PlaceDetails({
    required String formattedAddress,
    required double latitude,
    required double longitude,
    String? neighborhood,
    String? suburb,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) = _PlaceDetails;

  /// Composes the short display label sent to the backend as `locality_label`.
  ///
  /// One source of truth for the rule. If product wants a different label
  /// (e.g. "{city}, {country}"), change it here only.
  ///
  ///  - `suburb` + `city` → `"{suburb}, {city}"`
  ///  - `neighborhood` + `city` → `"{neighborhood}, {city}"`
  ///  - `city` only → `"{city}"`
  ///  - else → `null`
  String? get localityLabel {
    final area = suburb ?? neighborhood;
    if (area != null && city != null) return '$area, $city';
    return city;
  }
}

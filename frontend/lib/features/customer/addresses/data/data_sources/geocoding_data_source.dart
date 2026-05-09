import '../../domain/entities/place_search_entity.dart';
import '../models/place_details.dart';

/// Port for any reverse-geocoder / place-search provider.
///
/// Two adapters live behind this interface today:
///   - [GoogleMapsGeocodingDataSource] — production (requires GOOGLE_MAPS_API_KEY)
///   - [NominatimGeocodingDataSource] — dev fallback (free OSM, do not use in prod)
///
/// Switching providers in production is a one-line dart-define change in
/// `presentation/providers/dependency_injection.dart`. Repository/notifier code
/// is unaware of which adapter is wired.
///
/// Implementations MUST:
///   - return a [PlaceDetails] populated as fully as the provider allows
///   - never throw on transient failures from a fallback path; reverseGeocode
///     in particular MUST always resolve to *some* PlaceDetails (callers rely
///     on it to never block the confirm button)
abstract class GeocodingDataSource {
  /// Autocomplete predictions for an in-progress search query.
  /// Caller passes a session token to bundle the query → details billing.
  Future<List<PlaceSearchEntity>> searchPlaces(
    String query,
    String sessionToken,
  );

  /// Resolve the lat/lng + structured fields for a chosen prediction.
  Future<PlaceDetails> getPlaceDetails(String placeId, String sessionToken);

  /// Reverse-geocode arbitrary coordinates. Used when the user drags the map
  /// pin. Must always resolve — fall back to a `"lat, lng"` string for
  /// [PlaceDetails.formattedAddress] if upstream fails.
  Future<PlaceDetails> reverseGeocode(double lat, double lng);
}

import '../entities/address_entity.dart';
import '../entities/place_search_entity.dart';
import '../../data/models/place_details.dart';

/// Contract for all customer address operations.
///
/// The repository is the single source of truth — callers never touch
/// RemoteDataSource or LocalDataSource directly.
abstract class IAddressRepository {
  /// Returns the authenticated user's saved addresses, default-first.
  ///
  /// Offline-first: caches on success. Falls back to cache on [SocketException].
  /// Throws [AddressFailure] on any failure.
  Future<List<CustomerAddressEntity>> getAddresses();

  /// Creates and persists a new address.
  ///
  /// If [isDefault] is true, the backend atomically clears all other defaults.
  /// The structured locality fields are produced by the configured
  /// [GeocodingDataSource] and forwarded as-is to the backend, which stores
  /// them verbatim. All structured fields are optional — omit them to send
  /// `null` for the corresponding column.
  /// Throws [AddressFailure] on any failure.
  Future<CustomerAddressEntity> saveAddress({
    required String label,
    required String streetAddress,
    required double latitude,
    required double longitude,
    required bool isDefault,
    String? neighborhood,
    String? suburb,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? localityLabel,
  });

  /// Updates an existing address. When the user re-picks a location, the
  /// caller should pass lat/lng **and** the new structured fields together so
  /// the cached label stays consistent with the coordinates.
  Future<CustomerAddressEntity> updateAddress({
    required int id,
    bool? isDefault,
    String? label,
    String? streetAddress,
    double? latitude,
    double? longitude,
    String? neighborhood,
    String? suburb,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? localityLabel,
  });

  Future<void> deleteAddress(int id);

  /// Uses device GPS + reverse geocoding to resolve the current position.
  ///
  /// Returns a [PlaceDetails] so callers can pre-fill the save-address form
  /// with structured locality data.
  /// Throws [AddressLocationPermissionDenied] or [AddressLocationServiceDisabled].
  Future<PlaceDetails> getCurrentLocation();

  /// Reverse-geocodes arbitrary [lat]/[lng] coordinates. Used by the map
  /// picker when the user drags the pin.
  ///
  /// Never throws — falls back to a `"lat, lng"` string in
  /// [PlaceDetails.formattedAddress] on geocoding failure.
  Future<PlaceDetails> reverseGeocode(double lat, double lng);

  /// Searches for places via the configured geocoding provider.
  Future<List<PlaceSearchEntity>> searchPlaces(String query, String sessionToken);

  /// Retrieves detailed information for a specific place.
  Future<PlaceDetails> getPlaceDetails(String placeId, String sessionToken);
}

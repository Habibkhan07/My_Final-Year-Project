import '../entities/address_entity.dart';

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
  /// Throws [AddressFailure] on any failure.
  Future<CustomerAddressEntity> saveAddress({
    required String label,
    required String streetAddress,
    required double latitude,
    required double longitude,
    required bool isDefault,
  });

  /// Deletes the address with [id].
  ///
  /// Throws [AddressNotFoundFailure] when the id doesn't exist or belongs to
  /// another user (IDOR: same response shape, caller cannot distinguish).
  Future<void> deleteAddress(int id);

  /// Uses device GPS + reverse geocoding to resolve the current position.
  ///
  /// Returns a named record so callers can pre-fill the save-address form
  /// without any additional lookup.
  /// Throws [AddressLocationPermissionDenied] or [AddressLocationServiceDisabled].
  Future<({double latitude, double longitude, String streetAddress})> getCurrentLocation();

  /// Reverse-geocodes arbitrary [lat]/[lng] coordinates to a human-readable
  /// street address string. Used by the map picker when the user drags the pin.
  ///
  /// Never throws — falls back to `"lat, lng"` on geocoding failure so the
  /// confirm button is never blocked.
  Future<String> reverseGeocode(double lat, double lng);
}

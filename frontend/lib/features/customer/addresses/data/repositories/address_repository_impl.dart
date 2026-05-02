import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/entities/place_search_entity.dart';
import '../../domain/failures/address_failure.dart';
import '../../domain/repositories/i_address_repository.dart';
import '../data_sources/address_local_data_source.dart';
import '../data_sources/address_location_data_source.dart';
import '../data_sources/address_remote_data_source.dart';
import '../data_sources/geocoding_data_source.dart';
import '../models/address_model.dart';
import '../models/place_details.dart';

class AddressRepositoryImpl implements IAddressRepository {
  final AddressRemoteDataSource remoteDataSource;
  final AddressLocalDataSource localDataSource;
  final AddressLocationDataSource locationDataSource;
  final GeocodingDataSource geocodingDataSource;

  const AddressRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource,
    this.locationDataSource,
    this.geocodingDataSource,
  );

  @override
  Future<List<CustomerAddressEntity>> getAddresses() async {
    try {
      final models = await remoteDataSource.getAddresses();
      await localDataSource.cacheAddresses(models);
      return models.map((m) => m.toEntity()).toList();
    } on HttpFailure catch (e) {
      throw AddressServerFailure(e.message);
    } on SocketException {
      final cached = localDataSource.getCachedAddresses();
      if (cached != null) return cached.map((m) => m.toEntity()).toList();
      throw const AddressNetworkFailure();
    } on FormatException {
      throw const AddressParsingFailure();
    } catch (e) {
      throw AddressServerFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
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
  }) async {
    try {
      final request = CreateAddressRequest(
        label: label,
        streetAddress: streetAddress,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
        neighborhood: neighborhood,
        suburb: suburb,
        city: city,
        state: state,
        country: country,
        postalCode: postalCode,
        localityLabel: localityLabel,
      );
      final model = await remoteDataSource.saveAddress(request);
      return model.toEntity();
    } on HttpFailure catch (e) {
      // If the backend provided field-specific errors, bubble up the first one
      // for better UI feedback (e.g. "street_address: This field is required")
      if (e.errors.isNotEmpty) {
        final field = e.errors.keys.first;
        final message = (e.errors[field] as List).first;
        throw AddressServerFailure('$field: $message');
      }
      throw AddressServerFailure(e.message);
    } on SocketException {
      throw const AddressNetworkFailure();
    } on FormatException {
      throw const AddressParsingFailure();
    } catch (e) {
      throw AddressServerFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
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
  }) async {
    try {
      final data = {
        if (isDefault != null) 'is_default': isDefault,
        if (label != null) 'label': label,
        if (streetAddress != null) 'street_address': streetAddress,
        if (latitude != null) 'latitude': latitude.toStringAsFixed(6),
        if (longitude != null) 'longitude': longitude.toStringAsFixed(6),
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (suburb != null) 'suburb': suburb,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        if (postalCode != null) 'postal_code': postalCode,
        if (localityLabel != null) 'locality_label': localityLabel,
      };
      final model = await remoteDataSource.updateAddress(id, data);
      return model.toEntity();
    } on HttpFailure catch (e) {
      if (e.errors.isNotEmpty) {
        final field = e.errors.keys.first;
        final message = (e.errors[field] as List).first;
        throw AddressServerFailure('$field: $message');
      }
      throw AddressServerFailure(e.message);
    } on SocketException {
      throw const AddressNetworkFailure();
    } on FormatException {
      throw const AddressParsingFailure();
    } catch (e) {
      throw AddressServerFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAddress(int id) async {
    try {
      await remoteDataSource.deleteAddress(id);
    } on HttpFailure catch (e) {
      if (e.statusCode == 404) throw const AddressNotFoundFailure();
      throw AddressServerFailure(e.message);
    } on SocketException {
      throw const AddressNetworkFailure();
    } catch (e) {
      throw AddressServerFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<PlaceDetails> getCurrentLocation() async {
    try {
      // Resolve the device GPS first (native, offline-capable). Then layer
      // the HTTP geocoder on top to get structured fields. If the HTTP call
      // fails (no network, rate-limited), fall back to the native placemark
      // which still gives a usable streetAddress + partial structured data.
      final native = await locationDataSource.getCurrentLocation();
      try {
        final details = await geocodingDataSource.reverseGeocode(
            native.latitude, native.longitude);
        return details;
      } catch (_) {
        return native;
      }
    } on LocationServiceDisabledException {
      throw const AddressLocationServiceDisabled();
    } on PermissionDeniedException {
      throw const AddressLocationPermissionDenied();
    } catch (e) {
      throw AddressServerFailure('Location error: ${e.toString()}');
    }
  }

  @override
  Future<PlaceDetails> reverseGeocode(double lat, double lng) async {
    try {
      return await geocodingDataSource.reverseGeocode(lat, lng);
    } catch (_) {
      // Contract: never block the UI. Synthesise a coord-only PlaceDetails so
      // callers can still display *something* and persist the row.
      return PlaceDetails(
        formattedAddress: '$lat, $lng',
        latitude: lat,
        longitude: lng,
      );
    }
  }

  @override
  Future<List<PlaceSearchEntity>> searchPlaces(String query, String sessionToken) async {
    try {
      return await geocodingDataSource.searchPlaces(query, sessionToken);
    } on SocketException {
      throw const AddressNetworkFailure();
    } on FormatException catch (e) {
      throw AddressServerFailure(e.message);
    } catch (e) {
      throw AddressServerFailure('Search failed: ${e.toString()}');
    }
  }

  @override
  Future<PlaceDetails> getPlaceDetails(String placeId, String sessionToken) async {
    try {
      return await geocodingDataSource.getPlaceDetails(placeId, sessionToken);
    } on SocketException {
      throw const AddressNetworkFailure();
    } on FormatException catch (e) {
      throw AddressServerFailure(e.message);
    } catch (e) {
      throw AddressServerFailure('Details fetch failed: ${e.toString()}');
    }
  }
}

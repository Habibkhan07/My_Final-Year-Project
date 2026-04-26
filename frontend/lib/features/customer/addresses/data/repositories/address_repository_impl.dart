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
import '../data_sources/google_maps_remote_data_source.dart';
import '../models/address_model.dart';

class AddressRepositoryImpl implements IAddressRepository {
  final AddressRemoteDataSource remoteDataSource;
  final AddressLocalDataSource localDataSource;
  final AddressLocationDataSource locationDataSource;
  final GoogleMapsRemoteDataSource googleMapsDataSource;

  const AddressRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource,
    this.locationDataSource,
    this.googleMapsDataSource,
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
  }) async {
    try {
      final request = CreateAddressRequest(
        label: label,
        streetAddress: streetAddress,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
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
  }) async {
    try {
      final data = {
        if (isDefault != null) 'is_default': isDefault,
        if (label != null) 'label': label,
        if (streetAddress != null) 'street_address': streetAddress,
        if (latitude != null) 'latitude': latitude.toStringAsFixed(6),
        if (longitude != null) 'longitude': longitude.toStringAsFixed(6),
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
  Future<({double latitude, double longitude, String streetAddress})>
      getCurrentLocation() async {
    try {
      // The location data source uses geolocator to get position.
      // We will intercept the reverse-geocoding to use Google Maps instead.
      final locResult = await locationDataSource.getCurrentLocation();
      try {
        final address = await googleMapsDataSource.reverseGeocode(
            locResult.latitude, locResult.longitude);
        return (
          latitude: locResult.latitude,
          longitude: locResult.longitude,
          streetAddress: address,
        );
      } catch (_) {
        // Fallback to what locationDataSource resolved (or 'lat, lng')
        return locResult;
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
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      return await googleMapsDataSource.reverseGeocode(lat, lng);
    } catch (_) {
      // Fallback
      return '$lat, $lng';
    }
  }

  @override
  Future<List<PlaceSearchEntity>> searchPlaces(String query, String sessionToken) async {
    try {
      final results = await googleMapsDataSource.searchPlaces(query, sessionToken);
      return results.map((r) {
        final struct = r['structured_formatting'] ?? {};
        return PlaceSearchEntity(
          placeId: r['place_id'] as String,
          description: r['description'] as String,
          mainText: struct['main_text'] as String? ?? r['description'] as String,
          secondaryText: struct['secondary_text'] as String? ?? '',
        );
      }).toList();
    } on SocketException {
      throw const AddressNetworkFailure();
    } on FormatException catch (e) {
      throw AddressServerFailure(e.message);
    } catch (e) {
      throw AddressServerFailure('Search failed: ${e.toString()}');
    }
  }

  @override
  Future<({double latitude, double longitude, String streetAddress})> getPlaceDetails(String placeId, String sessionToken) async {
    try {
      final details = await googleMapsDataSource.getPlaceDetails(placeId, sessionToken);
      final geometry = details['geometry']?['location'];
      if (geometry == null) throw const FormatException('No geometry in place details');

      return (
        latitude: (geometry['lat'] as num).toDouble(),
        longitude: (geometry['lng'] as num).toDouble(),
        streetAddress: details['formatted_address'] as String? ?? '',
      );
    } on SocketException {
      throw const AddressNetworkFailure();
    } on FormatException catch (e) {
      throw AddressServerFailure(e.message);
    } catch (e) {
      throw AddressServerFailure('Details fetch failed: ${e.toString()}');
    }
  }
}


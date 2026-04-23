import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/failures/address_failure.dart';
import '../../domain/repositories/i_address_repository.dart';
import '../data_sources/address_local_data_source.dart';
import '../data_sources/address_location_data_source.dart';
import '../data_sources/address_remote_data_source.dart';
import '../models/address_model.dart';

class AddressRepositoryImpl implements IAddressRepository {
  final AddressRemoteDataSource remoteDataSource;
  final AddressLocalDataSource localDataSource;
  final AddressLocationDataSource locationDataSource;

  const AddressRepositoryImpl(
      this.remoteDataSource, this.localDataSource, this.locationDataSource);

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
      return await locationDataSource.getCurrentLocation();
    } on LocationServiceDisabledException {
      throw const AddressLocationServiceDisabled();
    } on PermissionDeniedException {
      throw const AddressLocationPermissionDenied();
    } catch (e) {
      throw AddressServerFailure('Location error: ${e.toString()}');
    }
  }

  @override
  Future<String> reverseGeocode(double lat, double lng) =>
      locationDataSource.reverseGeocode(lat, lng);
}

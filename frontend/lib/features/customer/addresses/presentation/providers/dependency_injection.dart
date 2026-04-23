import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data_sources/address_local_data_source.dart';
import '../../data/data_sources/address_location_data_source.dart';
import '../../data/data_sources/address_remote_data_source.dart';
import '../../data/repositories/address_repository_impl.dart';
import '../../domain/repositories/i_address_repository.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/use_cases/delete_address_use_case.dart';
import '../../domain/use_cases/get_addresses_use_case.dart';
import '../../domain/use_cases/get_current_location_use_case.dart';
import '../../domain/use_cases/reverse_geocode_use_case.dart';
import '../../domain/use_cases/save_address_use_case.dart';
import '../../domain/use_cases/update_address_use_case.dart';
import '../../../../../features/technician/onboarding/presentation/providers/dependency_injection.dart';

part 'dependency_injection.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
http.Client addressHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
FlutterSecureStorage addressSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ---------------------------------------------------------------------------
// Data Sources
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AddressRemoteDataSource addressRemoteDataSource(Ref ref) =>
    AddressRemoteDataSource(
      client: ref.watch(addressHttpClientProvider),
      secureStorage: ref.watch(addressSecureStorageProvider),
    );

@Riverpod(keepAlive: true)
AddressLocalDataSource addressLocalDataSource(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AddressLocalDataSource(prefs);
}

@Riverpod(keepAlive: true)
AddressLocationDataSource addressLocationDataSource(Ref ref) =>
    AddressLocationDataSource();

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
IAddressRepository addressRepository(Ref ref) => AddressRepositoryImpl(
      ref.watch(addressRemoteDataSourceProvider),
      ref.watch(addressLocalDataSourceProvider),
      ref.watch(addressLocationDataSourceProvider),
    );

// ---------------------------------------------------------------------------
// Use Cases
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GetAddressesUseCase getAddressesUseCase(Ref ref) =>
    GetAddressesUseCase(ref.watch(addressRepositoryProvider));

@Riverpod(keepAlive: true)
SaveAddressUseCase saveAddressUseCase(Ref ref) =>
    SaveAddressUseCase(ref.watch(addressRepositoryProvider));

@Riverpod(keepAlive: true)
UpdateAddressUseCase updateAddressUseCase(Ref ref) =>
    UpdateAddressUseCase(ref.watch(addressRepositoryProvider));

@Riverpod(keepAlive: true)
DeleteAddressUseCase deleteAddressUseCase(Ref ref) =>
    DeleteAddressUseCase(ref.watch(addressRepositoryProvider));

@Riverpod(keepAlive: true)
GetCurrentLocationUseCase getCurrentLocationUseCase(Ref ref) =>
    GetCurrentLocationUseCase(ref.watch(addressRepositoryProvider));

@Riverpod(keepAlive: true)
ReverseGeocodeUseCase reverseGeocodeUseCase(Ref ref) =>
    ReverseGeocodeUseCase(ref.watch(addressRepositoryProvider));

// ---------------------------------------------------------------------------
// Convenience fetch provider — consumed by any screen that needs the list
// ---------------------------------------------------------------------------

@riverpod
Future<List<CustomerAddressEntity>> addresses(Ref ref) =>
    ref.watch(getAddressesUseCaseProvider).call();

// ---------------------------------------------------------------------------
// Derived provider — returns the single default address, or null
// Consumed by the home screen header to display the active location.
// ---------------------------------------------------------------------------

@riverpod
Future<CustomerAddressEntity?> defaultAddress(Ref ref) async {
  final list = await ref.watch(addressesProvider.future);
  return list.where((a) => a.isDefault).firstOrNull;
}

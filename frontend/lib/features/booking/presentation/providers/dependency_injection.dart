import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/data_sources/booking_remote_data_source.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/repositories/i_booking_repository.dart';
import '../../domain/use_cases/create_instant_booking_use_case.dart';
import '../../domain/use_cases/get_availability_use_case.dart';
import '../../domain/use_cases/get_saved_addresses_use_case.dart';
import '../../domain/use_cases/get_technician_profile_use_case.dart';

part 'dependency_injection.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
http.Client bookingHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
FlutterSecureStorage bookingSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ---------------------------------------------------------------------------
// Data Sources
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
IBookingRemoteDataSource bookingRemoteDataSource(Ref ref) =>
    BookingRemoteDataSource(
      client: ref.watch(bookingHttpClientProvider),
      secureStorage: ref.watch(bookingSecureStorageProvider),
    );

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
IBookingRepository bookingRepository(Ref ref) => BookingRepositoryImpl(
      remoteDataSource: ref.watch(bookingRemoteDataSourceProvider),
    );

// ---------------------------------------------------------------------------
// Use Cases
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GetTechnicianProfileUseCase getTechnicianProfileUseCase(Ref ref) =>
    GetTechnicianProfileUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
GetAvailabilityUseCase getAvailabilityUseCase(Ref ref) =>
    GetAvailabilityUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
CreateInstantBookingUseCase createInstantBookingUseCase(Ref ref) =>
    CreateInstantBookingUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
GetSavedAddressesUseCase getSavedAddressesUseCase(Ref ref) =>
    GetSavedAddressesUseCase(ref.watch(bookingRepositoryProvider));

// ---------------------------------------------------------------------------
// Simple Fetch Providers
// ---------------------------------------------------------------------------

@riverpod
Future<List<SavedAddressEntity>> savedAddresses(Ref ref) {
  return ref.watch(getSavedAddressesUseCaseProvider).call();
}

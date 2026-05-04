// DI surface for the customer bookings feature.
//
// Mirrors the layout of `features/customer/home/presentation/providers/
// dependency_injection.dart` (which is itself the canonical reference
// for Clean Architecture wiring on the customer side). Every provider
// here is `keepAlive: true` because the list/counts notifiers are
// keepAlive — re-creating dependencies on every screen mount would
// orphan the realtime listener and the in-flight cache writes.
//
// Boot-time `SharedPreferences` instance comes from
// `sharedPreferencesProvider` (declared once in the technician
// onboarding feature for historical reasons; every customer feature
// that touches local storage already imports from there). The provider
// is overridden in `main.dart` with the real `SharedPreferences.getInstance()`
// future result.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../technician/onboarding/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/customer_bookings_local_data_source.dart';
import '../../data/data_sources/customer_bookings_remote_data_source.dart';
import '../../data/repositories/customer_bookings_repository_impl.dart';
import '../../domain/repositories/customer_bookings_repository.dart';
import '../../domain/use_cases/get_bookings_counts_use_case.dart';
import '../../domain/use_cases/get_customer_bookings_use_case.dart';

part 'dependency_injection.g.dart';

// ─── Infrastructure ─────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
http.Client customerBookingsHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
FlutterSecureStorage customerBookingsSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ─── Data Sources ────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ICustomerBookingsRemoteDataSource customerBookingsRemoteDataSource(Ref ref) =>
    CustomerBookingsRemoteDataSource(
      client: ref.watch(customerBookingsHttpClientProvider),
      secureStorage: ref.watch(customerBookingsSecureStorageProvider),
    );

@Riverpod(keepAlive: true)
ICustomerBookingsLocalDataSource customerBookingsLocalDataSource(Ref ref) =>
    CustomerBookingsLocalDataSource(ref.watch(sharedPreferencesProvider));

// ─── Repository ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ICustomerBookingsRepository customerBookingsRepository(Ref ref) =>
    CustomerBookingsRepositoryImpl(
      remote: ref.watch(customerBookingsRemoteDataSourceProvider),
      local: ref.watch(customerBookingsLocalDataSourceProvider),
    );

// ─── Use Cases ───────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
GetCustomerBookingsUseCase getCustomerBookingsUseCase(Ref ref) =>
    GetCustomerBookingsUseCase(ref.watch(customerBookingsRepositoryProvider));

@Riverpod(keepAlive: true)
GetBookingsCountsUseCase getBookingsCountsUseCase(Ref ref) =>
    GetBookingsCountsUseCase(ref.watch(customerBookingsRepositoryProvider));

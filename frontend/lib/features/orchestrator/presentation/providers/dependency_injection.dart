// DI surface for the orchestrator feature.
//
// Per sprint §24 we reuse `eventHttpClient` from the realtime feature
// (single shared http.Client, already keepAlive). Per the per-feature
// secure-storage convention we declare `orchestratorSecureStorage` here
// rather than importing `eventSecureStorage` — `FlutterSecureStorage`
// is a stateless wrapper around the platform store, so multiple
// instances cost nothing and keep cross-feature dependencies tidy.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/realtime/presentation/providers/dependency_injection.dart';
import '../../../technician/onboarding/presentation/providers/dependency_injection.dart';
import '../../data/datasources/booking_detail_local_data_source.dart';
import '../../data/datasources/booking_detail_remote_data_source.dart';
import '../../data/repositories/booking_detail_repository_impl.dart';
import '../../domain/repositories/booking_detail_repository.dart';
import '../../domain/use_cases/get_booking_detail_use_case.dart';

part 'dependency_injection.g.dart';

// ─── Infrastructure ──────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
FlutterSecureStorage orchestratorSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ─── Data Sources ────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
IBookingDetailRemoteDataSource bookingDetailRemoteDataSource(Ref ref) =>
    BookingDetailRemoteDataSource(
      ref.watch(eventHttpClientProvider),
      ref.watch(orchestratorSecureStorageProvider),
    );

@Riverpod(keepAlive: true)
IBookingDetailLocalDataSource bookingDetailLocalDataSource(Ref ref) =>
    BookingDetailLocalDataSource(ref.watch(sharedPreferencesProvider));

// ─── Repository ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
IBookingDetailRepository bookingDetailRepository(Ref ref) {
  // The auth user id is required to derive viewerRole inside the mapper.
  // We `ref.watch` so that auth state changes (login/logout) rebuild this
  // provider, which cascades to the use case + notifier — a logged-out
  // user shouldn't be reading any booking detail.
  //
  // Fail-fast on null rather than defaulting to 0: a sentinel id silently
  // miscategorizes the viewer as the technician (since no real customer
  // has User.id == 0), which would render the wrong primary action with
  // the wrong copy. The auth-redirect guard in `app_router.dart` should
  // catch unauthenticated users at the route level — this throw is the
  // belt-and-braces invariant for everything below the guard.
  final currentUserId = ref.watch(currentAuthUserIdProvider);
  if (currentUserId == null) {
    throw StateError(
      'BookingDetailRepository requires an authenticated user; '
      'currentAuthUserIdProvider returned null. The auth-redirect guard '
      'in app_router should have prevented this provider from being '
      'constructed while logged out.',
    );
  }
  return BookingDetailRepositoryImpl(
    remote: ref.watch(bookingDetailRemoteDataSourceProvider),
    local: ref.watch(bookingDetailLocalDataSourceProvider),
    currentUserId: currentUserId,
  );
}

// ─── Use Cases ───────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
GetBookingDetailUseCase getBookingDetailUseCase(Ref ref) =>
    GetBookingDetailUseCase(ref.watch(bookingDetailRepositoryProvider));

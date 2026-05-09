// Customer bookings repository — step 2 of the 4-step error pipeline
// (CLAUDE.md): translates the data-source's [HttpFailure] /
// [SocketException] paths into the domain's typed sealed
// [CustomerBookingsFailure] hierarchy.
//
// **Network-first with cache fallback** for [getBookings]:
//
//   1. Try the network. Cache the response on success (first page only).
//   2. On [SocketException] **for the first page**: serve cache with
//      `isStaleCache=true`. If no cache exists, throw
//      [CustomerBookingsOfflineNoCache].
//   3. On [SocketException] **for a subsequent page**: throw
//      [CustomerBookingsOfflineNoCache] directly. Pagination cache adds
//      complexity for marginal value — see the local data source's
//      class doc.
//
// [getCounts] is **never** cached — counts are cheap, always live, and
// stale numbers on the segmented control would mislead the user.
// Offline path throws [CustomerBookingsOfflineNoCache] directly; the
// screen renders the badges as `—` while offline.
import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/booking_segment.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/bookings_counts.dart';
import '../../domain/entities/bookings_page.dart';
import '../../domain/failures/customer_bookings_failure.dart';
import '../../domain/repositories/customer_bookings_repository.dart';
import '../data_sources/customer_bookings_local_data_source.dart';
import '../data_sources/customer_bookings_remote_data_source.dart';
import '../mappers/customer_booking_mapper.dart';

class CustomerBookingsRepositoryImpl implements ICustomerBookingsRepository {
  final ICustomerBookingsRemoteDataSource _remote;
  final ICustomerBookingsLocalDataSource _local;

  CustomerBookingsRepositoryImpl({
    required ICustomerBookingsRemoteDataSource remote,
    required ICustomerBookingsLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  @override
  Future<BookingsPage> getBookings({
    required BookingSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) async {
    final isFirstPage = cursor == null;

    try {
      final response = await _remote.getBookings(
        segment: segment,
        statusFilter: statusFilter,
        cursor: cursor,
        pageSize: pageSize,
      );

      if (isFirstPage) {
        // Best-effort cache. A failure here must not surface to the
        // caller — they got their fresh data, the cache is the
        // tomorrow-offline-rescue path, not a load-bearing one.
        try {
          await _local.cacheFirstPage(segment, response);
        } catch (_) {
          // intentional silent — see comment above.
        }
      }

      return CustomerBookingMapper.pageFromResponse(response);
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      if (!isFirstPage) {
        // Pagination cache miss path — see class doc.
        throw const CustomerBookingsOfflineNoCache();
      }
      final cached = await _local.getCachedFirstPage(segment);
      if (cached == null) {
        throw const CustomerBookingsOfflineNoCache();
      }
      return CustomerBookingMapper.pageFromResponse(
        cached.response,
        isStaleCache: true,
        cachedAt: cached.cachedAt,
      );
    } on CustomerBookingsFailure {
      // A nested layer (future interceptor) may have already mapped —
      // let it propagate verbatim instead of wrapping into Unknown.
      rethrow;
    } catch (e) {
      throw UnknownCustomerBookingsFailure(e.toString());
    }
  }

  @override
  Future<BookingsCounts> getCounts() async {
    try {
      final model = await _remote.getCounts();
      return CustomerBookingMapper.countsFromModel(model);
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      throw const CustomerBookingsOfflineNoCache();
    } on CustomerBookingsFailure {
      rethrow;
    } catch (e) {
      throw UnknownCustomerBookingsFailure(e.toString());
    }
  }

  /// Wire-code → typed failure switch. Centralised so list and counts
  /// arms agree on the mapping.
  CustomerBookingsFailure _mapHttpFailure(HttpFailure failure) {
    if (failure.statusCode >= 500) {
      return const CustomerBookingsServerFailure();
    }
    if (failure.statusCode == 400) {
      return CustomerBookingsValidationFailure(
        code: failure.code,
        errors: failure.errors,
        message: failure.message.isNotEmpty
            ? failure.message
            : 'Invalid request.',
      );
    }
    // 401/403/404 fall through to Unknown — none of those should be
    // reachable on this list endpoint with a logged-in user, so they
    // indicate a deployment / auth-state mismatch rather than a normal
    // outcome. Surfacing them as Unknown lets the screen show a generic
    // "something went wrong + retry" affordance.
    return UnknownCustomerBookingsFailure(failure.message);
  }
}

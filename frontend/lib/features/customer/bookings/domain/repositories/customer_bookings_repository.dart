import '../entities/booking_segment.dart';
import '../entities/booking_status.dart';
import '../entities/bookings_counts.dart';
import '../entities/bookings_page.dart';

/// Contract for the customer-side bookings list + counts endpoints.
///
/// Implementations talk to:
///   * `GET /api/bookings/` (list, paginated)
///   * `GET /api/bookings/counts/` (badge counts)
///
/// See `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` for the full
/// wire contract.
///
/// **Error pipeline contract.** Per CLAUDE.md, every failure surfaces
/// as a typed `CustomerBookingsFailure`. The implementation maps the
/// standard HTTP error envelope to the appropriate sealed subtype
/// (see `customer_bookings_failure.dart`).
///
/// **Offline behavior** for [getBookings]: network-first, with a
/// transparent cache fallback on `SocketException`. The returned
/// [BookingsPage] carries `isStaleCache=true` when served from cache;
/// the notifier surfaces the offline banner when that flag is set.
/// When no cache exists for the requested segment, throws
/// `CustomerBookingsOfflineNoCache`.
///
/// [getCounts] is **never** cached. Counts are cheap, always live, and
/// stale numbers on the segmented control would mislead the user. A
/// `SocketException` here surfaces as `CustomerBookingsOfflineNoCache`
/// directly; the screen renders the badges as `—` while offline.
abstract class ICustomerBookingsRepository {
  /// Fetch one page of the customer's bookings.
  ///
  /// [segment] is the dumb-UI shortcut. [statusFilter] (when non-empty)
  /// overrides the segment-implied status set on the server side and
  /// is reserved for future filter chips — v1 list notifier passes null.
  ///
  /// [cursor] is null on the first page. Subsequent pages pass the
  /// previous response's `nextCursor` verbatim.
  ///
  /// Throws [CustomerBookingsOfflineNoCache] when offline with no
  /// cache.
  /// Throws [CustomerBookingsServerFailure] on HTTP 5xx.
  /// Throws [CustomerBookingsValidationFailure] on HTTP 400.
  /// Throws [UnknownCustomerBookingsFailure] for any other unexpected
  /// error.
  Future<BookingsPage> getBookings({
    required BookingSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  });

  /// Fetch the segmented-control badge counts. Always live — never
  /// cached. See class doc for offline semantics.
  ///
  /// Throws [CustomerBookingsOfflineNoCache] when offline.
  /// Throws [CustomerBookingsServerFailure] on HTTP 5xx.
  /// Throws [UnknownCustomerBookingsFailure] for any other unexpected
  /// error.
  Future<BookingsCounts> getCounts();
}

// Contract: fed by `GET /api/bookings/` envelope.
// Wire spec: `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` §1.4.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'customer_booking.dart';

part 'bookings_page.freezed.dart';

/// One page of the customer's bookings list, plus the metadata the
/// list notifier needs to drive pagination, refresh, and offline UX.
///
/// Field notes:
///
///   * [nextCursor] — opaque token to fetch the next page. Null when
///     [hasMore] is false. Pass back verbatim on the next request; the
///     client never decodes it.
///
///   * [hasMore] — server-reported. The notifier uses this both to
///     decide whether to render the loading footer and whether
///     `loadMore()` is allowed.
///
///   * [serverTime] — server clock when the page was assembled. Used
///     by the card's date formatter to anchor "Today / Tomorrow / In
///     30 min" labels regardless of device-clock skew. The notifier
///     threads this through into the state.
///
///   * [isStaleCache] — true when the page was served from
///     [CustomerBookingsLocalDataSource] after a `SocketException`.
///     The screen surfaces a thin offline banner when true.
///
///   * [cachedAt] — when the cached page was originally fetched. Null
///     for fresh-from-network pages. Used by the screen to format the
///     "Last updated 8 min ago" disclosure on the offline banner.
@freezed
abstract class BookingsPage with _$BookingsPage {
  const factory BookingsPage({
    required List<CustomerBooking> items,
    required String? nextCursor,
    required bool hasMore,
    required DateTime serverTime,
    @Default(false) bool isStaleCache,
    DateTime? cachedAt,
  }) = _BookingsPage;
}

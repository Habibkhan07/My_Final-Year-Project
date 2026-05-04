// State held by [CustomerBookingsListNotifier]. The whole state is
// wrapped in `AsyncValue<CustomerBookingsListState>` by the notifier;
// the state object below is the inner data when the AsyncValue is in
// `data` form.
//
// Keeping the AsyncValue around the entire state (instead of the more
// common `state.copyWith(items: AsyncValue.data(...))` shape) means
// initial load surfaces as `AsyncLoading()`, refresh errors surface
// as `AsyncError()`, and the screen's `when()` switch handles all
// three transitions in one place. CLAUDE.md mandates `AsyncValue.guard`
// for this exact reason.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/booking_segment.dart';
import '../../domain/entities/customer_booking.dart';

part 'customer_bookings_list_state.freezed.dart';

@freezed
abstract class CustomerBookingsListState with _$CustomerBookingsListState {
  const factory CustomerBookingsListState({
    /// Which segment this state belongs to. The notifier sets it on
    /// build; the screen reads it when deciding whether to re-issue a
    /// load (rare belt-and-suspenders — the watched
    /// `selectedSegmentProvider` already triggers a re-build).
    required BookingSegment segment,

    /// All bookings loaded so far for [segment]. Pagination appends to
    /// this list; pull-to-refresh replaces it.
    @Default(<CustomerBooking>[]) List<CustomerBooking> items,

    /// Cursor to fetch the next page. Null when no more pages.
    String? nextCursor,

    /// Whether the underlying queryset has rows beyond what's loaded.
    /// Drives both the list-footer loading spinner and the `loadMore()`
    /// guard.
    @Default(false) bool hasMore,

    /// True while a `loadMore()` request is in flight. The screen
    /// renders a footer spinner while true and gates further
    /// `loadMore()` calls.
    @Default(false) bool isLoadingMore,

    /// True when the items currently shown were served from the local
    /// cache after a `SocketException`. The screen surfaces an offline
    /// banner with the [cachedAt] timestamp when true.
    @Default(false) bool isStaleCache,

    /// When the cached page was originally fetched. Null when [items]
    /// is fresh-from-network.
    DateTime? cachedAt,

    /// Server clock at the time the page was assembled. Used by the
    /// card's date formatter to anchor "Today / Tomorrow / In 30 min"
    /// labels regardless of device-clock skew.
    required DateTime serverTime,
  }) = _CustomerBookingsListState;
}

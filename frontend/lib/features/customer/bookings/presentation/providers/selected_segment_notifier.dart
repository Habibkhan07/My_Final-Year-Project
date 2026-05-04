// Holds which segment the user has tapped — `upcoming` or `past`.
//
// The list notifier `ref.watch`es this provider so a tab change
// triggers a re-build (fresh first-page fetch for the new segment).
// State is intentionally not persisted: a fresh app launch always
// lands on Upcoming, which matches what users care about first when
// opening the My Bookings tab.
//
// The list notifier is `keepAlive: true`, but this provider is **not**
// — it scopes to the screen mount. When the user navigates away from
// the tab and back, defaulting to Upcoming is the right reset.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/booking_segment.dart';

part 'selected_segment_notifier.g.dart';

@riverpod
class SelectedSegment extends _$SelectedSegment {
  @override
  BookingSegment build() => BookingSegment.upcoming;

  /// Set the active segment. The list notifier watches this provider
  /// and re-fetches when it changes; calling `set(current)` is a no-op.
  void set(BookingSegment segment) {
    if (state == segment) return;
    state = segment;
  }
}

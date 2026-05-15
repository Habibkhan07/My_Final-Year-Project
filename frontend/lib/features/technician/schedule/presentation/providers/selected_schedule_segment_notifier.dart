// Holds which Schedule segment the tech has tapped — `upcoming` or
// `past`.
//
// The list notifier `ref.watch`es this provider so a tab change triggers
// a re-build (fresh first-page fetch for the new segment). State is
// intentionally not persisted: a fresh app launch always lands on
// Upcoming, which matches what techs care about first when opening the
// Schedule tab.
//
// The list notifier is `keepAlive: true`, but this provider is **not**
// — it scopes to the screen mount. When the user navigates away and
// back, defaulting to Upcoming is the right reset.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/scheduled_job_segment.dart';

part 'selected_schedule_segment_notifier.g.dart';

@riverpod
class SelectedScheduleSegment extends _$SelectedScheduleSegment {
  @override
  ScheduledJobSegment build() => ScheduledJobSegment.upcoming;

  /// Set the active segment. The list notifier watches this provider
  /// and re-fetches when it changes; calling `set(current)` is a no-op.
  void set(ScheduledJobSegment segment) {
    if (state == segment) return;
    state = segment;
  }
}

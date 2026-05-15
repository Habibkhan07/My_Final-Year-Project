// Contract: fed by `GET /api/technicians/me/scheduled-jobs/` envelope.
// Wire spec: `backend/technicians/api/SCHEDULED_JOBS_API.md` §1.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'scheduled_job.dart';

part 'scheduled_jobs_page.freezed.dart';

/// One page of the technician's scheduled jobs, plus the metadata the
/// list notifier needs to drive pagination, refresh, and offline UX.
///
/// Field notes mirror [BookingsPage] on the customer side. The cursor
/// is opaque — the FE never decodes it. Encoded as base64(JSON{ss, id})
/// by the backend selector for stability across realtime inserts.
@freezed
abstract class ScheduledJobsPage with _$ScheduledJobsPage {
  const factory ScheduledJobsPage({
    required List<ScheduledJob> items,
    required String? nextCursor,
    required bool hasMore,
    required DateTime serverTime,
    @Default(false) bool isStaleCache,
    DateTime? cachedAt,
  }) = _ScheduledJobsPage;
}

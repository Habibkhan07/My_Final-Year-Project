import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../entities/scheduled_job_segment.dart';
import '../entities/scheduled_jobs_counts.dart';
import '../entities/scheduled_jobs_page.dart';

/// Contract for the tech-side scheduled-jobs list + counts endpoints.
///
/// Implementations talk to:
///   * `GET /api/technicians/me/scheduled-jobs/`
///   * `GET /api/technicians/me/scheduled-jobs/counts/`
///
/// See `backend/technicians/api/SCHEDULED_JOBS_API.md` for the full
/// wire contract.
///
/// **Error pipeline contract.** Per CLAUDE.md, every failure surfaces
/// as a typed `ScheduledJobsFailure`. The implementation maps the
/// standard HTTP error envelope to the appropriate sealed subtype.
///
/// **Offline behavior** for [getScheduledJobs]: network-first with a
/// transparent cache fallback on `SocketException`. The returned
/// [ScheduledJobsPage] carries `isStaleCache=true` when served from
/// cache; the notifier surfaces the offline banner. When no cache
/// exists, throws [ScheduledJobsOfflineNoCache].
///
/// [getCounts] is **never** cached — counts are cheap, always live,
/// and stale numbers on the segmented control would mislead the tech.
/// `SocketException` surfaces as [ScheduledJobsOfflineNoCache] directly;
/// the screen renders the badges as `—` while offline.
abstract class IScheduledJobsRepository {
  /// Fetch one page of the tech's scheduled jobs.
  ///
  /// [segment] is the dumb-UI shortcut. [statusFilter] (when non-empty)
  /// overrides the segment-implied status set on the server and is
  /// reserved for future filter chips — v1 list notifier passes null.
  ///
  /// [cursor] is null on the first page; subsequent pages pass the
  /// previous response's `nextCursor` verbatim.
  ///
  /// Throws [ScheduledJobsOfflineNoCache] when offline with no cache.
  /// Throws [ScheduledJobsServerFailure] on HTTP 5xx.
  /// Throws [ScheduledJobsValidationFailure] on HTTP 400.
  /// Throws [UnknownScheduledJobsFailure] otherwise.
  Future<ScheduledJobsPage> getScheduledJobs({
    required ScheduledJobSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  });

  /// Fetch the segmented-control badge counts. Always live — never
  /// cached. See class doc for offline semantics.
  ///
  /// Throws [ScheduledJobsOfflineNoCache] when offline.
  /// Throws [ScheduledJobsServerFailure] on HTTP 5xx.
  /// Throws [UnknownScheduledJobsFailure] otherwise.
  Future<ScheduledJobsCounts> getCounts();
}

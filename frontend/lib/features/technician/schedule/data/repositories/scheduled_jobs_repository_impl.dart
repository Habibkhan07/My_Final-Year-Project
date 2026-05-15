// Scheduled-jobs repository — step 2 of the 4-step error pipeline
// (CLAUDE.md): translates the data-source's [HttpFailure] /
// [SocketException] paths into the domain's typed sealed
// [ScheduledJobsFailure] hierarchy.
//
// **Network-first with cache fallback** for [getScheduledJobs]:
//
//   1. Try the network. Cache the response on success (first page only).
//   2. On [SocketException] **for the first page**: serve cache with
//      `isStaleCache=true`. If no cache exists, throw
//      [ScheduledJobsOfflineNoCache].
//   3. On [SocketException] **for a subsequent page**: throw
//      [ScheduledJobsOfflineNoCache] directly.
//
// [getCounts] is **never** cached — counts are cheap, always live, and
// stale numbers on the segmented control would mislead the tech. Offline
// path throws [ScheduledJobsOfflineNoCache] directly; the screen renders
// the badges as `—` while offline.
import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../domain/entities/scheduled_job_segment.dart';
import '../../domain/entities/scheduled_jobs_counts.dart';
import '../../domain/entities/scheduled_jobs_page.dart';
import '../../domain/failures/scheduled_jobs_failure.dart';
import '../../domain/repositories/scheduled_jobs_repository.dart';
import '../data_sources/scheduled_jobs_local_data_source.dart';
import '../data_sources/scheduled_jobs_remote_data_source.dart';
import '../mappers/scheduled_job_mapper.dart';

class ScheduledJobsRepositoryImpl implements IScheduledJobsRepository {
  final IScheduledJobsRemoteDataSource _remote;
  final IScheduledJobsLocalDataSource _local;

  ScheduledJobsRepositoryImpl({
    required IScheduledJobsRemoteDataSource remote,
    required IScheduledJobsLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  @override
  Future<ScheduledJobsPage> getScheduledJobs({
    required ScheduledJobSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) async {
    final isFirstPage = cursor == null;

    try {
      final response = await _remote.getScheduledJobs(
        segment: segment,
        statusFilter: statusFilter,
        cursor: cursor,
        pageSize: pageSize,
      );

      if (isFirstPage) {
        // Best-effort cache. A failure here must not surface — the
        // caller got their fresh data, and the cache is the rescue path.
        try {
          await _local.cacheFirstPage(segment, response);
        } catch (_) {
          // intentional silent.
        }
      }

      return ScheduledJobMapper.pageFromResponse(response);
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      if (!isFirstPage) {
        throw const ScheduledJobsOfflineNoCache();
      }
      final cached = await _local.getCachedFirstPage(segment);
      if (cached == null) {
        throw const ScheduledJobsOfflineNoCache();
      }
      return ScheduledJobMapper.pageFromResponse(
        cached.response,
        isStaleCache: true,
        cachedAt: cached.cachedAt,
      );
    } on ScheduledJobsFailure {
      rethrow;
    } catch (e) {
      throw UnknownScheduledJobsFailure(e.toString());
    }
  }

  @override
  Future<ScheduledJobsCounts> getCounts() async {
    try {
      final model = await _remote.getCounts();
      return ScheduledJobMapper.countsFromModel(model);
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      throw const ScheduledJobsOfflineNoCache();
    } on ScheduledJobsFailure {
      rethrow;
    } catch (e) {
      throw UnknownScheduledJobsFailure(e.toString());
    }
  }

  /// Wire-code → typed failure switch. Centralised so list and counts
  /// arms agree on the mapping.
  ScheduledJobsFailure _mapHttpFailure(HttpFailure failure) {
    if (failure.statusCode >= 500) {
      return const ScheduledJobsServerFailure();
    }
    if (failure.statusCode == 400) {
      return ScheduledJobsValidationFailure(
        code: failure.code,
        errors: failure.errors,
        message: failure.message.isNotEmpty
            ? failure.message
            : 'Invalid request.',
      );
    }
    // 401/403/404 fall through to Unknown — same rationale as customer
    // side: these indicate auth/deployment mismatch, not normal outcomes.
    return UnknownScheduledJobsFailure(failure.message);
  }
}

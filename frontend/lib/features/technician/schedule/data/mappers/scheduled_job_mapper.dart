// Translates [ScheduledJobModel] (wire) → [ScheduledJob] (domain).
//
// Boundary where wire strings become typed values:
//   * status string ("CONFIRMED") → BookingStatus
//   * tone string ("positive")    → BookingUiTone
//   * ISO-8601 string             → DateTime
//
// The mapper is forgiving: unknown enum strings fall to the `unknown`
// member of each enum (forward-compat with future backend rollouts).
// Unparseable timestamps fall back to `DateTime.now().toUtc()` and log —
// better than throwing into the queue notifier, which would drop the
// entire page.
import 'dart:developer';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../customer/bookings/domain/entities/booking_ui_tone.dart';
import '../../domain/entities/scheduled_job.dart';
import '../../domain/entities/scheduled_jobs_counts.dart';
import '../../domain/entities/scheduled_jobs_page.dart';
import '../models/scheduled_job_model.dart';
import '../models/scheduled_jobs_counts_model.dart';
import '../models/scheduled_jobs_list_response_model.dart';

class ScheduledJobMapper {
  ScheduledJobMapper._();

  static const _logName = 'features.technician.schedule.mapper';

  static ScheduledJob fromModel(ScheduledJobModel model) {
    return ScheduledJob(
      id: model.id,
      status: BookingStatus.fromWire(model.status),
      service: ScheduledJobService(
        name: model.service.name,
        iconName: model.service.iconName,
      ),
      customer: ScheduledJobCustomer(
        id: model.customer.id,
        displayName: model.customer.displayName,
        profilePictureUrl: model.customer.profilePictureUrl,
      ),
      addressLabel: model.addressLabel,
      scheduledStart: _parseIsoOrNow(
        model.scheduledStart,
        model.id,
        'scheduled_start',
      ),
      scheduledEnd: _parseIsoOrNow(
        model.scheduledEnd,
        model.id,
        'scheduled_end',
      ),
      createdAt: _parseIsoOrNow(model.createdAt, model.id, 'created_at'),
      payout: PayoutBlock(
        amount: model.payout.amount,
        context: model.payout.context,
        uiLabel: model.payout.uiLabel,
      ),
      ui: ScheduledJobUi(
        badgeText: model.ui.badgeText,
        badgeTone: BookingUiTone.fromWire(model.ui.badgeTone),
        headline: model.ui.headline,
      ),
    );
  }

  /// Maps the full list response envelope. [isStaleCache] and [cachedAt]
  /// are passed in by the repository when the page came from cache after
  /// a SocketException; the network path passes false / null.
  static ScheduledJobsPage pageFromResponse(
    ScheduledJobsListResponseModel response, {
    bool isStaleCache = false,
    DateTime? cachedAt,
  }) {
    return ScheduledJobsPage(
      items: response.items.map(fromModel).toList(growable: false),
      nextCursor: response.nextCursor,
      hasMore: response.hasMore,
      serverTime: _parseIsoOrNow(response.serverTime, -1, 'server_time'),
      isStaleCache: isStaleCache,
      cachedAt: cachedAt,
    );
  }

  static ScheduledJobsCounts countsFromModel(ScheduledJobsCountsModel model) {
    return ScheduledJobsCounts(
      upcoming: model.upcoming,
      past: model.past,
      serverTime: _parseIsoOrNow(model.serverTime, -1, 'counts.server_time'),
    );
  }

  static DateTime _parseIsoOrNow(String iso, int jobId, String field) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      log(
        'Unparseable $field "$iso" on scheduled job $jobId; falling back to now().',
        name: _logName,
      );
      return DateTime.now().toUtc();
    }
  }
}

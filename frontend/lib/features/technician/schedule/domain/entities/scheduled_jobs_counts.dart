// Contract: fed by `GET /api/technicians/me/scheduled-jobs/counts/`.
// Wire spec: `backend/technicians/api/SCHEDULED_JOBS_API.md` §2.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scheduled_jobs_counts.freezed.dart';

/// Segmented-control badge counts. Two cheap COUNT(*) on the server.
///
/// Note: earnings aggregates are deliberately NOT surfaced here. The
/// Metrics tab owns "how much have I earned"; the Schedule tab owns
/// "what jobs exist". Mixing the two would duplicate responsibility
/// across surfaces — see memory `feedback_wallet_vs_metrics_separation`.
@freezed
abstract class ScheduledJobsCounts with _$ScheduledJobsCounts {
  const factory ScheduledJobsCounts({
    required int upcoming,
    required int past,
    required DateTime serverTime,
  }) = _ScheduledJobsCounts;
}

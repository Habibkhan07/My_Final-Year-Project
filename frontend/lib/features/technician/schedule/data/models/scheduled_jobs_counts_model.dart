// Wire envelope for `GET /api/technicians/me/scheduled-jobs/counts/`.
// Source of truth: `backend/technicians/api/SCHEDULED_JOBS_API.md` §2.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scheduled_jobs_counts_model.freezed.dart';
part 'scheduled_jobs_counts_model.g.dart';

@freezed
abstract class ScheduledJobsCountsModel with _$ScheduledJobsCountsModel {
  const factory ScheduledJobsCountsModel({
    required int upcoming,
    required int past,
    @JsonKey(name: 'server_time') required String serverTime,
  }) = _ScheduledJobsCountsModel;

  factory ScheduledJobsCountsModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduledJobsCountsModelFromJson(json);
}

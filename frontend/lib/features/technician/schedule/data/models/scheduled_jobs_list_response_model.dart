// Wire envelope for `GET /api/technicians/me/scheduled-jobs/`.
// Source of truth: `backend/technicians/api/SCHEDULED_JOBS_API.md` §1.4.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'scheduled_job_model.dart';

part 'scheduled_jobs_list_response_model.freezed.dart';
part 'scheduled_jobs_list_response_model.g.dart';

@freezed
abstract class ScheduledJobsListResponseModel
    with _$ScheduledJobsListResponseModel {
  const factory ScheduledJobsListResponseModel({
    required List<ScheduledJobModel> items,
    @JsonKey(name: 'next_cursor') required String? nextCursor,
    @JsonKey(name: 'has_more') required bool hasMore,
    @JsonKey(name: 'server_time') required String serverTime,
  }) = _ScheduledJobsListResponseModel;

  factory ScheduledJobsListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduledJobsListResponseModelFromJson(json);
}

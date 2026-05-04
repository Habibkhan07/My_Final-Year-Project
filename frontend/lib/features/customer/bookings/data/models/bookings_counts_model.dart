// Wire envelope for `GET /api/bookings/counts/`.
// Source of truth: `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` §2.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookings_counts_model.freezed.dart';
part 'bookings_counts_model.g.dart';

@freezed
abstract class BookingsCountsModel with _$BookingsCountsModel {
  const factory BookingsCountsModel({
    required int upcoming,
    required int past,
    @JsonKey(name: 'server_time') required String serverTime,
  }) = _BookingsCountsModel;

  factory BookingsCountsModel.fromJson(Map<String, dynamic> json) =>
      _$BookingsCountsModelFromJson(json);
}

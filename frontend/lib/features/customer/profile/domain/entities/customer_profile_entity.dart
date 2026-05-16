import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_profile_entity.freezed.dart';
part 'customer_profile_entity.g.dart';

/// The authenticated user's own profile.
///
/// Fed by `GET /api/accounts/me/` and `PATCH /api/accounts/me/`.
/// Both endpoints return the same shape; PATCH responds with the
/// post-update state so the FE notifier can swap its cache directly
/// from the response (no second GET round-trip).
///
/// `phone` and `isTechnician` are read-only from this surface —
/// the backend whitelists only `firstName` / `lastName` for PATCH.
@freezed
abstract class CustomerProfileEntity with _$CustomerProfileEntity {
  const factory CustomerProfileEntity({
    required int id,
    required String phone,
    @Default(false) bool isTechnician,
    String? firstName,
    String? lastName,
  }) = _CustomerProfileEntity;

  factory CustomerProfileEntity.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileEntityFromJson(json);
}

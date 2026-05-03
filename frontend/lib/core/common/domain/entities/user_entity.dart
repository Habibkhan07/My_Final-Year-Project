import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String phone,
    // Numeric `auth.User.id` from the backend. Sourced from
    // /api/accounts/verify-otp/'s `user_id` field. Powers the realtime
    // recipient filter via `currentAuthUserIdProvider` (flag #19).
    // Nullable for two reasons: pre-flag-#19 cached sessions where the
    // backend did not yet return `user_id`, and tests that construct a
    // `UserEntity` without exercising the auth flow.
    int? id,
    String? token,
    String? firstName,
    String? lastName,
    @Default(false) bool isTechnician,
    @Default(false) bool nameRequired,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) => _$UserEntityFromJson(json);
}

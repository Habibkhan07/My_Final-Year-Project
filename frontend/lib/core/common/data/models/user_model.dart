import '../../domain/entities/user_entity.dart';

class UserModel {
  final int? id;
  final String phone;
  final String? token;
  final bool isTechnician;
  final bool nameRequired;

  const UserModel({
    this.id,
    required this.phone,
    this.token,
    this.isTechnician = false,
    this.nameRequired = false,
  });

  // JSON Map -> Dart Object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // `user_id` is the wire field name from /api/accounts/verify-otp/.
      // Nullable — older cached responses (pre-flag-#19) won't carry it.
      id: json['user_id'] as int?,
      phone: json['phone'] ?? '',
      token: json['token'],
      isTechnician: json['is_technician'] ?? false,
      nameRequired: json['name_required'] ?? false,
    );
  }

  // Mapper: Turns this model back into a clean Entity
  UserEntity toEntity() => UserEntity(
    id: id,
    phone: phone,
    token: token,
    isTechnician: isTechnician,
    nameRequired: nameRequired,
  );
}

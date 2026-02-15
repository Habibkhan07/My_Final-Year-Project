import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.phone,
    super.token,
    super.isTechnician,
    super.nameRequired,
  });

  // JSON Map -> Dart Object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      phone: json['phone'] ?? '',
      token: json['token'],
      isTechnician: json['is_technician'] ?? false,
      nameRequired: json['name_required'] ?? false,
    );
  }

  // Mapper: Turns this model back into a clean Entity
  UserEntity toEntity() => UserEntity(
    phone: phone,
    token: token,
    isTechnician: isTechnician,
    nameRequired: nameRequired,
  );
}

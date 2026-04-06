import '../../domain/entities/user_entity.dart';

class UserModel {
  final String phone;
  final String? token;
  final bool isTechnician;
  final bool nameRequired;

  const UserModel({
    required this.phone,
    this.token,
    this.isTechnician = false,
    this.nameRequired = false,
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

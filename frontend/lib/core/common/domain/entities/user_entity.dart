import 'package:equatable/equatable.dart'; //

class UserEntity extends Equatable {
  // 1. Extend Equatable
  final String phone;
  final String? token;
  final String? firstName;
  final String? lastName;
  final bool isTechnician;
  final bool nameRequired;

  const UserEntity({
    required this.phone,
    this.token,
    this.firstName,
    this.lastName,
    this.isTechnician = false,
    this.nameRequired = false,
  });

  // 2. Add the props getter to tell Dart what to compare
  @override
  List<Object?> get props => [
    phone,
    token,
    firstName,
    lastName,
    isTechnician,
    nameRequired,
  ];

  UserEntity copyWith({
    String? firstName,
    String? lastName,
    bool? nameRequired,
    bool? isTechnician, // Added for your upcoming Technician sprint
  }) {
    return UserEntity(
      phone: phone,
      token: token,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nameRequired: nameRequired ?? this.nameRequired,
      isTechnician: isTechnician ?? this.isTechnician,
    );
  }
}

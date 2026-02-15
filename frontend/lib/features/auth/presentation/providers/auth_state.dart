import '../../../../core/common/domain/entities/user_entity.dart';

class AuthState {
  final String? successMessage;
  final UserEntity? user;

  AuthState({this.successMessage, this.user});

  AuthState copyWith({String? successMessage, UserEntity? user}) {
    return AuthState(
      // We explicitly reset successMessage to null if not provided
      successMessage: successMessage,
      user: user ?? this.user,
    );
  }
}

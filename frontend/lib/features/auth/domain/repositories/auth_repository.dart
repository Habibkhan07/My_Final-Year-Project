import '../../../../core/common/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<String> requestOtp(String phone);
  Future<UserEntity> verifyOtp(String phone, String otp);
  Future<String> completeSignup(
    String firstName,
    String lastName,
    String token,
  );

  // Session Management
  Future<UserEntity?> getCachedUser();
  Future<void> logout();
  Future<void> persistUser(UserEntity user);
}

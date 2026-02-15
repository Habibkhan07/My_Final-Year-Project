import '../../../../core/common/domain/entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;
  VerifyOtpUseCase(this.repository);

  Future<UserEntity> execute(String phone, String otp) {
    return repository.verifyOtp(phone, otp);
  }
}

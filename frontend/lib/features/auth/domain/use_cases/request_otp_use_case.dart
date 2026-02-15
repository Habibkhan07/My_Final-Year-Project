import '../repositories/auth_repository.dart';

class RequestOtpUseCase {
  final AuthRepository repository;
  RequestOtpUseCase(this.repository);

  // Now returns Future<String>
  Future<String> execute(String phone) {
    return repository.requestOtp(phone);
  }
}

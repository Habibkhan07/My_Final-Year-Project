import '../repositories/auth_repository.dart';

class CompleteSignupUseCase {
  final AuthRepository repository;
  CompleteSignupUseCase(this.repository);

  Future<String> execute(String firstName, String lastName, String token) {
    return repository.completeSignup(firstName, lastName, token);
  }
}

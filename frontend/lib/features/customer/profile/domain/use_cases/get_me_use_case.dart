import '../entities/customer_profile_entity.dart';
import '../repositories/i_profile_repository.dart';

class GetMeUseCase {
  final IProfileRepository repository;
  const GetMeUseCase(this.repository);

  Future<CustomerProfileEntity> call() => repository.getMe();
}

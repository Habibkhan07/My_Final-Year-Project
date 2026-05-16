import '../entities/customer_profile_entity.dart';
import '../repositories/i_profile_repository.dart';

class UpdateMeUseCase {
  final IProfileRepository repository;
  const UpdateMeUseCase(this.repository);

  Future<CustomerProfileEntity> call({
    required String firstName,
    required String lastName,
  }) => repository.updateMe(firstName: firstName, lastName: lastName);
}

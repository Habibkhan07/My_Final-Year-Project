import '../entities/address_entity.dart';
import '../repositories/i_address_repository.dart';

class UpdateAddressUseCase {
  final IAddressRepository repository;

  const UpdateAddressUseCase(this.repository);

  Future<CustomerAddressEntity> call({
    required int id,
    bool? isDefault,
    String? label,
    String? streetAddress,
    double? latitude,
    double? longitude,
  }) {
    return repository.updateAddress(
      id: id,
      isDefault: isDefault,
      label: label,
      streetAddress: streetAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

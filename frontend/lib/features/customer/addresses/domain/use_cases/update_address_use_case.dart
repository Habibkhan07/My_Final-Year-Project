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
    String? neighborhood,
    String? suburb,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? localityLabel,
  }) {
    return repository.updateAddress(
      id: id,
      isDefault: isDefault,
      label: label,
      streetAddress: streetAddress,
      latitude: latitude,
      longitude: longitude,
      neighborhood: neighborhood,
      suburb: suburb,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      localityLabel: localityLabel,
    );
  }
}

import '../entities/address_entity.dart';
import '../repositories/i_address_repository.dart';

/// Creates a new saved address for the authenticated customer.
///
/// Thin delegate — all error mapping is in [IAddressRepository].
/// Throws [AddressFailure] on any failure.
class SaveAddressUseCase {
  final IAddressRepository repository;
  const SaveAddressUseCase(this.repository);

  Future<CustomerAddressEntity> call({
    required String label,
    required String streetAddress,
    required double latitude,
    required double longitude,
    required bool isDefault,
    String? neighborhood,
    String? suburb,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? localityLabel,
  }) => repository.saveAddress(
    label: label,
    streetAddress: streetAddress,
    latitude: latitude,
    longitude: longitude,
    isDefault: isDefault,
    neighborhood: neighborhood,
    suburb: suburb,
    city: city,
    state: state,
    country: country,
    postalCode: postalCode,
    localityLabel: localityLabel,
  );
}

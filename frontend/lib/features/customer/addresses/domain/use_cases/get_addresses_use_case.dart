import '../entities/address_entity.dart';
import '../repositories/i_address_repository.dart';

/// Fetches all saved addresses for the authenticated customer.
///
/// Thin delegate — all error mapping is in [IAddressRepository].
/// Throws [AddressFailure] on any failure.
class GetAddressesUseCase {
  final IAddressRepository repository;
  const GetAddressesUseCase(this.repository);

  Future<List<CustomerAddressEntity>> call() => repository.getAddresses();
}

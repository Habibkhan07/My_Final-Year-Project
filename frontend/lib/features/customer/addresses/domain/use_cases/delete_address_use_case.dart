import '../repositories/i_address_repository.dart';

/// Deletes a saved address by id.
///
/// Thin delegate — all error mapping is in [IAddressRepository].
/// Throws [AddressNotFoundFailure] if the id doesn't exist or is owned by
/// another user (IDOR: both cases are indistinguishable to the caller).
class DeleteAddressUseCase {
  final IAddressRepository repository;
  const DeleteAddressUseCase(this.repository);

  Future<void> call(int id) => repository.deleteAddress(id);
}

/// Contract: Fed by GET /api/customers/addresses/ and POST /api/customers/addresses/
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_entity.freezed.dart';

/// A saved customer address.
///
/// [isDefault] is the source of truth for which address pre-fills on booking.
/// Flutter must never compute this locally — always read from backend.
@freezed
abstract class CustomerAddressEntity with _$CustomerAddressEntity {
  const factory CustomerAddressEntity({
    required int id,
    required String label,
    required String streetAddress,
    required double latitude,
    required double longitude,
    required bool isDefault,
    required String createdAt,
  }) = _CustomerAddressEntity;
}

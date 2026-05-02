/// Contract: Fed by GET /api/customers/addresses/ and POST /api/customers/addresses/
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_entity.freezed.dart';

/// A saved customer address.
///
/// [isDefault] is the source of truth for which address pre-fills on booking.
/// Flutter must never compute this locally — always read from backend.
///
/// The 7 nullable structured locality fields are populated client-side at save
/// time via the configured [GeocodingDataSource] (Google in prod, OSM in dev).
/// Backend stores them verbatim. Legacy rows created before this rollout have
/// `null` for every structured field — UI must fall back to [streetAddress]
/// when [localityLabel] is null.
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
    String? neighborhood,
    String? suburb,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? localityLabel,
  }) = _CustomerAddressEntity;
}

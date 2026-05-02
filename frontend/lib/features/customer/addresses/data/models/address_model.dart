import '../../domain/entities/address_entity.dart';

/// JSON ↔ Dart mapping for GET /api/customers/addresses/ list items
/// and the POST /api/customers/addresses/ response body.
class CustomerAddressModel {
  final int id;
  final String label;
  final String streetAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String createdAt;

  // Client-supplied structured locality fields. Nullable for legacy rows
  // created before this rollout, and for cases where the geocoder returned
  // partial coverage (rural areas, etc.).
  final String? neighborhood;
  final String? suburb;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? localityLabel;

  const CustomerAddressModel({
    required this.id,
    required this.label,
    required this.streetAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
    this.neighborhood,
    this.suburb,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.localityLabel,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) =>
      CustomerAddressModel(
        id: json['id'] as int,
        label: json['label'] as String,
        streetAddress: json['street_address'] as String,
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
        isDefault: json['is_default'] as bool,
        createdAt: json['created_at'] as String,
        neighborhood: json['neighborhood'] as String?,
        suburb: json['suburb'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        country: json['country'] as String?,
        postalCode: json['postal_code'] as String?,
        localityLabel: json['locality_label'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'street_address': streetAddress,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
        'created_at': createdAt,
        'neighborhood': neighborhood,
        'suburb': suburb,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'locality_label': localityLabel,
      };

  CustomerAddressEntity toEntity() => CustomerAddressEntity(
        id: id,
        label: label,
        streetAddress: streetAddress,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
        createdAt: createdAt,
        neighborhood: neighborhood,
        suburb: suburb,
        city: city,
        state: state,
        country: country,
        postalCode: postalCode,
        localityLabel: localityLabel,
      );
}

/// Outgoing POST body for POST /api/customers/addresses/.
///
/// All structured locality fields are nullable. The backend serializer marks
/// them optional+allow_null, so omitting them or sending null both work; we
/// always send the keys (null when absent) for wire-shape consistency.
class CreateAddressRequest {
  final String label;
  final String streetAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;

  final String? neighborhood;
  final String? suburb;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? localityLabel;

  const CreateAddressRequest({
    required this.label,
    required this.streetAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.neighborhood,
    this.suburb,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.localityLabel,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'street_address': streetAddress,
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
        'is_default': isDefault,
        'neighborhood': neighborhood,
        'suburb': suburb,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'locality_label': localityLabel,
      };
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

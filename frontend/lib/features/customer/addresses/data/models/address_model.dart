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

  const CustomerAddressModel({
    required this.id,
    required this.label,
    required this.streetAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'street_address': streetAddress,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
        'created_at': createdAt,
      };

  CustomerAddressEntity toEntity() => CustomerAddressEntity(
        id: id,
        label: label,
        streetAddress: streetAddress,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
        createdAt: createdAt,
      );
}

/// Outgoing POST body for POST /api/customers/addresses/
class CreateAddressRequest {
  final String label;
  final String streetAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const CreateAddressRequest({
    required this.label,
    required this.streetAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'street_address': streetAddress,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      };
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

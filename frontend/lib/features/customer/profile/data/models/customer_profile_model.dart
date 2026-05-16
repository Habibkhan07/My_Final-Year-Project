import '../../domain/entities/customer_profile_entity.dart';

/// Wire model for `GET / PATCH /api/accounts/me/`.
///
/// Separate from [CustomerProfileEntity] so the snake_case wire field
/// names live exactly here and nowhere else. Conversion is one-way at
/// `toEntity()` — the domain layer never sees the JSON shape.
class CustomerProfileModel {
  final int id;
  final String phone;
  final bool isTechnician;
  final String? firstName;
  final String? lastName;

  const CustomerProfileModel({
    required this.id,
    required this.phone,
    required this.isTechnician,
    this.firstName,
    this.lastName,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      id: json['id'] as int,
      phone: json['phone'] as String? ?? '',
      isTechnician: json['is_technician'] as bool? ?? false,
      // Empty strings come through as "" not null — normalize so the
      // header card can do `firstName?.isEmpty ?? true` cleanly.
      firstName: _nullIfEmpty(json['first_name'] as String?),
      lastName: _nullIfEmpty(json['last_name'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'is_technician': isTechnician,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
      };

  CustomerProfileEntity toEntity() => CustomerProfileEntity(
        id: id,
        phone: phone,
        isTechnician: isTechnician,
        firstName: firstName,
        lastName: lastName,
      );

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.isEmpty) ? null : s;
}

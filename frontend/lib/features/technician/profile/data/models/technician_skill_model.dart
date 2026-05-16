import '../../domain/entities/technician_skill_entity.dart';

/// Wire model for one row from `GET /api/technicians/me/skills/`.
///
/// Plain Dart (not Freezed) so the snake_case wire field names live
/// exactly here, mirroring the customer profile model's pattern. The
/// domain layer only ever sees [TechnicianSkillEntity] via [toEntity].
class TechnicianSkillModel {
  final int id;
  final int subServiceId;
  final String subServiceName;
  final String? subServiceIconName;
  final bool isFixedPrice;
  final int parentServiceId;
  final String parentServiceName;
  final String? parentServiceIconName;

  const TechnicianSkillModel({
    required this.id,
    required this.subServiceId,
    required this.subServiceName,
    required this.subServiceIconName,
    required this.isFixedPrice,
    required this.parentServiceId,
    required this.parentServiceName,
    required this.parentServiceIconName,
  });

  factory TechnicianSkillModel.fromJson(Map<String, dynamic> json) {
    final sub = json['sub_service'] as Map<String, dynamic>;
    final service = sub['service'] as Map<String, dynamic>;
    return TechnicianSkillModel(
      id: json['id'] as int,
      subServiceId: sub['id'] as int,
      subServiceName: sub['name'] as String,
      subServiceIconName: sub['icon_name'] as String?,
      isFixedPrice: sub['is_fixed_price'] as bool? ?? false,
      parentServiceId: service['id'] as int,
      parentServiceName: service['name'] as String,
      parentServiceIconName: service['icon_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sub_service': {
          'id': subServiceId,
          'name': subServiceName,
          'icon_name': subServiceIconName,
          'is_fixed_price': isFixedPrice,
          'service': {
            'id': parentServiceId,
            'name': parentServiceName,
            'icon_name': parentServiceIconName,
          },
        },
      };

  TechnicianSkillEntity toEntity() => TechnicianSkillEntity(
        id: id,
        subService: SubServiceRef(
          id: subServiceId,
          name: subServiceName,
          iconName: subServiceIconName,
          isFixedPrice: isFixedPrice,
          service: ParentServiceRef(
            id: parentServiceId,
            name: parentServiceName,
            iconName: parentServiceIconName,
          ),
        ),
      );
}

import '../../domain/entities/available_sub_service_entity.dart';

/// Wire model for one service in `GET /api/technicians/onboarding/metadata/`.
///
/// The onboarding metadata endpoint already returns the full service
/// tree (services with sub_services nested). We reuse it for the Add
/// Skill picker rather than introduce a second catalog endpoint — the
/// data needed is identical.
class AvailableServiceModel {
  final int id;
  final String name;
  final String? iconName;
  final List<AvailableSubServiceModel> subServices;

  const AvailableServiceModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.subServices,
  });

  factory AvailableServiceModel.fromJson(Map<String, dynamic> json) {
    return AvailableServiceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      iconName: json['icon_name'] as String?,
      subServices: ((json['sub_services'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(AvailableSubServiceModel.fromJson)
          .toList(growable: false),
    );
  }

  AvailableServiceEntity toEntity() => AvailableServiceEntity(
        id: id,
        name: name,
        iconName: iconName,
        subServices: subServices.map((s) => s.toEntity()).toList(growable: false),
      );
}

class AvailableSubServiceModel {
  final int id;
  final String name;
  final String? iconName;
  final bool isFixedPrice;

  const AvailableSubServiceModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.isFixedPrice,
  });

  factory AvailableSubServiceModel.fromJson(Map<String, dynamic> json) {
    return AvailableSubServiceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      iconName: json['icon_name'] as String?,
      isFixedPrice: json['is_fixed_price'] as bool? ?? false,
    );
  }

  AvailableSubServiceEntity toEntity() => AvailableSubServiceEntity(
        id: id,
        name: name,
        iconName: iconName,
        isFixedPrice: isFixedPrice,
      );
}

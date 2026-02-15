// feature/technician/onboarding/data/models/service_model.dart

class ServiceModel {
  final int id;
  final String name;
  final List<SubServiceModel> subServices;

  ServiceModel({
    required this.id,
    required this.name,
    required this.subServices,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'], // Matches Django Service.id
      name: json['name'], // Matches Django Service.name
      subServices:
          (json['sub_services'] as List? ??
                  []) // Handle null by returning empty list
              .map((i) => SubServiceModel.fromJson(i))
              .toList(),
    );
  }

  // Used if you ever need to cache this data locally
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sub_services': subServices.map((s) => s.toJson()).toList(),
    };
  }
}

class SubServiceModel {
  final int id;
  final String name;
  final double basePrice;

  SubServiceModel({
    required this.id,
    required this.name,
    required this.basePrice,
  });

  factory SubServiceModel.fromJson(Map<String, dynamic> json) {
    return SubServiceModel(
      id: json['id'], // Matches Django SubService.id
      name: json['name'], // Matches Django SubService.name
      // Ensuring the price is treated as a double even if it comes as a string or int
      basePrice: double.parse(json['base_price'].toString()), //
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'base_price': basePrice};
  }
}

// domain/entities/category_license_entity.dart
import 'package:equatable/equatable.dart';

class CategoryLicenseEntity extends Equatable {
  final int serviceId;
  final String mediaUuid;

  const CategoryLicenseEntity({
    required this.serviceId,
    required this.mediaUuid,
  });

  @override
  List<Object?> get props => [serviceId, mediaUuid];
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_license_entity.freezed.dart';

/// [CategoryLicenseEntity] maps a service category to a certification image.
/// FLOW: Uploaded in Onboarding Step 4
@freezed
abstract class CategoryLicenseEntity with _$CategoryLicenseEntity {
  const factory CategoryLicenseEntity({
    required int serviceId,
    required String mediaUuid,
  }) = _CategoryLicenseEntity;
}

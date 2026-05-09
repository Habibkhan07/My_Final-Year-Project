import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/booking_entities.dart';
import 'dependency_injection.dart';
import '../../../customer/addresses/presentation/providers/dependency_injection.dart';

part 'technician_profile_notifier.g.dart';

@riverpod
class TechnicianProfileNotifier extends _$TechnicianProfileNotifier {
  @override
  Future<TechnicianProfileEntity> build({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  }) async {
    // Prefer explicit coordinates, fallback to global default address
    double? effectiveLat = lat;
    double? effectiveLng = lng;

    if (effectiveLat == null || effectiveLng == null) {
      final defaultAddress = await ref.watch(defaultAddressProvider.future);
      effectiveLat = defaultAddress?.latitude;
      effectiveLng = defaultAddress?.longitude;
    }

    return ref
        .read(getTechnicianProfileUseCaseProvider)
        .call(
          id: id,
          lat: effectiveLat,
          lng: effectiveLng,
          serviceId: serviceId,
          subServiceId: subServiceId,
          promotionId: promotionId,
        );
  }
}

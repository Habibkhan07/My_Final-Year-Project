import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/booking_entities.dart';
import 'dependency_injection.dart';

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
    return ref.read(getTechnicianProfileUseCaseProvider).call(
          id: id,
          lat: lat,
          lng: lng,
          serviceId: serviceId,
          subServiceId: subServiceId,
          promotionId: promotionId,
        );
  }
}

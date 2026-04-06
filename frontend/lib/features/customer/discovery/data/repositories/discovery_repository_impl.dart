import 'dart:io';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/discovery_entities.dart';
import '../../domain/failures/discovery_failure.dart';
import '../../domain/repositories/i_discovery_repository.dart';
import '../data_sources/discovery_remote_data_source.dart';

class DiscoveryRepositoryImpl implements IDiscoveryRepository {
  final IDiscoveryRemoteDataSource remoteDataSource;

  DiscoveryRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<DiscoveryResultEntity> getNearbyTechnicians({
    double? lat,
    double? lng,
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    int page = 1,
  }) async {
    try {
      final model = await remoteDataSource.getNearbyTechnicians(
        lat: lat,
        lng: lng,
        query: query,
        serviceId: serviceId,
        subServiceId: subServiceId,
        promotionId: promotionId,
        page: page,
      );

      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapHttpFailureToDomain(e);
    } on SocketException {
      throw const DiscoveryNetworkFailure();
    } on FormatException {
      throw const DiscoveryUnexpectedFailure('Parsing error: Invalid JSON format.');
    } catch (e) {
      throw DiscoveryUnexpectedFailure(e.toString());
    }
  }

  DiscoveryFailure _mapHttpFailureToDomain(HttpFailure failure) {
    switch (failure.code) {
      case 'validation_error':
        return DiscoveryValidationFailure(
          message: failure.message,
          errors: failure.errors.map((key, value) => MapEntry(key, List<String>.from(value))),
        );
      case 'unauthorized':
        return const DiscoveryUnauthorizedFailure();
      case 'resource_not_found':
        return DiscoveryNotFoundFailure(failure.message);
      case 'server_error':
        return const DiscoveryServerFailure();
      default:
        return DiscoveryUnexpectedFailure(failure.message);
    }
  }
}

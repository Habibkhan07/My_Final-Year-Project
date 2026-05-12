import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/technician_metrics_entity.dart';
import '../../domain/failures/metrics_failure.dart';
import '../../domain/repositories/metrics_repository.dart';
import '../data_sources/metrics_remote_data_source.dart';

class MetricsRepositoryImpl implements MetricsRepository {
  final IMetricsRemoteDataSource remoteDataSource;

  MetricsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<TechnicianMetricsEntity> getMetrics() async {
    try {
      final model = await remoteDataSource.getMetrics();
      return model.toEntity();
    } on HttpFailure catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw const MetricsPermissionFailure();
      }
      throw const MetricsServerFailure();
    } on SocketException catch (_) {
      throw const MetricsNetworkFailure();
    } on FormatException catch (_) {
      throw const MetricsServerFailure();
    }
  }
}

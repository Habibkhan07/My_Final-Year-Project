import 'dart:io';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/technician_dashboard_entity.dart';
import '../../domain/failures/technician_dashboard_failure.dart';
import '../../domain/repositories/technician_dashboard_repository.dart';
import '../data_sources/technician_dashboard_local_data_source.dart';
import '../data_sources/technician_dashboard_remote_data_source.dart';

class TechnicianDashboardRepositoryImpl implements TechnicianDashboardRepository {
  final ITechnicianDashboardRemoteDataSource remoteDataSource;
  final TechnicianDashboardLocalDataSource localDataSource;

  TechnicianDashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<TechnicianDashboardEntity> getDashboard() async {
    try {
      final model = await remoteDataSource.getDashboard();
      // Cache for offline access
      await localDataSource.cacheDashboard(model);
      return model.toEntity();
    } on HttpFailure catch (e) {
      if (e.statusCode == 403) {
        throw const DashboardPermissionFailure();
      }
      throw DashboardServerFailure(e.message);
    } on SocketException catch (_) {
      // Offline-First: Try to return cached data
      final cachedModel = await localDataSource.getCachedDashboard();
      if (cachedModel != null) {
        return cachedModel.toEntity();
      }
      throw const DashboardNetworkFailure();
    } on FormatException catch (_) {
      throw const DashboardParsingFailure();
    } catch (e) {
      // In production, log this to Sentry/Firebase
      throw DashboardServerFailure("Unexpected error: ${e.toString()}");
    }
  }
}

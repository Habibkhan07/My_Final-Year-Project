import 'dart:io';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/technician_status.dart';
import '../../domain/failures/tech_status_failure.dart';
import '../../domain/repositories/technician_status_repository.dart';
import '../data_sources/technician_status_remote_data_source.dart';

class TechnicianStatusRepositoryImpl implements TechnicianStatusRepository {
  final TechnicianStatusRemoteDataSource remoteDataSource;

  TechnicianStatusRepositoryImpl(this.remoteDataSource);

  @override
  Future<TechnicianStatus> getMyStatus() async {
    try {
      final model = await remoteDataSource.getMyStatus();
      return model.toEntity();
    } on HttpFailure catch (e) {
      // `not_authenticated` is DRF's default code for missing/expired
      // token. Map both 401 status and the wire code so a non-standard
      // backend response still routes through unauthorized.
      if (e.statusCode == 401 || e.code == 'not_authenticated') {
        throw const TechStatusUnauthorized();
      }
      throw TechStatusServerFailure(e.message);
    } on SocketException catch (_) {
      throw const TechStatusNetworkFailure();
    } on FormatException catch (_) {
      throw const TechStatusServerFailure('Invalid response from server');
    }
  }
}

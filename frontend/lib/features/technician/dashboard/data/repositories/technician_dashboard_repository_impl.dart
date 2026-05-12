import 'dart:io';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/technician_dashboard_entity.dart';
import '../../domain/failures/technician_dashboard_failure.dart';
import '../../domain/repositories/technician_dashboard_repository.dart';
import '../data_sources/technician_dashboard_local_data_source.dart';
import '../data_sources/technician_dashboard_remote_data_source.dart';

class TechnicianDashboardRepositoryImpl
    implements TechnicianDashboardRepository {
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
      // **No cache fallback for the dashboard.** Per CLAUDE.md Tier 3
      // storage rule: "Local cache is UX only, never source of truth
      // for wallet balances or payment status." The dashboard entity
      // carries `walletBalance` + `cashCollectedToday` + `isOnline` —
      // all three are financial-truth fields and the tech makes
      // job-acceptance decisions based on them (wallet-lockout
      // threshold). Showing yesterday's wallet balance with no
      // staleness indicator would let the tech accept jobs they can
      // no longer service after an over-the-air commission deduction
      // settled. Better to surface the offline error explicitly via
      // the existing `DashboardNetworkFailure` so the screen prompts
      // reconnect rather than rendering a wrong number.
      //
      // The cache write path on the success branch above still runs
      // — non-financial features (e.g. up-next display name shown on
      // an offline notification tap, if we ever add that) can read it
      // safely. The repository read path is the one that must refuse
      // cache.
      throw const DashboardNetworkFailure();
    } on FormatException catch (_) {
      throw const DashboardParsingFailure();
    } catch (e) {
      // In production, log this to Sentry/Firebase
      throw DashboardServerFailure("Unexpected error: ${e.toString()}");
    }
  }
}

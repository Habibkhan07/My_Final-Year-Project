import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/data_sources/technician_dashboard_local_data_source.dart';
import '../../data/data_sources/technician_dashboard_remote_data_source.dart';
import '../../data/repositories/technician_dashboard_repository_impl.dart';
import '../../domain/repositories/technician_dashboard_repository.dart';
// SharedPreferences is exposed by the onboarding feature's DI and overridden
// in main() with the async-loaded instance. Reusing the same provider keeps
// every feature pointed at the same backing store, which is what FCM/event
// background isolates expect when they cache or read low-urgency updates.
import '../../../onboarding/presentation/providers/dependency_injection.dart';

part 'dependency_injection.g.dart';

/// Dedicated http client for the dashboard remote source. Kept separate
/// from other features' clients so disposing one doesn't ripple into the
/// dashboard's in-flight requests.
@Riverpod(keepAlive: true)
http.Client technicianDashboardHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@riverpod
ITechnicianDashboardRemoteDataSource technicianDashboardRemoteDataSource(
  Ref ref,
) {
  return TechnicianDashboardRemoteDataSource(
    client: ref.watch(technicianDashboardHttpClientProvider),
  );
}

@riverpod
TechnicianDashboardLocalDataSource technicianDashboardLocalDataSource(Ref ref) {
  return TechnicianDashboardLocalDataSourceImpl(
    ref.watch(sharedPreferencesProvider),
  );
}

@riverpod
TechnicianDashboardRepository technicianDashboardRepository(Ref ref) {
  return TechnicianDashboardRepositoryImpl(
    remoteDataSource: ref.watch(technicianDashboardRemoteDataSourceProvider),
    localDataSource: ref.watch(technicianDashboardLocalDataSourceProvider),
  );
}

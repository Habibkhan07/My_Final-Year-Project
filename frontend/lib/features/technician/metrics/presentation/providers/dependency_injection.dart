import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../auth/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/metrics_remote_data_source.dart';
import '../../data/repositories/metrics_repository_impl.dart';
import '../../domain/repositories/metrics_repository.dart';

part 'dependency_injection.g.dart';

@Riverpod(keepAlive: true)
http.Client metricsHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
IMetricsRemoteDataSource metricsRemoteDataSource(Ref ref) {
  return MetricsRemoteDataSource(
    client: ref.watch(metricsHttpClientProvider),
    authLocalDataSource: ref.watch(authLocalDataSourceProvider),
  );
}

@Riverpod(keepAlive: true)
MetricsRepository metricsRepository(Ref ref) {
  return MetricsRepositoryImpl(
    remoteDataSource: ref.watch(metricsRemoteDataSourceProvider),
  );
}

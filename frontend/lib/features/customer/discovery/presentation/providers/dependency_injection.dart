import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

import '../../data/data_sources/discovery_remote_data_source.dart';
import '../../data/repositories/discovery_repository_impl.dart';
import '../../domain/repositories/i_discovery_repository.dart';
import '../../domain/usecases/get_nearby_technicians_usecase.dart';

part 'dependency_injection.g.dart';

@Riverpod(keepAlive: true)
http.Client httpClient(Ref ref) {
  return http.Client();
}

@Riverpod(keepAlive: true)
IDiscoveryRemoteDataSource discoveryRemoteDataSource(Ref ref) {
  final client = ref.watch(httpClientProvider);
  return DiscoveryRemoteDataSource(client: client);
}

@Riverpod(keepAlive: true)
IDiscoveryRepository discoveryRepository(Ref ref) {
  final remote = ref.watch(discoveryRemoteDataSourceProvider);
  return DiscoveryRepositoryImpl(
    remoteDataSource: remote,
  );
}

@Riverpod(keepAlive: true)
GetNearbyTechniciansUseCase getNearbyTechniciansUseCase(Ref ref) {
  final repository = ref.watch(discoveryRepositoryProvider);
  return GetNearbyTechniciansUseCase(repository);
}

// lib/features/customer/home/data/repositories/home_repository_impl.dart
import 'dart:io';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/home_feed_entity.dart';
import '../../domain/failures/home_failure.dart';
import '../../domain/repositories/home_repository.dart';
import '../data_sources/home_remote_data_source.dart';
import '../data_sources/home_local_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;

  HomeRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<HomeFeedEntity> getHomeFeed({double? lat, double? lng}) async {
    try {
      final model = await remoteDataSource.getHomeFeed(lat: lat, lng: lng);
      // Cache the fresh data
      await localDataSource.cacheHomeFeed(model);
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw HomeServerFailure(e.message);
    } on SocketException catch (_) {
      // Try to return cached data on network failure
      final cachedModel = await localDataSource.getCachedHomeFeed();
      if (cachedModel != null) {
        return cachedModel.toEntity();
      }
      throw const HomeNetworkFailure();
    } on FormatException catch (_) {
      throw const HomeParsingFailure();
    } catch (e) {
      throw HomeServerFailure("Unexpected error: ${e.toString()}");
    }
  }
}

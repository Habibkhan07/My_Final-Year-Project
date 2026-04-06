// lib/features/customer/home/domain/usecases/get_home_feed_usecase.dart
import '../entities/home_feed_entity.dart';
import '../repositories/home_repository.dart';

class GetHomeFeedUseCase {
  final HomeRepository repository;

  GetHomeFeedUseCase(this.repository);

  Future<HomeFeedEntity> call({double? lat, double? lng}) {
    return repository.getHomeFeed(lat: lat, lng: lng);
  }
}

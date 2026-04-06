// lib/features/customer/home/domain/repositories/home_repository.dart
import '../entities/home_feed_entity.dart';
import '../failures/home_failure.dart';

abstract class HomeRepository {
  /// Fetches the aggregated home feed for the customer discovery screen.
  /// 
  /// The [lat] and [lng] parameters are optional. If provided, the backend 
  /// calculates [distanceKm] for the technicians using Haversine logic.
  /// If omitted or invalid, the backend safely falls back to a global list.
  ///
  /// Throws [HomeNetworkFailure] if there is a SocketException.
  /// Throws [HomeServerFailure] if the backend returns a 500 error.
  /// Throws [HomeParsingFailure] if the JSON contract changes unexpectedly.
  Future<HomeFeedEntity> getHomeFeed({double? lat, double? lng});
}

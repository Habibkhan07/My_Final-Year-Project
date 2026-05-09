import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/discovery_entities.dart';

part 'discovery_state.freezed.dart';

@freezed
abstract class DiscoveryState with _$DiscoveryState {
  const factory DiscoveryState({
    /// The current page of results.
    DiscoveryResultEntity? discoveryResult,

    /// Current search/filter parameters to allow refresh or pagination.
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    double? lat,
    double? lng,

    /// Tracks if we are currently fetching the NEXT page.
    @Default(false) bool isPaginationLoading,
  }) = _DiscoveryState;
}

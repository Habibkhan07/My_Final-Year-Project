import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/home_feed_entity.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const HomeState._();

  const factory HomeState({
    HomeFeedEntity? homeFeed,
    double? lastLat,
    double? lastLng,
  }) = _HomeState;
}

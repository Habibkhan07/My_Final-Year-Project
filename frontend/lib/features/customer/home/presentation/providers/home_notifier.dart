import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'home_state.dart';
import 'dependency_injection.dart';

part 'home_notifier.g.dart';

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  FutureOr<HomeState> build() async {
    // Fetch the home feed data initially
    final feed = await ref.read(getHomeFeedUseCaseProvider).call();
    
    return HomeState(
      homeFeed: feed,
      lastLat: null,
      lastLng: null,
    );
  }

  Future<void> fetchHomeFeed({double? lat, double? lng}) async {
    // AsyncValue.guard automatically handles Loading and Error states for you
    state = await AsyncValue.guard(() async {
      final feed = await ref.read(getHomeFeedUseCaseProvider).call(lat: lat, lng: lng);
      return state.requireValue.copyWith(
        homeFeed: feed,
        lastLat: lat,
        lastLng: lng,
      );
    });
  }
}

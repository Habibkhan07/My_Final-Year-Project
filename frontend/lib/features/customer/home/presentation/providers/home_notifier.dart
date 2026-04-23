import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'home_state.dart';
import 'dependency_injection.dart';
import '../../../../customer/addresses/presentation/providers/dependency_injection.dart';

part 'home_notifier.g.dart';

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  FutureOr<HomeState> build() async {
    // Watch the default address so the home feed automatically re-fetches
    // when the user changes their location.
    final address = await ref.watch(defaultAddressProvider.future);
    
    // Fetch the home feed data with location context
    final feed = await ref.read(getHomeFeedUseCaseProvider).call(
      lat: address?.latitude,
      lng: address?.longitude,
    );
    
    return HomeState(
      homeFeed: feed,
      lastLat: address?.latitude,
      lastLng: address?.longitude,
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

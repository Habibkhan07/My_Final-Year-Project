import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'discovery_state.dart';
import 'dependency_injection.dart';
import '../../../../customer/addresses/presentation/providers/dependency_injection.dart';

part 'discovery_notifier.g.dart';

/// Notifier responsible for managing the state of the Technician Discovery result list.
///
/// **Intent**: Uses structured error handling to ensure that all network/server failures
/// are correctly propagated through the [DiscoveryFailure] pipeline defined in the domain layer,
/// without dropping existing loaded data.
@riverpod
class DiscoveryNotifier extends _$DiscoveryNotifier {
  @override
  FutureOr<DiscoveryState> build({
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    double? lat,
    double? lng,
  }) async {
    // Prefer explicit coordinates, fallback to global default address
    double? effectiveLat = lat;
    double? effectiveLng = lng;

    if (effectiveLat == null || effectiveLng == null) {
      final defaultAddress = await ref.watch(defaultAddressProvider.future);
      effectiveLat = defaultAddress?.latitude;
      effectiveLng = defaultAddress?.longitude;
    }

    // Initial fetch on build
    final result = await ref
        .read(getNearbyTechniciansUseCaseProvider)
        .call(
          query: query,
          serviceId: serviceId,
          subServiceId: subServiceId,
          promotionId: promotionId,
          lat: effectiveLat,
          lng: effectiveLng,
          page: 1,
        );

    return DiscoveryState(
      discoveryResult: result,
      query: query,
      serviceId: serviceId,
      subServiceId: subServiceId,
      promotionId: promotionId,
      lat: effectiveLat,
      lng: effectiveLng,
    );
  }

  /// Refreshes the discovery list from page 1 using the original filters.
  ///
  /// **Safe Execution**: Can be called safely even if the initial [build] failed
  /// (meaning [state.hasValue] is false). It uses the provider's inherent arguments.
  Future<void> refresh() async {
    // Capture previous state if any, to avoid completely blanking the screen on refresh.
    final previousData = state.value;
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      double? effectiveLat = lat;
      double? effectiveLng = lng;

      if (effectiveLat == null || effectiveLng == null) {
        final defaultAddress = await ref.read(defaultAddressProvider.future);
        effectiveLat = defaultAddress?.latitude;
        effectiveLng = defaultAddress?.longitude;
      }

      final result = await ref
          .read(getNearbyTechniciansUseCaseProvider)
          .call(
            query: query,
            serviceId: serviceId,
            subServiceId: subServiceId,
            promotionId: promotionId,
            lat: effectiveLat,
            lng: effectiveLng,
            page: 1,
          );

      // If we had a previous state structure, preserve it, else create a fresh one.
      return previousData?.copyWith(discoveryResult: result) ??
          DiscoveryState(
            discoveryResult: result,
            query: query,
            serviceId: serviceId,
            subServiceId: subServiceId,
            promotionId: promotionId,
            lat: effectiveLat,
            lng: effectiveLng,
          );
    });
  }

  /// Fetches the next page of results and appends them to the current list.
  ///
  /// **Bulletproof Data Access**: Guards against being called when state has
  /// crashed or is currently loading. Manual try/catch preserves the list data
  /// even if pagination throws an error.
  Future<void> loadMore() async {
    // If the provider doesn't have a valid underlying value, we cannot paginate.
    final currentState = state.value;
    if (currentState == null) return;

    final currentResult = currentState.discoveryResult;

    // If there is no next page or we are already loading, exit early.
    if (currentResult?.next == null || currentState.isPaginationLoading) return;

    // Set pagination loading to true without dropping current data
    state = AsyncData(currentState.copyWith(isPaginationLoading: true));

    final nextPageUri = Uri.parse(currentResult!.next!);
    final nextPage =
        int.tryParse(nextPageUri.queryParameters['page'] ?? '') ?? 1;

    try {
      final newResult = await ref
          .read(getNearbyTechniciansUseCaseProvider)
          .call(
            query: query,
            serviceId: serviceId,
            subServiceId: subServiceId,
            promotionId: promotionId,
            lat: currentState
                .lat, // Use the effective coordinates stored in the state
            lng: currentState.lng,
            page: nextPage,
          );

      state = AsyncData(
        currentState.copyWith(
          isPaginationLoading: false,
          discoveryResult: newResult.copyWith(
            results: [...currentResult.results, ...newResult.results],
          ),
        ),
      );
    } catch (error, stackTrace) {
      // Revert the `isPaginationLoading` flag but wrap the current state
      // inside an AsyncError to trigger the presentation layer UI error feedback
      // while retaining the already loaded list.
      state = AsyncError<DiscoveryState>(error, stackTrace).copyWithPrevious(
        AsyncData(currentState.copyWith(isPaginationLoading: false)),
      );
    }
  }
}

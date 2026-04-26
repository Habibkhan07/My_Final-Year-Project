import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'location_search_state.dart';
import 'dependency_injection.dart';
import '../../domain/failures/address_failure.dart';
import '../../domain/entities/place_search_entity.dart';
import 'map_picker_notifier.dart';

part 'location_search_notifier.g.dart';

@riverpod
class LocationSearchNotifier extends _$LocationSearchNotifier {
  Timer? _debounce;
  final _uuid = const Uuid();

  @override
  LocationSearchState build() {
    return LocationSearchState(
      sessionToken: _uuid.v4(),
    );
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      state = state.copyWith(results: [], isLoading: false, errorMessage: null);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    try {
      final searchPlaces = ref.read(searchPlacesUseCaseProvider);
      final results = await searchPlaces(query, state.sessionToken);
      
      // Ensure the query hasn't changed while we were fetching
      if (state.query == query) {
        state = state.copyWith(
          results: results,
          isLoading: false,
        );
      }
    } on AddressFailure catch (e) {
      if (state.query == query) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.message,
          results: [],
        );
      }
    } catch (e) {
      if (state.query == query) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'An unexpected error occurred.',
          results: [],
        );
      }
    }
  }

  Future<void> selectPlace(PlaceSearchEntity place) async {
    // We immediately clear the search state so the UI dismisses the dropdown
    state = state.copyWith(
      query: place.mainText,
      results: [],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final getDetails = ref.read(getPlaceDetailsUseCaseProvider);
      final details = await getDetails(place.placeId, state.sessionToken);
      
      // Tell MapPicker to move to this location
      ref.read(mapPickerProvider.notifier).updateLocation(
        details.latitude,
        details.longitude,
        details.streetAddress,
      );

      // Reset the session token for the next full search session
      state = state.copyWith(
        isLoading: false,
        sessionToken: _uuid.v4(),
      );
    } on AddressFailure catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch place details.',
      );
    }
  }
}

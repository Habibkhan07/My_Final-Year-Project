import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/widgets/map/app_map_state_views.dart';
import '../../../../../core/widgets/map/location_picker.dart';
import '../../../../customer/addresses/domain/entities/place_search_entity.dart';
import '../../../../customer/addresses/presentation/providers/dependency_injection.dart'
    as customer_addresses_di;
import '../../../dashboard/presentation/notifiers/technician_dashboard_notifier.dart';
import '../../domain/entities/work_location_entity.dart';
import '../notifiers/work_location_picker_notifier.dart';
import '../state/work_location_picker_state.dart';

/// Technician work-location picker.
///
/// One screen, one record. Visual language mirrors the customer addresses
/// `MapPickerScreen` (#0051AE brand blue, rounded card, search overlay) so the
/// tech-onboarded feel matches what the user already sees as a customer.
///
/// The only product difference from the customer picker: a "travel radius"
/// slider in the bottom card instead of label chips. The matchmaker reads
/// this directly (`TechnicianProfile.max_travel_radius_km`), so it has to be
/// captured here, not at booking time.
class WorkLocationPickerScreen extends ConsumerWidget {
  const WorkLocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifierAsync = ref.watch(workLocationPickerProvider);

    // Pop on successful save so the dashboard's banner disappears on return.
    //
    // ``technicianDashboardProvider`` is ``keepAlive: true``, so its cached
    // ``has_work_location`` / ``work_address_label`` would remain stale after
    // the PATCH without an explicit refresh. Calling ``refresh()`` (instead of
    // ``invalidate``) preserves the cached value while the round-trip happens
    // — no banner flicker, no AsyncLoading skeleton — matching the customer
    // addresses picker's invalidate-on-save pattern adapted for a notifier
    // that exposes a refresh method.
    ref.listen<AsyncValue<WorkLocationPickerState>>(
      workLocationPickerProvider,
      (_, next) {
        final s = next.value;
        if (s == null) return;
        final saved = s.saveState;
        if (saved is AsyncData<WorkLocationEntity?> && saved.value != null) {
          ref.read(technicianDashboardProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Work location saved.'),
              backgroundColor: Color(0xFF0051AE),
            ),
          );
          context.pop();
        }
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: notifierAsync.when(
        loading: () => const AppMapSkeleton(),
        error: (error, _) => AppMapErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(workLocationPickerProvider),
        ),
        data: (state) => LocationPicker(
          initialCenter: LatLng(state.latitude, state.longitude),
          onLocationChanged: (newCenter) {
            ref
                .read(workLocationPickerProvider.notifier)
                .onMapPanEnd(newCenter.latitude, newCenter.longitude);
          },
          overlay: const _SearchOverlay(),
          bottomCard: _BottomCard(state: state),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search overlay — back button + autocomplete.
//
// Owns its own debounce + place-details resolution rather than reusing the
// customer ``LocationSearchNotifier`` because that notifier hardcodes a
// push into the customer-side ``mapPickerProvider``. Reaching across feature
// boundaries to mutate a sibling feature's notifier is the kind of coupling
// the per-event-feature-wiring section of CLAUDE.md exists to prevent — so
// this overlay calls the geocoding use cases directly and updates this
// feature's notifier.
// ---------------------------------------------------------------------------

class _SearchOverlay extends ConsumerStatefulWidget {
  const _SearchOverlay();

  @override
  ConsumerState<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<_SearchOverlay> {
  final _focus = FocusNode();
  final _controller = TextEditingController();
  Timer? _debounce;
  String _sessionToken = const Uuid().v4();
  List<PlaceSearchEntity> _results = const [];
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() {
      _isLoading = query.isNotEmpty;
      if (query.isEmpty) _results = const [];
    });
    _debounce?.cancel();
    if (query.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await ref
            .read(customer_addresses_di.searchPlacesUseCaseProvider)
            .call(query, _sessionToken);
        if (!mounted) return;
        setState(() {
          _results = results;
          _isLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = const [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _onSelectPlace(PlaceSearchEntity place) async {
    _focus.unfocus();
    setState(() {
      _controller.text = place.mainText;
      _results = const [];
      _isLoading = true;
    });
    try {
      final details = await ref
          .read(customer_addresses_di.getPlaceDetailsUseCaseProvider)
          .call(place.placeId, _sessionToken);
      if (!mounted) return;
      ref
          .read(workLocationPickerProvider.notifier)
          .updateLocation(details);
      setState(() {
        _isLoading = false;
        _sessionToken = const Uuid().v4();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: _onQueryChanged,
                        decoration: InputDecoration(
                          hintText: 'Search your work area...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF0051AE),
                          ),
                          suffixIcon: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0051AE),
                                    ),
                                  ),
                                )
                              : _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _controller.clear();
                                        _onQueryChanged('');
                                      },
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_results.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.shade100,
                        indent: 52,
                      ),
                      itemBuilder: (context, index) {
                        final place = _results[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF0051AE),
                          ),
                          title: Text(
                            place.mainText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            place.secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _onSelectPlace(place),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 18, color: const Color(0xFF151C24)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom card: selected-location summary + travel-radius slider + Confirm.
// ---------------------------------------------------------------------------

class _BottomCard extends ConsumerWidget {
  final WorkLocationPickerState state;
  const _BottomCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(workLocationPickerProvider.notifier);
    final isSaving = state.saveState is AsyncLoading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            color: Colors.black12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFC2C6D6).withOpacity(0.4),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected location card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0051AE).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: Color(0xFF0051AE),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOUR WORK AREA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Color(0xFF424753),
                              ),
                            ),
                            const SizedBox(height: 4),
                            state.isGeocoding
                                ? const _GeocodingSkeleton()
                                : Text(
                                    state.streetAddress,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF151C24),
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Travel radius slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TRAVEL RADIUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Color(0xFF424753),
                      ),
                    ),
                    Text(
                      '${state.maxTravelRadiusKm} km',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0051AE),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF0051AE),
                    thumbColor: const Color(0xFF0051AE),
                    overlayColor: const Color(0xFF0051AE).withOpacity(0.15),
                  ),
                  child: Slider(
                    value: state.maxTravelRadiusKm
                        .clamp(1, 100)
                        .toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      notifier.setRadius(v.round());
                    },
                  ),
                ),
                if (state.saveState is AsyncError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Text(
                        (state.saveState as AsyncError).error.toString(),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: const BoxDecoration(color: Colors.white),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isSaving || state.isGeocoding)
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(workLocationPickerProvider.notifier)
                            .save();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0051AE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF0051AE).withOpacity(0.4),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Save Work Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeocodingSkeleton extends StatelessWidget {
  const _GeocodingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF151C24).withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 120,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF151C24).withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

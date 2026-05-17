import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/widgets/map/location_picker.dart';
import '../../../../customer/addresses/data/models/place_details.dart';
import '../../../../customer/addresses/domain/entities/place_search_entity.dart';
import '../../../../customer/addresses/presentation/providers/dependency_injection.dart'
    as customer_addresses_di;

/// Fullscreen map picker used by the onboarding wizard's Work Location
/// step. Identical visual language to the dashboard's
/// ``WorkLocationPickerScreen`` (#0051AE brand, search overlay, radius
/// slider, bottom card) but the Confirm action **pops with the chosen
/// result** instead of dispatching a PATCH — the wizard's finalize call
/// is the only network write.
///
/// Returns ``OnboardingWorkLocationResult?`` via `Navigator.pop`.
class OnboardingWorkLocationPickerScreen extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddressLabel;
  final int initialRadiusKm;

  const OnboardingWorkLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddressLabel,
    this.initialRadiusKm = 10,
  });

  @override
  ConsumerState<OnboardingWorkLocationPickerScreen> createState() =>
      _OnboardingWorkLocationPickerScreenState();
}

class _OnboardingWorkLocationPickerScreenState
    extends ConsumerState<OnboardingWorkLocationPickerScreen> {
  static const _brand = Color(0xFF0051AE);
  // Lahore fallback — matches the dashboard picker's anchor.
  static const _fallbackLat = 31.5204;
  static const _fallbackLng = 74.3587;

  late double _lat;
  late double _lng;
  late String _label;
  late int _radiusKm;
  bool _isGeocoding = false;
  bool _bootstrapping = true;
  // True once the user has actively confirmed a location (panned the
  // map, searched, or accepted the bootstrapped current-location).
  // Drives the Confirm button's enabled state so the user can't
  // accidentally confirm the Lahore fallback without realising.
  bool _userPicked = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLatitude ?? _fallbackLat;
    _lng = widget.initialLongitude ?? _fallbackLng;
    _label = widget.initialAddressLabel ?? _coordsLabel(_lat, _lng);
    _radiusKm = widget.initialRadiusKm;
    // If the screen was entered with a saved location (re-entering the
    // step), treat the existing pick as confirmed.
    _userPicked =
        widget.initialLatitude != null && widget.initialLongitude != null;
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() => _bootstrapping = false);
      return;
    }
    try {
      final details = await ref
          .read(customer_addresses_di.getCurrentLocationUseCaseProvider)
          .call();
      if (!mounted) return;
      setState(() {
        _lat = details.latitude;
        _lng = details.longitude;
        _label = details.formattedAddress;
        _bootstrapping = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bootstrapping = false);
    }
  }

  void _onMapPanEnd(LatLng newCenter) {
    setState(() {
      _lat = newCenter.latitude;
      _lng = newCenter.longitude;
      _isGeocoding = true;
      _userPicked = true;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final details = await ref
            .read(customer_addresses_di.reverseGeocodeUseCaseProvider)
            .call(newCenter.latitude, newCenter.longitude);
        if (!mounted) return;
        setState(() {
          _label = details.formattedAddress;
          _isGeocoding = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _label = _coordsLabel(newCenter.latitude, newCenter.longitude);
          _isGeocoding = false;
        });
      }
    });
  }

  void _onSelectPlace(PlaceDetails details) {
    setState(() {
      _lat = details.latitude;
      _lng = details.longitude;
      _label = details.formattedAddress;
      _isGeocoding = false;
      _userPicked = true;
    });
  }

  String _coordsLabel(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  void _confirm() {
    HapticFeedback.mediumImpact();
    // Truncate the label to the backend column limit (CharField(200)).
    // Reverse-geocoded labels from Nominatim regularly exceed 200 chars.
    final trimmed = _label.length > 200 ? _label.substring(0, 200) : _label;
    Navigator.of(context).pop(
      OnboardingWorkLocationResult(
        latitude: _lat,
        longitude: _lng,
        addressLabel: trimmed,
        radiusKm: _radiusKm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Bootstrap state needs its own AppBar so the user can cancel out
      // if GPS permission prompts hang. The main picker draws its own
      // back affordance inside the search overlay.
      appBar: _bootstrapping
          ? AppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF151C24),
              elevation: 0,
              title: const Text(
                'Finding your location…',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: _bootstrapping
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : LocationPicker(
              initialCenter: LatLng(_lat, _lng),
              onLocationChanged: _onMapPanEnd,
              overlay: _SearchOverlay(onSelectPlace: _onSelectPlace),
              bottomCard: _BottomCard(
                addressLabel: _label,
                isGeocoding: _isGeocoding,
                radiusKm: _radiusKm,
                canConfirm: _userPicked,
                onRadiusChanged: (km) => setState(() => _radiusKm = km),
                onConfirm: _confirm,
              ),
            ),
    );
  }
}

/// Wire payload returned to the onboarding wizard from the picker.
class OnboardingWorkLocationResult {
  final double latitude;
  final double longitude;
  final String addressLabel;
  final int radiusKm;

  const OnboardingWorkLocationResult({
    required this.latitude,
    required this.longitude,
    required this.addressLabel,
    required this.radiusKm,
  });
}

class _SearchOverlay extends ConsumerStatefulWidget {
  final void Function(PlaceDetails) onSelectPlace;
  const _SearchOverlay({required this.onSelectPlace});

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

  Future<void> _select(PlaceSearchEntity place) async {
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
      widget.onSelectPlace(details);
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
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: _onQueryChanged,
                        decoration: InputDecoration(
                          hintText: 'Search your work area…',
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
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
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
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => Divider(
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
                          onTap: () => _select(place),
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
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.arrow_back_ios_new,
              size: 18, color: Color(0xFF151C24)),
        ),
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  final String addressLabel;
  final bool isGeocoding;
  final int radiusKm;
  final bool canConfirm;
  final ValueChanged<int> onRadiusChanged;
  final VoidCallback onConfirm;

  const _BottomCard({
    required this.addressLabel,
    required this.isGeocoding,
    required this.radiusKm,
    required this.canConfirm,
    required this.onRadiusChanged,
    required this.onConfirm,
  });

  static const _brand = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0x66C2C6D6),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FB),
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
                          color: _brand,
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
                            isGeocoding
                                ? const _GeocodingSkeleton()
                                : Text(
                                    addressLabel,
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
                      '$radiusKm km',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _brand,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _brand,
                    thumbColor: _brand,
                    overlayColor: const Color(0x260051AE),
                  ),
                  child: Slider(
                    value: radiusKm.clamp(1, 100).toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      onRadiusChanged(v.round());
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isGeocoding || !canConfirm) ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFC2C6D6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: canConfirm && !isGeocoding ? 8 : 0,
                  shadowColor: const Color(0x660051AE),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      canConfirm
                          ? 'Use this location'
                          : 'Tap the map or search to pick',
                      style: const TextStyle(
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
            color: const Color(0x0D151C24),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 120,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0x0D151C24),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

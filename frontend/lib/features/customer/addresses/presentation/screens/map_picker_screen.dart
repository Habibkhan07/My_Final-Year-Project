import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/address_entity.dart';
import '../providers/dependency_injection.dart';
import '../providers/map_picker_notifier.dart';
import '../providers/map_picker_state.dart';

/// Uber-style draggable map picker.
///
/// Visual contract:
///   loading  → grey skeleton (GPS fetch in progress)
///   error    → centred error card + retry
///   data     → full-screen map + fixed centre pin + bottom confirmation card
///
/// The map pans freely; the pin is fixed at the absolute screen centre via
/// [Align]. [MapEventMoveEnd] triggers debounced reverse geocoding.
/// On successful save the screen pops; the caller is responsible for
/// invalidating [addressesProvider] if a refresh is needed.
class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifierAsync = ref.watch(mapPickerProvider);

    // Navigate away as soon as save completes successfully.
    ref.listen<AsyncValue<MapPickerState>>(
      mapPickerProvider,
      (_, next) {
        final mapState = next.value;
        if (mapState == null) return;
        final saved = mapState.saveState;
        if (saved is AsyncData<CustomerAddressEntity?> && saved.value != null) {
          ref.invalidate(addressesProvider);
          context.pop();
        }
      },
    );

    return Scaffold(
      body: notifierAsync.when(
        loading: () => const _MapSkeleton(),
        error: (error, _) => _ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(mapPickerProvider),
        ),
        data: (state) => _MapBody(
          state: state,
          mapController: _mapController,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map body — shown when GPS has resolved
// ---------------------------------------------------------------------------

class _MapBody extends ConsumerWidget {
  final MapPickerState state;
  final MapController mapController;

  const _MapBody({required this.state, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mapPickerProvider.notifier);

    return Stack(
      children: [
        // 1. Full-screen map
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(state.latitude, state.longitude),
            initialZoom: 15.5,
            onMapEvent: (event) {
              if (event is MapEventMoveEnd) {
                final center = mapController.camera.center;
                notifier.onMapPanEnd(center.latitude, center.longitude);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fyp.frontend',
            ),
          ],
        ),

        // 2. Fixed centre pin — Align keeps it stationary while map pans
        const Align(
          alignment: Alignment.center,
          child: Padding(
            // Offset upward by half the icon height so the tip sits at centre
            padding: EdgeInsets.only(bottom: 48),
            child: Icon(
              Icons.location_pin,
              size: 48,
              color: Color(0xFF0051AE),
            ),
          ),
        ),

        // 3. Back button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 4. Bottom confirmation card
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomCard(state: state),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom card — address display, label chips, confirm button
// ---------------------------------------------------------------------------

class _BottomCard extends ConsumerWidget {
  final MapPickerState state;

  const _BottomCard({required this.state});

  static const _labels = ['Home', 'Office', 'Other'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mapPickerProvider.notifier);
    final isSaving = state.saveState is AsyncLoading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black26)],
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Address display
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: state.isGeocoding
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0051AE),
                        ),
                      )
                    : Text(
                        state.streetAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF151C24),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Label chips
          Text(
            'Save as',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _labels.map((label) {
              final isSelected = label == state.selectedLabel;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => notifier.setLabel(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0051AE)
                          : const Color(0xFFF0F3F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF727785),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Error message from save failure
          if (state.saveState is AsyncError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                (state.saveState as AsyncError).error.toString(),
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () => ref
                      .read(mapPickerProvider.notifier)
                      .save(isDefault: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0051AE),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF0051AE).withAlpha(128),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton — shown while GPS is fetching
// ---------------------------------------------------------------------------

class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFE8EAF0)),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 240,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE3EF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                    height: 16,
                    width: 200,
                    color: const Color(0xFFF0F3F9)),
                const SizedBox(height: 12),
                Container(
                    height: 16,
                    width: 140,
                    color: const Color(0xFFF0F3F9)),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error card
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey.shade800, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0051AE),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/widgets/map/app_map_state_views.dart';
import '../../../../../core/widgets/map/location_picker.dart';
import '../../domain/entities/address_entity.dart';
import '../providers/dependency_injection.dart';
import '../providers/map_picker_notifier.dart';
import '../providers/map_picker_state.dart';
import '../providers/location_search_notifier.dart';

class MapPickerScreen extends ConsumerWidget {
  const MapPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifierAsync = ref.watch(mapPickerProvider);

    // Navigate away as soon as save completes successfully.
    ref.listen<AsyncValue<MapPickerState>>(mapPickerProvider, (_, next) {
      final mapState = next.value;
      if (mapState == null) return;
      final saved = mapState.saveState;
      if (saved is AsyncData<CustomerAddressEntity?> && saved.value != null) {
        ref.invalidate(addressesProvider);
        context.pop();
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: notifierAsync.when(
        loading: () => const AppMapSkeleton(),
        error: (error, _) => AppMapErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(mapPickerProvider),
        ),
        data: (state) => LocationPicker(
          initialCenter: LatLng(state.latitude, state.longitude),
          onLocationChanged: (newCenter) {
            ref
                .read(mapPickerProvider.notifier)
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
// Top Overlay — back button, search bar, and autocomplete results
// ---------------------------------------------------------------------------

class _SearchOverlay extends ConsumerStatefulWidget {
  const _SearchOverlay();

  @override
  ConsumerState<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<_SearchOverlay> {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(locationSearchProvider);
    final notifier = ref.read(locationSearchProvider.notifier);

    // If query is empty from state (e.g., after selecting a place), clear text
    if (searchState.query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

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
                        focusNode: _focusNode,
                        onChanged: notifier.onQueryChanged,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF151C24),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search location...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF0051AE),
                          ),
                          suffixIcon: searchState.isLoading
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
                                    notifier.onQueryChanged('');
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
              if (searchState.errorMessage != null)
                _ErrorBubble(message: searchState.errorMessage!),
              if (searchState.results.isNotEmpty)
                _SearchResultsList(
                  results: searchState.results,
                  onSelect: (place) {
                    _focusNode.unfocus();
                    notifier.selectPlace(place);
                  },
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

class _ErrorBubble extends StatelessWidget {
  final String message;
  const _ErrorBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final List<dynamic> results;
  final void Function(dynamic) onSelect;

  const _SearchResultsList({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 300),
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
          itemCount: results.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade100, indent: 52),
          itemBuilder: (context, index) {
            final place = results[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0051AE).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF0051AE),
                  size: 20,
                ),
              ),
              title: Text(
                place.mainText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF151C24),
                ),
              ),
              subtitle: Text(
                place.secondaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              onTap: () => onSelect(place),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom card — address display, label chips, confirm button
// ---------------------------------------------------------------------------

class _BottomCard extends ConsumerWidget {
  final MapPickerState state;

  const _BottomCard({required this.state});

  static const _labels = [
    ('Home', Icons.home_rounded),
    ('Office', Icons.work_rounded),
    ('Other', Icons.location_on_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mapPickerProvider.notifier);
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
          // Drag handle
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
                // Address summary tile (matching booking summary style)
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
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
                              'SELECTED LOCATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Color(0xFF424753),
                              ),
                            ),
                            const SizedBox(height: 4),
                            state.isGeocoding
                                ? _GeocodingSkeleton()
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

                // Label chips
                const Text(
                  'SAVE AS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Color(0xFF424753),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _labels.map((item) {
                    final label = item.$1;
                    final icon = item.$2;
                    final isSelected = label == state.selectedLabel;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setLabel(label);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0051AE)
                                : const Color(0xFF0051AE).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0051AE)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0051AE),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF151C24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Error message from save failure
                if (state.saveState is AsyncError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ErrorBubble(
                      message: (state.saveState as AsyncError).error.toString(),
                    ),
                  ),
              ],
            ),
          ),

          // Footer (Matching booking footer style)
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFC2C6D6).withOpacity(0.15),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isSaving || state.isGeocoding)
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(mapPickerProvider.notifier)
                            .save(isDefault: false);
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
                            'Confirm Location',
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

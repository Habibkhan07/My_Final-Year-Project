import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_position_provider.g.dart';

/// Lightweight cached geolocator one-shot for the dashboard's "X km away"
/// subtext.
///
/// Why a custom provider instead of reusing the addresses feature's
/// `LocationDataSource`:
///   - That data source throws on permission denial — appropriate for the
///     address picker (a hard failure: the user can't pick an address without
///     location). Here, denial is soft: the dashboard still works, the km
///     subtext just hides.
///   - We only need the lat/lng. No reverse-geocoding, no street string.
///
/// Cache window is 5 minutes. The dashboard rebuilds infrequently and the
/// technician hasn't moved meaningfully in 5 minutes for "X km away" purposes.
/// `invalidate` lets a future "refresh" gesture force a fresh fix.
@Riverpod(keepAlive: true)
class CurrentPosition extends _$CurrentPosition {
  static const _cacheTtl = Duration(minutes: 5);
  Position? _cached;
  DateTime? _cachedAt;

  @override
  Future<Position?> build() => _read();

  Future<Position?> _read() async {
    final now = DateTime.now();
    if (_cached != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheTtl) {
      return _cached;
    }

    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _cached = position;
      _cachedAt = now;
      return position;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Force-refresh on next read. Used by pull-to-refresh.
  void invalidateCache() {
    _cached = null;
    _cachedAt = null;
    ref.invalidateSelf();
  }
}

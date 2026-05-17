import 'package:flutter/foundation.dart';

/// Booking orchestrator (session 4): which map vendor renders the
/// `LiveTrackingMap`. Selected once at app boot via `--dart-define=
/// MAP_PROVIDER=osm|google` and consumed by the adapter factories
/// (`mapProviderTypeProvider` in `core/widgets/map/map_provider.dart`).
/// Per memory `project_maps_strategy`: default `osm` until a Google
/// Maps API key is provisioned. Runtime flipping is intentionally NOT
/// supported — would require widget-tree rebuild on every screen.
enum MapProviderType { osm, google }

class AppConstants {
  // Build-time injection via ``--dart-define=BASE_URL=...``. The default is
  // the Django dev server on the laptop loopback — fine for ``flutter run``
  // on the local web shell or an emulator that's mapped the laptop's port.
  // On-device builds MUST override (LAN IP for dev, https tunnel / staging
  // endpoint for viva + release). The release-mode guard
  // ``assertReleaseSafeNetworking`` below refuses to start with cleartext.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  // WebSocket origin — mirrors [baseUrl]'s host. Has no `/api` prefix because
  // Django Channels mounts its routes at the project root (e.g. `/ws/events/`).
  // Override at build time with ``--dart-define=BASE_WS_URL=wss://...``.
  static const String baseWsUrl = String.fromEnvironment(
    'BASE_WS_URL',
    defaultValue: 'ws://127.0.0.1:8000',
  );

  // ─── Map provider (session 4) ──────────────────────────────────────────
  //
  // Read once at boot via --dart-define. Anything other than the literal
  // string "google" falls back to OSM — the dev default that requires no
  // API key. The fallback is deliberately permissive (any typo / missing
  // value lands on OSM, never on a broken Google build).
  static const String _mapProviderRaw = String.fromEnvironment(
    'MAP_PROVIDER',
    defaultValue: 'osm',
  );

  static MapProviderType get mapProvider => switch (_mapProviderRaw) {
    'google' => MapProviderType.google,
    _ => MapProviderType.osm,
  };

  /// API key for Google Maps + Google Directions. Empty when running on the
  /// OSM provider (the default), or when the Google build forgot to pass
  /// the key. The map widget logs a clear warning at first build time if
  /// `mapProvider == google` but this is empty — see flag #16 for the
  /// silent-fallback footgun and the planned production-mode assertion.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Customer-side support phone for the live-tracking call FAB
  /// (audit H11 / W-8). The booking detail wire contract does not
  /// surface `technician.phoneNo` to customers, so the customer can't
  /// dial the assigned tech directly. Until the API exposes it,
  /// the customer's call FAB dials this support number — non-zero is
  /// strictly better than the previous behaviour (customer sees no
  /// FAB at all and has no path to reach anyone if something goes
  /// wrong on their side of the booking).
  ///
  /// Empty by default in dev; production builds pass
  /// `--dart-define=SUPPORT_PHONE_NUMBER=+92...`. When empty the
  /// customer-side FAB stays hidden (same UX as before, but failure
  /// mode is now "intentionally unconfigured" rather than "silently
  /// dropped because backend doesn't surface tech phone").
  static const String supportPhoneNumber = String.fromEnvironment(
    'SUPPORT_PHONE_NUMBER',
    defaultValue: '',
  );

  /// Audit S-8 (Batch D): boot-time guardrail against shipping a release
  /// build that points at `http://`. Our `baseUrl` + `baseWsUrl` are
  /// hardcoded to `http://127.0.0.1:8000/api` for dev (the Django dev
  /// server does not serve TLS); a release build that forgot to swap
  /// these to `https://` / `wss://` would transmit auth tokens, JWT
  /// header, and tech-location frames in plaintext.
  ///
  /// Throws [StateError] in release mode if either URL is cleartext.
  /// In debug / profile mode this is a no-op (cleartext is the
  /// normal dev workflow).
  ///
  /// Call this from `main()` before runApp. Tests call it via the same
  /// boot path, so this also doubles as a unit-test invariant.
  static void assertReleaseSafeNetworking() {
    if (!kReleaseMode) return;
    if (!baseUrl.startsWith('https://')) {
      throw StateError(
        'Release build attempted to start with cleartext baseUrl '
        '"$baseUrl". Set --dart-define=BASE_URL=https://... at build '
        'time. Audit S-8: cleartext shipped to production would leak '
        'auth tokens + tech-location GPS frames to any on-path '
        'observer.',
      );
    }
    if (!baseWsUrl.startsWith('wss://')) {
      throw StateError(
        'Release build attempted to start with cleartext baseWsUrl '
        '"$baseWsUrl". Set --dart-define=BASE_WS_URL=wss://... at '
        'build time. Audit S-8.',
      );
    }
  }
}

// Tech-side banner that surfaces a non-`running` `BroadcastState` so the
// technician sees clearly when their location is NOT being shared with
// the customer.
//
// Audit C6 (S-5): without this banner, the controller can transition to
// `permissionDenied` / `notificationPermissionDenied` / `error` and emit
// no UI signal at all — the tech keeps driving thinking the customer
// can see them, while the customer's map sits frozen on "tech offline".
//
// Audit C2 (F-1): for the two permission-denied variants, the banner is
// the deep-link entry point to the OS Settings page. On Android 11+
// `ACCESS_BACKGROUND_LOCATION` cannot be granted via the runtime dialog
// at all — Settings is the only path. The banner exposes an "Open
// settings" affordance via `onOpenSettings`.
//
// UX (illiterate-first per CLAUDE.md memory):
//   • Big icon, large readable line of plain copy. No jargon.
//   • Colour communicates severity at a glance:
//       - red — hard block (no permission to share location at all).
//       - amber — soft block (notification missing means OS will kill
//         the service; tracking will fail soon even if not yet failed).
//       - orange — generic error (tracking failed for another reason).
//   • Render-only for non-blocking states (`idle` / `running`):
//     `SizedBox.shrink()` keeps the layout pristine.
//   • Permission-denied variants get a tap target ("Open settings");
//     plain `error` does not (settings won't help with a generic init
//     failure).

import 'package:flutter/material.dart';

import '../../domain/entities/broadcast_state.dart';

class BroadcastStateBanner extends StatelessWidget {
  const BroadcastStateBanner({
    super.key,
    required this.state,
    this.onOpenSettings,
  });

  final BroadcastState state;

  /// Invoked when the tech taps a permission-denied banner's "Open
  /// settings" CTA. Wired by the orchestrator screen to
  /// `ForegroundLocationServiceController.openSystemSettings()`.
  ///
  /// Null disables the CTA — the banner still renders the message but
  /// without the tap affordance. Useful for tests + the `error` state.
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(state);
    if (spec == null) return const SizedBox.shrink();

    final showCta = spec.isPermissionDenied && onOpenSettings != null;

    // Audit W-38 (Batch G): liveRegion so TalkBack announces the
    // banner appearance immediately. The tech needs to know the
    // moment broadcasting fails — silent appearance defeats the
    // C6 visibility purpose for screen-reader users.
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: spec.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: spec.foreground.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(spec.icon, size: 24, color: spec.foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                spec.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: spec.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showCta) ...[
              const SizedBox(width: 8),
              // BANNER-1b (Batch I): bumped from `Size(0, 36)` to
              // `Size(0, 48)` and dropped `MaterialTapTargetSize
              // .shrinkWrap`. 36 dp tall is below Material / Android
              // accessibility's 48 dp tap-target minimum — for a
              // fix-permission CTA on the tracking-failed path
              // (high-stress UX) this is exactly the wrong place to
              // economise on tap area.
              TextButton(
                onPressed: onOpenSettings,
                style: TextButton.styleFrom(
                  foregroundColor: spec.foreground,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  'Open settings',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static _BannerSpec? _specFor(BroadcastState state) {
    switch (state) {
      case BroadcastState.idle:
      case BroadcastState.running:
        return null;
      case BroadcastState.permissionDenied:
        return const _BannerSpec(
          icon: Icons.location_off,
          message: 'Location is off — customer cannot see you.',
          background: Color(0xFFFFEBEE), // red 50
          foreground: Color(0xFFC62828), // red 800
          isPermissionDenied: true,
        );
      case BroadcastState.notificationPermissionDenied:
        return const _BannerSpec(
          icon: Icons.notifications_off,
          message: 'Allow notifications so tracking can stay on.',
          background: Color(0xFFFFF8E1), // amber 50
          foreground: Color(0xFFB07000), // amber 900-ish, AA on amber 50
          isPermissionDenied: true,
        );
      case BroadcastState.error:
        return const _BannerSpec(
          icon: Icons.signal_wifi_statusbar_connected_no_internet_4,
          message: 'Tracking unavailable. Try reopening this booking.',
          background: Color(0xFFFFF3E0), // orange 50
          foreground: Color(0xFFE65100), // orange 900
          isPermissionDenied: false,
        );
      case BroadcastState.unsupportedPlatform:
        return const _BannerSpec(
          icon: Icons.devices_other,
          message:
              'GPS tracking only runs on the Android app. In dev: use '
              "dev_panel option [4] to simulate the tech's location.",
          background: Color(0xFFE3F2FD), // blue 50 — informational
          foreground: Color(0xFF0D47A1), // blue 900
          isPermissionDenied: false,
        );
    }
  }
}

class _BannerSpec {
  const _BannerSpec({
    required this.icon,
    required this.message,
    required this.background,
    required this.foreground,
    required this.isPermissionDenied,
  });
  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;

  /// True when tapping "Open settings" can plausibly fix the state.
  /// `error` is generic and settings won't necessarily help.
  final bool isPermissionDenied;
}

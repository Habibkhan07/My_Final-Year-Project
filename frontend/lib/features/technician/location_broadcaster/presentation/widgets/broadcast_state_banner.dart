// Tech-side banner that surfaces a non-`running` `BroadcastState` so the
// technician sees clearly when their location is NOT being shared with
// the customer.
//
// Audit C6 (S-5): without this banner, the controller can transition to
// `permissionDenied` / `notificationPermissionDenied` / `error` and emit
// no UI signal at all — the tech keeps driving thinking the customer
// can see them, while the customer's map sits frozen on "tech offline".
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
//
// The banner is intentionally informational this session — the
// "Open settings" action lands with C2 (background-location flow).

import 'package:flutter/material.dart';

import '../../domain/entities/broadcast_state.dart';

class BroadcastStateBanner extends StatelessWidget {
  const BroadcastStateBanner({super.key, required this.state});

  final BroadcastState state;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(state);
    if (spec == null) return const SizedBox.shrink();

    return Container(
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
        ],
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
        );
      case BroadcastState.notificationPermissionDenied:
        return const _BannerSpec(
          icon: Icons.notifications_off,
          message: 'Allow notifications so tracking can stay on.',
          background: Color(0xFFFFF8E1), // amber 50
          foreground: Color(0xFFB07000), // amber 900-ish, AA on amber 50
        );
      case BroadcastState.error:
        return const _BannerSpec(
          icon: Icons.signal_wifi_statusbar_connected_no_internet_4,
          message: 'Tracking unavailable. Try reopening this booking.',
          background: Color(0xFFFFF3E0), // orange 50
          foreground: Color(0xFFE65100), // orange 900
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
  });
  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;
}

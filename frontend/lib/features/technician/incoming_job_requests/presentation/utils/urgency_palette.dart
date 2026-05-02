// Single source of truth for the urgency-color encoding shared across the
// incoming-job UI. After the pivot to a serialized one-offer model with a
// swipe-to-accept draining track, the only consumer is the swipe widget's
// fill (and an optional pulse on near-expiry). The bands themselves stay
// the same — green / amber / red as a fraction of the original SLA window —
// because they're still the right visual encoding for "how much runway does
// this offer have left."
//
// Bands are computed as a fraction of the original SLA window (`slaWindow`),
// not absolute seconds. With the new 5-minute floor on `slaWindow` (server
// contract — see flag.md), the same thresholds give the technician roughly
// 2.5min of green, 1.5min of amber, and the final ~1min in red.

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Above this fraction of the SLA window remaining, the offer reads "calm" and
/// the band is green. 0.5 = at least half the window left.
const double urgencyGreenAbove = 0.5;

/// Above this fraction (and ≤ green threshold) the offer reads "warning" and
/// the band is amber. 0.2 = at least 20% of the window left.
const double urgencyAmberAbove = 0.2;

/// Full-saturation amber used for the warning band. Defined here (not in
/// AppColors) because it's a UI-state color, not a brand color — the rest of
/// the app should not pick this up incidentally.
const Color amberAccent = Color(0xFFD97706);

/// Returns the full-saturation accent color for the supplied remaining/window
/// pair. Drives the swipe track's fill and any near-expiry pulse decoration.
///
/// Defensive: a non-positive [slaWindow] (which should never happen on the
/// wire — backend enforces a 5-minute floor) returns red so the band stays
/// visually loud rather than silently degrading to green when the math is
/// broken.
Color urgencyAccent(Duration remaining, Duration slaWindow) {
  final fraction = _fraction(remaining, slaWindow);
  if (fraction > urgencyGreenAbove) return AppColors.secondary;
  if (fraction >= urgencyAmberAbove) return amberAccent;
  return AppColors.error;
}

/// True when the offer is in the red band — the caller may use this to drive
/// a pulse animation. Centralized so "is this urgent enough to pulse?" never
/// drifts from the color decision.
bool urgencyIsRed(Duration remaining, Duration slaWindow) {
  return _fraction(remaining, slaWindow) < urgencyAmberAbove;
}

double _fraction(Duration remaining, Duration slaWindow) {
  final span = slaWindow.inMilliseconds;
  if (span <= 0) return 0.0;
  if (remaining.isNegative) return 0.0;
  final f = remaining.inMilliseconds / span;
  return f.clamp(0.0, 1.0);
}

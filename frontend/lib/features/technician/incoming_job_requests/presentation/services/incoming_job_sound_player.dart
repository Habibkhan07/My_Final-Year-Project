// Audio cue for new-offer-arrival, played by `IncomingJobSheetHost` as part
// of the head-change vanish-reappear ceremony. Wrapped in an interface so
// the implementation can be swapped without touching the host:
//
//   * Today's `SystemSoundIncomingJobSoundPlayer` delegates to Flutter's
//     built-in `SystemSound.play(SystemSoundType.alert)`. No dependency,
//     no asset, respects device silent / vibrate mode automatically. The
//     trade-off is that the alert sound is the device's standard one —
//     not distinct from a regular system notification. Treated as a
//     deliberate placeholder; see `flag.md` #18 for the swap-path.
//
//   * A future `AssetIncomingJobSoundPlayer` will load a custom chime via
//     `audioplayers` (or similar). The host doesn't need to know — the
//     swap is one provider override in `dependency_injection.dart`.
import 'package:flutter/services.dart';

/// Plays a short audio cue at moments the technician must register
/// immediately. Today the only such moment is "new offer is the head" —
/// the listener fires `playNewOfferSound()` while the sheet is sliding in
/// during the vanish-reappear ceremony.
abstract class IncomingJobSoundPlayer {
  /// Plays the audio cue for a new offer surfacing as the head of the
  /// queue. Returning a Future allows asset-backed implementations to
  /// `await` decode + playback if they need to; the system-sound
  /// implementation completes synchronously.
  Future<void> playNewOfferSound();
}

/// Placeholder implementation: delegates to Flutter's built-in
/// `SystemSound.play(SystemSoundType.alert)`. Zero-cost (no dependency,
/// no asset bundling), but the audible output is the device's stock
/// alert tone — fine as a placeholder, not as the final UX.
class SystemSoundIncomingJobSoundPlayer implements IncomingJobSoundPlayer {
  const SystemSoundIncomingJobSoundPlayer();

  @override
  Future<void> playNewOfferSound() => SystemSound.play(SystemSoundType.alert);
}

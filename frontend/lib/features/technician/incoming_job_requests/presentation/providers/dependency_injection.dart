// DI surface for the incoming job requests feature.
//
// The queue notifier is exposed by codegen on its own; this file is for
// providers that don't need codegen — simple stateless service singletons.
//
// Future additions: when the accept/decline endpoint ships
// (`backend/bookings/api/BOOKINGS_API.md` §1.1), the repository and its
// remote/local data sources will be wired here.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/incoming_job_sound_player.dart';

/// Plays the audio cue for a new offer surfacing as the head of the queue.
/// Consumed by `IncomingJobSheetHost` during the vanish-reappear ceremony.
///
/// Today's binding is the placeholder `SystemSoundIncomingJobSoundPlayer`
/// which delegates to Flutter's built-in alert sound. To swap to a custom
/// chime: override this provider in the test/app setup with an
/// `AssetIncomingJobSoundPlayer` (or similar) that loads a bundled audio
/// asset via `audioplayers`. No host or widget changes required — the
/// swap is one override. See `flag.md` #18.
final incomingJobSoundPlayerProvider = Provider<IncomingJobSoundPlayer>(
  (ref) => const SystemSoundIncomingJobSoundPlayer(),
);

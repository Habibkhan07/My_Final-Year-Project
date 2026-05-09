// Trivial-but-load-bearing pin on the placeholder sound player. The host
// reads through `incomingJobSoundPlayerProvider` and calls
// `playNewOfferSound()` once per head-change ceremony; if the placeholder
// implementation ever stops conforming to the interface (or starts
// throwing), the host's ceremony silently fails. This test covers the
// contract those calls assume.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/services/incoming_job_sound_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemSoundIncomingJobSoundPlayer', () {
    test('implements IncomingJobSoundPlayer', () {
      expect(
        const SystemSoundIncomingJobSoundPlayer(),
        isA<IncomingJobSoundPlayer>(),
      );
    });

    test(
      'playNewOfferSound returns a Future that completes without throwing',
      () async {
        const player = SystemSoundIncomingJobSoundPlayer();
        // Under the test binding, the SystemSound platform channel is a
        // no-op — but it must still complete cleanly so the host's
        // `unawaited(...)` doesn't surface an uncaught error to the zone.
        await expectLater(player.playNewOfferSound(), completes);
      },
    );

    test(
      'playNewOfferSound dispatches the alert system sound (not click)',
      () async {
        // Listen on the platform channel SystemSound uses, so we can verify
        // the placeholder picks the right sound type. Click would be too
        // subtle for "new offer arrived"; alert is the deliberate choice.
        final calls = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'SystemSound.play') {
                calls.add(call.arguments as String);
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        const player = SystemSoundIncomingJobSoundPlayer();
        await player.playNewOfferSound();

        expect(calls, ['SystemSoundType.alert']);
      },
    );
  });
}

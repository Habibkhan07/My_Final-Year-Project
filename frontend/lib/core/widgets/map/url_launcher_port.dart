// IUrlLauncher port + production adapter.
//
// Introduced for audit H14: the phone-call FAB in `LiveTrackingMap`
// previously called the static `launchUrl` from `package:url_launcher`
// directly, which gave widget tests no way to drive the launched=false
// failure path (the platform plugin call hangs in the test isolate).
//
// The port keeps the surface narrow to what the call FAB needs — no
// `mode`, no `webOnlyWindowName` etc. If a future call site needs more
// surface (the technician dashboard's `up_next_job_card.dart` already
// uses `LaunchMode.externalApplication`), broaden here in lockstep with
// the adapter — do NOT introduce a parallel port.

import 'package:url_launcher/url_launcher.dart';

abstract class IUrlLauncher {
  /// Launches the given URI. Returns `true` if a handler accepted the
  /// intent (dialler opened, browser opened, …) and `false` otherwise.
  Future<bool> launch(Uri uri);
}

class UrlLauncherAdapter implements IUrlLauncher {
  const UrlLauncherAdapter();

  @override
  Future<bool> launch(Uri uri) => launchUrl(uri);
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../notifiers/ws_connection_notifier.dart';
import '../state/connection_state.dart';

part 'connection_status_provider.g.dart';

/// Read-only view of the WebSocket status, intended for UI widgets that
/// only care about the connection bar.
///
/// Why a separate provider: watching `systemEventNotifierProvider` rebuilds
/// on every incoming event (chat bursts, arrival alerts, etc.). Widgets that
/// only render an offline indicator should watch this provider so they only
/// rebuild when the connection state itself transitions — which is rare.
@riverpod
WsConnectionStatus connectionStatus(Ref ref) {
  return ref.watch(wsConnectionProvider);
}

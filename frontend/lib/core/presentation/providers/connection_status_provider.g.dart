// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-only view of the WebSocket status, intended for UI widgets that
/// only care about the connection bar.
///
/// Why a separate provider: watching `systemEventNotifierProvider` rebuilds
/// on every incoming event (chat bursts, arrival alerts, etc.). Widgets that
/// only render an offline indicator should watch this provider so they only
/// rebuild when the connection state itself transitions — which is rare.

@ProviderFor(connectionStatus)
final connectionStatusProvider = ConnectionStatusProvider._();

/// Read-only view of the WebSocket status, intended for UI widgets that
/// only care about the connection bar.
///
/// Why a separate provider: watching `systemEventNotifierProvider` rebuilds
/// on every incoming event (chat bursts, arrival alerts, etc.). Widgets that
/// only render an offline indicator should watch this provider so they only
/// rebuild when the connection state itself transitions — which is rare.

final class ConnectionStatusProvider
    extends
        $FunctionalProvider<
          WsConnectionStatus,
          WsConnectionStatus,
          WsConnectionStatus
        >
    with $Provider<WsConnectionStatus> {
  /// Read-only view of the WebSocket status, intended for UI widgets that
  /// only care about the connection bar.
  ///
  /// Why a separate provider: watching `systemEventNotifierProvider` rebuilds
  /// on every incoming event (chat bursts, arrival alerts, etc.). Widgets that
  /// only render an offline indicator should watch this provider so they only
  /// rebuild when the connection state itself transitions — which is rare.
  ConnectionStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionStatusHash();

  @$internal
  @override
  $ProviderElement<WsConnectionStatus> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WsConnectionStatus create(Ref ref) {
    return connectionStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WsConnectionStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WsConnectionStatus>(value),
    );
  }
}

String _$connectionStatusHash() => r'923f89d0fc986fe4870e373641a367da249a811b';

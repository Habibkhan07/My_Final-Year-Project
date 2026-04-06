// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier responsible for managing the state of the Technician Discovery result list.
///
/// **Intent**: Uses structured error handling to ensure that all network/server failures
/// are correctly propagated through the [DiscoveryFailure] pipeline defined in the domain layer,
/// without dropping existing loaded data.

@ProviderFor(DiscoveryNotifier)
final discoveryProvider = DiscoveryNotifierFamily._();

/// Notifier responsible for managing the state of the Technician Discovery result list.
///
/// **Intent**: Uses structured error handling to ensure that all network/server failures
/// are correctly propagated through the [DiscoveryFailure] pipeline defined in the domain layer,
/// without dropping existing loaded data.
final class DiscoveryNotifierProvider
    extends $AsyncNotifierProvider<DiscoveryNotifier, DiscoveryState> {
  /// Notifier responsible for managing the state of the Technician Discovery result list.
  ///
  /// **Intent**: Uses structured error handling to ensure that all network/server failures
  /// are correctly propagated through the [DiscoveryFailure] pipeline defined in the domain layer,
  /// without dropping existing loaded data.
  DiscoveryNotifierProvider._({
    required DiscoveryNotifierFamily super.from,
    required ({
      String? query,
      int? serviceId,
      int? subServiceId,
      int? promotionId,
      double? lat,
      double? lng,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'discoveryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$discoveryNotifierHash();

  @override
  String toString() {
    return r'discoveryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DiscoveryNotifier create() => DiscoveryNotifier();

  @override
  bool operator ==(Object other) {
    return other is DiscoveryNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$discoveryNotifierHash() => r'e43cb06026ba3d64786cb0562f5266af4a2eb5b5';

/// Notifier responsible for managing the state of the Technician Discovery result list.
///
/// **Intent**: Uses structured error handling to ensure that all network/server failures
/// are correctly propagated through the [DiscoveryFailure] pipeline defined in the domain layer,
/// without dropping existing loaded data.

final class DiscoveryNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DiscoveryNotifier,
          AsyncValue<DiscoveryState>,
          DiscoveryState,
          FutureOr<DiscoveryState>,
          ({
            String? query,
            int? serviceId,
            int? subServiceId,
            int? promotionId,
            double? lat,
            double? lng,
          })
        > {
  DiscoveryNotifierFamily._()
    : super(
        retry: null,
        name: r'discoveryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier responsible for managing the state of the Technician Discovery result list.
  ///
  /// **Intent**: Uses structured error handling to ensure that all network/server failures
  /// are correctly propagated through the [DiscoveryFailure] pipeline defined in the domain layer,
  /// without dropping existing loaded data.

  DiscoveryNotifierProvider call({
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    double? lat,
    double? lng,
  }) => DiscoveryNotifierProvider._(
    argument: (
      query: query,
      serviceId: serviceId,
      subServiceId: subServiceId,
      promotionId: promotionId,
      lat: lat,
      lng: lng,
    ),
    from: this,
  );

  @override
  String toString() => r'discoveryProvider';
}

/// Notifier responsible for managing the state of the Technician Discovery result list.
///
/// **Intent**: Uses structured error handling to ensure that all network/server failures
/// are correctly propagated through the [DiscoveryFailure] pipeline defined in the domain layer,
/// without dropping existing loaded data.

abstract class _$DiscoveryNotifier extends $AsyncNotifier<DiscoveryState> {
  late final _$args =
      ref.$arg
          as ({
            String? query,
            int? serviceId,
            int? subServiceId,
            int? promotionId,
            double? lat,
            double? lng,
          });
  String? get query => _$args.query;
  int? get serviceId => _$args.serviceId;
  int? get subServiceId => _$args.subServiceId;
  int? get promotionId => _$args.promotionId;
  double? get lat => _$args.lat;
  double? get lng => _$args.lng;

  FutureOr<DiscoveryState> build({
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    double? lat,
    double? lng,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DiscoveryState>, DiscoveryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DiscoveryState>, DiscoveryState>,
              AsyncValue<DiscoveryState>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        query: _$args.query,
        serviceId: _$args.serviceId,
        subServiceId: _$args.subServiceId,
        promotionId: _$args.promotionId,
        lat: _$args.lat,
        lng: _$args.lng,
      ),
    );
  }
}

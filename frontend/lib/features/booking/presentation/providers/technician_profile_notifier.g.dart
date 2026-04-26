// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TechnicianProfileNotifier)
final technicianProfileProvider = TechnicianProfileNotifierFamily._();

final class TechnicianProfileNotifierProvider
    extends
        $AsyncNotifierProvider<
          TechnicianProfileNotifier,
          TechnicianProfileEntity
        > {
  TechnicianProfileNotifierProvider._({
    required TechnicianProfileNotifierFamily super.from,
    required ({
      int id,
      double? lat,
      double? lng,
      int? serviceId,
      int? subServiceId,
      int? promotionId,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'technicianProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$technicianProfileNotifierHash();

  @override
  String toString() {
    return r'technicianProfileProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TechnicianProfileNotifier create() => TechnicianProfileNotifier();

  @override
  bool operator ==(Object other) {
    return other is TechnicianProfileNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$technicianProfileNotifierHash() =>
    r'8d1306d415bdb30bdd0984d1f4a6b0d1aecdcf56';

final class TechnicianProfileNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TechnicianProfileNotifier,
          AsyncValue<TechnicianProfileEntity>,
          TechnicianProfileEntity,
          FutureOr<TechnicianProfileEntity>,
          ({
            int id,
            double? lat,
            double? lng,
            int? serviceId,
            int? subServiceId,
            int? promotionId,
          })
        > {
  TechnicianProfileNotifierFamily._()
    : super(
        retry: null,
        name: r'technicianProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TechnicianProfileNotifierProvider call({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  }) => TechnicianProfileNotifierProvider._(
    argument: (
      id: id,
      lat: lat,
      lng: lng,
      serviceId: serviceId,
      subServiceId: subServiceId,
      promotionId: promotionId,
    ),
    from: this,
  );

  @override
  String toString() => r'technicianProfileProvider';
}

abstract class _$TechnicianProfileNotifier
    extends $AsyncNotifier<TechnicianProfileEntity> {
  late final _$args =
      ref.$arg
          as ({
            int id,
            double? lat,
            double? lng,
            int? serviceId,
            int? subServiceId,
            int? promotionId,
          });
  int get id => _$args.id;
  double? get lat => _$args.lat;
  double? get lng => _$args.lng;
  int? get serviceId => _$args.serviceId;
  int? get subServiceId => _$args.subServiceId;
  int? get promotionId => _$args.promotionId;

  FutureOr<TechnicianProfileEntity> build({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<TechnicianProfileEntity>,
              TechnicianProfileEntity
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TechnicianProfileEntity>,
                TechnicianProfileEntity
              >,
              AsyncValue<TechnicianProfileEntity>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        id: _$args.id,
        lat: _$args.lat,
        lng: _$args.lng,
        serviceId: _$args.serviceId,
        subServiceId: _$args.subServiceId,
        promotionId: _$args.promotionId,
      ),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotable_sub_services_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuotableSubServicesNotifier)
final quotableSubServicesProvider = QuotableSubServicesNotifierFamily._();

final class QuotableSubServicesNotifierProvider
    extends
        $AsyncNotifierProvider<
          QuotableSubServicesNotifier,
          List<QuotableSubServiceModel>
        > {
  QuotableSubServicesNotifierProvider._({
    required QuotableSubServicesNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'quotableSubServicesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quotableSubServicesNotifierHash();

  @override
  String toString() {
    return r'quotableSubServicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  QuotableSubServicesNotifier create() => QuotableSubServicesNotifier();

  @override
  bool operator ==(Object other) {
    return other is QuotableSubServicesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quotableSubServicesNotifierHash() =>
    r'5c3649b29791d99fed48585f1065e137a8697b8f';

final class QuotableSubServicesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          QuotableSubServicesNotifier,
          AsyncValue<List<QuotableSubServiceModel>>,
          List<QuotableSubServiceModel>,
          FutureOr<List<QuotableSubServiceModel>>,
          int
        > {
  QuotableSubServicesNotifierFamily._()
    : super(
        retry: null,
        name: r'quotableSubServicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  QuotableSubServicesNotifierProvider call(int serviceId) =>
      QuotableSubServicesNotifierProvider._(argument: serviceId, from: this);

  @override
  String toString() => r'quotableSubServicesProvider';
}

abstract class _$QuotableSubServicesNotifier
    extends $AsyncNotifier<List<QuotableSubServiceModel>> {
  late final _$args = ref.$arg as int;
  int get serviceId => _$args;

  FutureOr<List<QuotableSubServiceModel>> build(int serviceId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<QuotableSubServiceModel>>,
              List<QuotableSubServiceModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<QuotableSubServiceModel>>,
                List<QuotableSubServiceModel>
              >,
              AsyncValue<List<QuotableSubServiceModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

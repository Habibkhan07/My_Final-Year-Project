// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DraftNotifier)
final draftProvider = DraftNotifierFamily._();

final class DraftNotifierProvider
    extends $AsyncNotifierProvider<DraftNotifier, String> {
  DraftNotifierProvider._({
    required DraftNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'draftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$draftNotifierHash();

  @override
  String toString() {
    return r'draftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DraftNotifier create() => DraftNotifier();

  @override
  bool operator ==(Object other) {
    return other is DraftNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$draftNotifierHash() => r'5c7dcbe8f8fdcb0a175bbc0d6774be46997e0075';

final class DraftNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DraftNotifier,
          AsyncValue<String>,
          String,
          FutureOr<String>,
          int
        > {
  DraftNotifierFamily._()
    : super(
        retry: null,
        name: r'draftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DraftNotifierProvider call(int conversationId) =>
      DraftNotifierProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'draftProvider';
}

abstract class _$DraftNotifier extends $AsyncNotifier<String> {
  late final _$args = ref.$arg as int;
  int get conversationId => _$args;

  FutureOr<String> build(int conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HelpChatNotifier)
final helpChatProvider = HelpChatNotifierProvider._();

final class HelpChatNotifierProvider
    extends $AsyncNotifierProvider<HelpChatNotifier, HelpChatState> {
  HelpChatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'helpChatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$helpChatNotifierHash();

  @$internal
  @override
  HelpChatNotifier create() => HelpChatNotifier();
}

String _$helpChatNotifierHash() => r'7ccad3d9fb162486ea2ab5b8d7a5503b0d3022bb';

abstract class _$HelpChatNotifier extends $AsyncNotifier<HelpChatState> {
  FutureOr<HelpChatState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HelpChatState>, HelpChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HelpChatState>, HelpChatState>,
              AsyncValue<HelpChatState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

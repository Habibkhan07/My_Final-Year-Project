// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chatbot_session_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatbotSessionNotifier)
final chatbotSessionProvider = ChatbotSessionNotifierFamily._();

final class ChatbotSessionNotifierProvider
    extends $AsyncNotifierProvider<ChatbotSessionNotifier, ChatSession> {
  ChatbotSessionNotifierProvider._({
    required ChatbotSessionNotifierFamily super.from,
    required ({String personaKey, int bookingId}) super.argument,
  }) : super(
         retry: null,
         name: r'chatbotSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatbotSessionNotifierHash();

  @override
  String toString() {
    return r'chatbotSessionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ChatbotSessionNotifier create() => ChatbotSessionNotifier();

  @override
  bool operator ==(Object other) {
    return other is ChatbotSessionNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatbotSessionNotifierHash() =>
    r'c8eb02d33fb29f666dd591b48c994f7fd6758f44';

final class ChatbotSessionNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatbotSessionNotifier,
          AsyncValue<ChatSession>,
          ChatSession,
          FutureOr<ChatSession>,
          ({String personaKey, int bookingId})
        > {
  ChatbotSessionNotifierFamily._()
    : super(
        retry: null,
        name: r'chatbotSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatbotSessionNotifierProvider call({
    required String personaKey,
    required int bookingId,
  }) => ChatbotSessionNotifierProvider._(
    argument: (personaKey: personaKey, bookingId: bookingId),
    from: this,
  );

  @override
  String toString() => r'chatbotSessionProvider';
}

abstract class _$ChatbotSessionNotifier extends $AsyncNotifier<ChatSession> {
  late final _$args = ref.$arg as ({String personaKey, int bookingId});
  String get personaKey => _$args.personaKey;
  int get bookingId => _$args.bookingId;

  FutureOr<ChatSession> build({
    required String personaKey,
    required int bookingId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChatSession>, ChatSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChatSession>, ChatSession>,
              AsyncValue<ChatSession>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(personaKey: _$args.personaKey, bookingId: _$args.bookingId),
    );
  }
}

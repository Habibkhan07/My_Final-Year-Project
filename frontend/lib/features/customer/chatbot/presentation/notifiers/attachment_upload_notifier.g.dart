// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_upload_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AttachmentUploadNotifier)
final attachmentUploadProvider = AttachmentUploadNotifierFamily._();

final class AttachmentUploadNotifierProvider
    extends $NotifierProvider<AttachmentUploadNotifier, Set<String>> {
  AttachmentUploadNotifierProvider._({
    required AttachmentUploadNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'attachmentUploadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attachmentUploadNotifierHash();

  @override
  String toString() {
    return r'attachmentUploadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AttachmentUploadNotifier create() => AttachmentUploadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AttachmentUploadNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attachmentUploadNotifierHash() =>
    r'ef235eae1e4103b78a0d544080ca124e722549d9';

final class AttachmentUploadNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AttachmentUploadNotifier,
          Set<String>,
          Set<String>,
          Set<String>,
          int
        > {
  AttachmentUploadNotifierFamily._()
    : super(
        retry: null,
        name: r'attachmentUploadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AttachmentUploadNotifierProvider call(int conversationId) =>
      AttachmentUploadNotifierProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'attachmentUploadProvider';
}

abstract class _$AttachmentUploadNotifier extends $Notifier<Set<String>> {
  late final _$args = ref.$arg as int;
  int get conversationId => _$args;

  Set<String> build(int conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

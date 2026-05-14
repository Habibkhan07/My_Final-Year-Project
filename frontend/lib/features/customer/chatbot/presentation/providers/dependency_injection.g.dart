// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatbotHttpClient)
final chatbotHttpClientProvider = ChatbotHttpClientProvider._();

final class ChatbotHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  ChatbotHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatbotHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatbotHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return chatbotHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$chatbotHttpClientHash() => r'4232fa7cb0fcc6de6e66ab29f93e478278498f72';

@ProviderFor(chatbotSecureStorage)
final chatbotSecureStorageProvider = ChatbotSecureStorageProvider._();

final class ChatbotSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  ChatbotSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatbotSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatbotSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return chatbotSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$chatbotSecureStorageHash() =>
    r'8b87ad11db07338cb4a28f7645d56220d2a9a40f';

@ProviderFor(chatbotRemoteDataSource)
final chatbotRemoteDataSourceProvider = ChatbotRemoteDataSourceProvider._();

final class ChatbotRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IChatbotRemoteDataSource,
          IChatbotRemoteDataSource,
          IChatbotRemoteDataSource
        >
    with $Provider<IChatbotRemoteDataSource> {
  ChatbotRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatbotRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatbotRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IChatbotRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IChatbotRemoteDataSource create(Ref ref) {
    return chatbotRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IChatbotRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IChatbotRemoteDataSource>(value),
    );
  }
}

String _$chatbotRemoteDataSourceHash() =>
    r'6d898d1905b6c8ca91c9a423ea2935b2d20eb8eb';

@ProviderFor(chatbotLocalDataSource)
final chatbotLocalDataSourceProvider = ChatbotLocalDataSourceProvider._();

final class ChatbotLocalDataSourceProvider
    extends
        $FunctionalProvider<
          IChatbotLocalDataSource,
          IChatbotLocalDataSource,
          IChatbotLocalDataSource
        >
    with $Provider<IChatbotLocalDataSource> {
  ChatbotLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatbotLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatbotLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<IChatbotLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IChatbotLocalDataSource create(Ref ref) {
    return chatbotLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IChatbotLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IChatbotLocalDataSource>(value),
    );
  }
}

String _$chatbotLocalDataSourceHash() =>
    r'298767887df9b1b2147f674e4a575f235a1be78d';

@ProviderFor(chatbotRepository)
final chatbotRepositoryProvider = ChatbotRepositoryProvider._();

final class ChatbotRepositoryProvider
    extends
        $FunctionalProvider<
          IChatbotRepository,
          IChatbotRepository,
          IChatbotRepository
        >
    with $Provider<IChatbotRepository> {
  ChatbotRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatbotRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatbotRepositoryHash();

  @$internal
  @override
  $ProviderElement<IChatbotRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IChatbotRepository create(Ref ref) {
    return chatbotRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IChatbotRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IChatbotRepository>(value),
    );
  }
}

String _$chatbotRepositoryHash() => r'456412ca7e1893b07fbf50cf0cab701d5b0bf0d7';

@ProviderFor(startConversationUseCase)
final startConversationUseCaseProvider = StartConversationUseCaseProvider._();

final class StartConversationUseCaseProvider
    extends
        $FunctionalProvider<
          StartConversationUseCase,
          StartConversationUseCase,
          StartConversationUseCase
        >
    with $Provider<StartConversationUseCase> {
  StartConversationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startConversationUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startConversationUseCaseHash();

  @$internal
  @override
  $ProviderElement<StartConversationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StartConversationUseCase create(Ref ref) {
    return startConversationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartConversationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartConversationUseCase>(value),
    );
  }
}

String _$startConversationUseCaseHash() =>
    r'7b1317f5bbdba7fc79e7b35bf352757db5e30fa1';

@ProviderFor(fetchConversationUseCase)
final fetchConversationUseCaseProvider = FetchConversationUseCaseProvider._();

final class FetchConversationUseCaseProvider
    extends
        $FunctionalProvider<
          FetchConversationUseCase,
          FetchConversationUseCase,
          FetchConversationUseCase
        >
    with $Provider<FetchConversationUseCase> {
  FetchConversationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fetchConversationUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fetchConversationUseCaseHash();

  @$internal
  @override
  $ProviderElement<FetchConversationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FetchConversationUseCase create(Ref ref) {
    return fetchConversationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FetchConversationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FetchConversationUseCase>(value),
    );
  }
}

String _$fetchConversationUseCaseHash() =>
    r'3edf71f86791619cd73ca8d5b9144ba19200526d';

@ProviderFor(sendTextTurnUseCase)
final sendTextTurnUseCaseProvider = SendTextTurnUseCaseProvider._();

final class SendTextTurnUseCaseProvider
    extends
        $FunctionalProvider<
          SendTextTurnUseCase,
          SendTextTurnUseCase,
          SendTextTurnUseCase
        >
    with $Provider<SendTextTurnUseCase> {
  SendTextTurnUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendTextTurnUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendTextTurnUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendTextTurnUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SendTextTurnUseCase create(Ref ref) {
    return sendTextTurnUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendTextTurnUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendTextTurnUseCase>(value),
    );
  }
}

String _$sendTextTurnUseCaseHash() =>
    r'aa101d193c6810b74b0a0de060892133af170e56';

@ProviderFor(submitFormTurnUseCase)
final submitFormTurnUseCaseProvider = SubmitFormTurnUseCaseProvider._();

final class SubmitFormTurnUseCaseProvider
    extends
        $FunctionalProvider<
          SubmitFormTurnUseCase,
          SubmitFormTurnUseCase,
          SubmitFormTurnUseCase
        >
    with $Provider<SubmitFormTurnUseCase> {
  SubmitFormTurnUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitFormTurnUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitFormTurnUseCaseHash();

  @$internal
  @override
  $ProviderElement<SubmitFormTurnUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubmitFormTurnUseCase create(Ref ref) {
    return submitFormTurnUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubmitFormTurnUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubmitFormTurnUseCase>(value),
    );
  }
}

String _$submitFormTurnUseCaseHash() =>
    r'b7e57309299fd0f75a0dbd83ece89f3ca32f48c3';

@ProviderFor(uploadAttachmentUseCase)
final uploadAttachmentUseCaseProvider = UploadAttachmentUseCaseProvider._();

final class UploadAttachmentUseCaseProvider
    extends
        $FunctionalProvider<
          UploadAttachmentUseCase,
          UploadAttachmentUseCase,
          UploadAttachmentUseCase
        >
    with $Provider<UploadAttachmentUseCase> {
  UploadAttachmentUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadAttachmentUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadAttachmentUseCaseHash();

  @$internal
  @override
  $ProviderElement<UploadAttachmentUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UploadAttachmentUseCase create(Ref ref) {
    return uploadAttachmentUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadAttachmentUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadAttachmentUseCase>(value),
    );
  }
}

String _$uploadAttachmentUseCaseHash() =>
    r'2faae09924105e0eb769c3bb19ec075d1ef2e7fc';

@ProviderFor(notifyAttachmentsDoneUseCase)
final notifyAttachmentsDoneUseCaseProvider =
    NotifyAttachmentsDoneUseCaseProvider._();

final class NotifyAttachmentsDoneUseCaseProvider
    extends
        $FunctionalProvider<
          NotifyAttachmentsDoneUseCase,
          NotifyAttachmentsDoneUseCase,
          NotifyAttachmentsDoneUseCase
        >
    with $Provider<NotifyAttachmentsDoneUseCase> {
  NotifyAttachmentsDoneUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notifyAttachmentsDoneUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notifyAttachmentsDoneUseCaseHash();

  @$internal
  @override
  $ProviderElement<NotifyAttachmentsDoneUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotifyAttachmentsDoneUseCase create(Ref ref) {
    return notifyAttachmentsDoneUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotifyAttachmentsDoneUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotifyAttachmentsDoneUseCase>(value),
    );
  }
}

String _$notifyAttachmentsDoneUseCaseHash() =>
    r'cd3adce5dd8d2278f79adbf483bc98c2b4bcd99c';

@ProviderFor(closeConversationUseCase)
final closeConversationUseCaseProvider = CloseConversationUseCaseProvider._();

final class CloseConversationUseCaseProvider
    extends
        $FunctionalProvider<
          CloseConversationUseCase,
          CloseConversationUseCase,
          CloseConversationUseCase
        >
    with $Provider<CloseConversationUseCase> {
  CloseConversationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'closeConversationUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$closeConversationUseCaseHash();

  @$internal
  @override
  $ProviderElement<CloseConversationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CloseConversationUseCase create(Ref ref) {
    return closeConversationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloseConversationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloseConversationUseCase>(value),
    );
  }
}

String _$closeConversationUseCaseHash() =>
    r'0975fc07c75815f1b7cdc46bf6f2fbff3d23678e';

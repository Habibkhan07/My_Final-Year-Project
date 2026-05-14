// DI surface for the customer chatbot feature.
//
// Mirrors the layout of `features/customer/bookings/presentation/providers/
// dependency_injection.dart` — that file is the canonical reference for
// Clean Architecture wiring on the customer side. Provider order matches:
// Infrastructure → Data Sources → Repository → Use Cases.
//
// **All providers are `keepAlive: true`.** The session notifier itself
// is `keepAlive: false` (it owns per-screen state and should dispose
// when the chatbot screen pops), but the repository, data sources, and
// HTTP/secure-storage singletons should NOT be re-created on every
// screen mount — re-creating `FlutterSecureStorage` mid-session would
// thrash the platform channel and re-instantiating the repo would
// leave the local debounce timers without a place to land.
//
// **`sharedPreferencesProvider` is imported from the technician
// onboarding feature.** That is the single declared boot-time override
// across the app (`main.dart` overrides it once with the real
// `SharedPreferences.getInstance()` result). Every customer feature
// that needs prefs imports from there — see `bookings`'s DI for the
// same pattern.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../technician/onboarding/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/chatbot_local_data_source.dart';
import '../../data/data_sources/chatbot_remote_data_source.dart';
import '../../data/repositories/chatbot_repository_impl.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../../domain/use_cases/close_conversation_use_case.dart';
import '../../domain/use_cases/fetch_conversation_use_case.dart';
import '../../domain/use_cases/notify_attachments_done_use_case.dart';
import '../../domain/use_cases/send_text_turn_use_case.dart';
import '../../domain/use_cases/start_conversation_use_case.dart';
import '../../domain/use_cases/submit_form_turn_use_case.dart';
import '../../domain/use_cases/upload_attachment_use_case.dart';

part 'dependency_injection.g.dart';

// ─── Infrastructure ─────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
http.Client chatbotHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
FlutterSecureStorage chatbotSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ─── Data Sources ────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
IChatbotRemoteDataSource chatbotRemoteDataSource(Ref ref) =>
    ChatbotRemoteDataSource(
      client: ref.watch(chatbotHttpClientProvider),
      secureStorage: ref.watch(chatbotSecureStorageProvider),
    );

@Riverpod(keepAlive: true)
IChatbotLocalDataSource chatbotLocalDataSource(Ref ref) =>
    ChatbotLocalDataSource(ref.watch(sharedPreferencesProvider));

// ─── Repository ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
IChatbotRepository chatbotRepository(Ref ref) => ChatbotRepositoryImpl(
  remote: ref.watch(chatbotRemoteDataSourceProvider),
  local: ref.watch(chatbotLocalDataSourceProvider),
);

// ─── Use Cases ───────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
StartConversationUseCase startConversationUseCase(Ref ref) =>
    StartConversationUseCase(ref.watch(chatbotRepositoryProvider));

@Riverpod(keepAlive: true)
FetchConversationUseCase fetchConversationUseCase(Ref ref) =>
    FetchConversationUseCase(ref.watch(chatbotRepositoryProvider));

@Riverpod(keepAlive: true)
SendTextTurnUseCase sendTextTurnUseCase(Ref ref) =>
    SendTextTurnUseCase(ref.watch(chatbotRepositoryProvider));

@Riverpod(keepAlive: true)
SubmitFormTurnUseCase submitFormTurnUseCase(Ref ref) =>
    SubmitFormTurnUseCase(ref.watch(chatbotRepositoryProvider));

@Riverpod(keepAlive: true)
UploadAttachmentUseCase uploadAttachmentUseCase(Ref ref) =>
    UploadAttachmentUseCase(ref.watch(chatbotRepositoryProvider));

@Riverpod(keepAlive: true)
NotifyAttachmentsDoneUseCase notifyAttachmentsDoneUseCase(Ref ref) =>
    NotifyAttachmentsDoneUseCase(ref.watch(chatbotRepositoryProvider));

@Riverpod(keepAlive: true)
CloseConversationUseCase closeConversationUseCase(Ref ref) =>
    CloseConversationUseCase(ref.watch(chatbotRepositoryProvider));

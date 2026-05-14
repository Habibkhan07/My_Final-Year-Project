// In-flight upload tracker for the EVIDENCE-phase attachment composer.
//
// **What it owns:** a `Set<String>` of local file paths currently
// being uploaded. The composer's grid uses this to render a per-tile
// spinner overlay while an upload is mid-flight.
//
// **What it does NOT own:** the upload itself. The use-case call lives
// on [ChatbotSessionNotifier.uploadAttachment] so the resulting
// `attachmentsCount` flows back through the single session state. This
// notifier is purely transient UX bookkeeping.
//
// **Lifecycle:** `@riverpod` default — disposes on screen pop. There
// is no persistence; if the user closes mid-upload, the inflight set
// is gone and the next mount starts clean. The server-side upload may
// still complete (the HTTP request is in-flight) and a subsequent
// turn's GET-detail will surface the new count.
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attachment_upload_notifier.g.dart';

@riverpod
class AttachmentUploadNotifier extends _$AttachmentUploadNotifier {
  @override
  Set<String> build(int conversationId) => <String>{};

  /// Mark [filePath] as currently uploading. The composer's grid tile
  /// shows a spinner while the path is present in the set.
  void markStart(String filePath) {
    state = {...state, filePath};
  }

  /// Remove [filePath] from the in-flight set. Called after the
  /// upload completes (regardless of success or failure — the error
  /// itself surfaces through the session notifier's state).
  void markEnd(String filePath) {
    if (!state.contains(filePath)) return;
    final next = Set<String>.from(state)..remove(filePath);
    state = next;
  }

  /// True iff [filePath] is currently uploading.
  bool isUploading(String filePath) => state.contains(filePath);
}

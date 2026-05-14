// Shared stub IChatbotRepository for widget tests.
//
// Widget tests don't exercise the wire layer (CLAUDE.md: "NEVER mock
// network calls in widget tests"). Where a composer reads from
// providers that themselves need a repo to resolve, we install this
// stub via `ProviderScope` so the provider graph builds without
// reaching `http.Client`. Every method either throws (if the test is
// not expecting it to be called) or returns a sensible default.
//
// Tests that DO want to assert on repo invocations should compose
// their own narrower fake — see the notifier tests for that pattern.
import 'dart:typed_data';

import 'package:frontend/features/customer/chatbot/domain/entities/chat_session.dart';
import 'package:frontend/features/customer/chatbot/domain/repositories/chatbot_repository.dart';

class StubChatbotRepo implements IChatbotRepository {
  /// Per-conversation draft text. Returned by [loadDraftText]. Default
  /// empty.
  final Map<int, String?> drafts = {};

  /// Per-booking active recovery id (was a single global int; now
  /// per-booking to match the production fix that closed the
  /// cross-booking recovery leak — see plan §C).
  final Map<int, int?> activeIds = {};

  @override
  Future<ChatSession> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  }) => throw UnimplementedError('startConversation not expected in widget test');

  @override
  Future<ChatSession> fetchConversation(int conversationId) =>
      throw UnimplementedError('fetchConversation not expected in widget test');

  @override
  Future<ChatSession> sendTextTurn({
    required int conversationId,
    required int bookingId,
    required String text,
  }) => throw UnimplementedError('sendTextTurn not expected in widget test');

  @override
  Future<ChatSession> submitFormTurn({
    required int conversationId,
    required int bookingId,
    required Map<String, dynamic> values,
  }) => throw UnimplementedError('submitFormTurn not expected in widget test');

  @override
  Future<int> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  }) => throw UnimplementedError('uploadAttachment not expected in widget test');

  @override
  Future<ChatSession> notifyAttachmentsDone({
    required int conversationId,
    required int bookingId,
  }) => throw UnimplementedError('notifyAttachmentsDone not expected in widget test');

  @override
  Future<ChatSession> closeConversation({
    required int conversationId,
    required int bookingId,
  }) => throw UnimplementedError('closeConversation not expected in widget test');

  @override
  Future<void> saveDraftText({
    required int conversationId,
    required String? text,
  }) async {
    drafts[conversationId] = text;
  }

  @override
  Future<String?> loadDraftText(int conversationId) async =>
      drafts[conversationId];

  @override
  Future<void> setActiveConversationId({
    required int bookingId,
    required int? conversationId,
  }) async {
    activeIds[bookingId] = conversationId;
  }

  @override
  Future<int?> getActiveConversationId(int bookingId) async =>
      activeIds[bookingId];
}

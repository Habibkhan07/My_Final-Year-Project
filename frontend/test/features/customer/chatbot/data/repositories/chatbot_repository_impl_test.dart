// Tests for ChatbotRepositoryImpl — the step-2 of the error pipeline
// that translates HttpFailure / SocketException into the typed sealed
// ChatbotFailure hierarchy.
//
// Coverage:
//   * Every wire code from §7 of CHATBOT_FRONTEND_PLAN.md → matching
//     ChatbotFailure subtype (9 codes).
//   * SocketException → ChatbotNetworkFailure on every method.
//   * startConversation happy path persists the recovery id.
//   * Turn writes that auto-close the conversation clear the recovery
//     id + drop the draft.
//   * closeConversation does POST + GET-detail (idempotent path).
//   * uploadAttachment returns attachmentsCount from the wire model.
//   * AttachmentTooLargeFailure / AttachmentCountExceededFailure read
//     `errors.max_mb` / `errors.max` from the envelope (with fallback).
//   * FormValidationFailure carries the flattened fieldErrors map.
//   * UnknownChatbotFailure catch-all for unrecognised codes.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/chatbot/data/data_sources/chatbot_local_data_source.dart';
import 'package:frontend/features/customer/chatbot/data/data_sources/chatbot_remote_data_source.dart';
import 'package:frontend/features/customer/chatbot/data/models/attachment_upload_response_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/close_response_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/conversation_detail_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/conversation_start_response_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/turn_result_model.dart';
import 'package:frontend/features/customer/chatbot/data/repositories/chatbot_repository_impl.dart';
import 'package:frontend/features/customer/chatbot/domain/failures/chatbot_failure.dart';

import '../../_fixtures/wire_payloads.dart' as fx;

// ─── Hand-written fakes (same pattern as bookings repo tests) ─────────

class _FakeRemote implements IChatbotRemoteDataSource {
  /// If non-null and matches the called method, that method throws this.
  Object? throwOnStart;
  Object? throwOnGet;
  Object? throwOnSendText;
  Object? throwOnSubmitForm;
  Object? throwOnNotifyDone;
  Object? throwOnUpload;
  Object? throwOnClose;

  ConversationStartResponseModel? startResponse;
  ConversationDetailModel? getResponse;
  TurnResultModel? turnResponse;
  AttachmentUploadResponseModel? uploadResponse;
  CloseResponseModel? closeResponseValue;

  int closeCalls = 0;
  int getCalls = 0;

  @override
  Future<ConversationStartResponseModel> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  }) async {
    if (throwOnStart != null) throw throwOnStart!;
    return startResponse!;
  }

  @override
  Future<ConversationDetailModel> getConversation(int conversationId) async {
    getCalls++;
    if (throwOnGet != null) throw throwOnGet!;
    return getResponse!;
  }

  @override
  Future<TurnResultModel> sendTextMessage({
    required int conversationId,
    required String text,
  }) async {
    if (throwOnSendText != null) throw throwOnSendText!;
    return turnResponse!;
  }

  @override
  Future<TurnResultModel> submitForm({
    required int conversationId,
    required Map<String, dynamic> values,
  }) async {
    if (throwOnSubmitForm != null) throw throwOnSubmitForm!;
    return turnResponse!;
  }

  @override
  Future<TurnResultModel> notifyAttachmentsDone(int conversationId) async {
    if (throwOnNotifyDone != null) throw throwOnNotifyDone!;
    return turnResponse!;
  }

  // The remote close still takes a positional int — only the
  // repository-level surface added the bookingId requirement.

  @override
  Future<AttachmentUploadResponseModel> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  }) async {
    if (throwOnUpload != null) throw throwOnUpload!;
    return uploadResponse!;
  }

  @override
  Future<CloseResponseModel> closeConversation(int conversationId) async {
    closeCalls++;
    if (throwOnClose != null) throw throwOnClose!;
    return closeResponseValue!;
  }
}

class _FakeLocal implements IChatbotLocalDataSource {
  /// Per-booking active recovery ids (was a single global int — now
  /// per-booking to match the production fix).
  final Map<int, int?> activeIds = {};
  final Map<int, String?> drafts = {};

  int activeIdSetCalls = 0;
  int draftClearCalls = 0;

  @override
  Future<void> setActiveConversationId({
    required int bookingId,
    required int? conversationId,
  }) async {
    activeIdSetCalls++;
    activeIds[bookingId] = conversationId;
  }

  @override
  Future<int?> getActiveConversationId(int bookingId) async =>
      activeIds[bookingId];

  @override
  Future<void> saveDraftText({
    required int conversationId,
    required String? text,
  }) async {
    if (text == null) draftClearCalls++;
    drafts[conversationId] = text;
  }

  @override
  Future<String?> loadDraftText(int conversationId) async =>
      drafts[conversationId];

  @override
  Future<void> clear() async {
    activeIds.clear();
    drafts.clear();
  }
}

ChatbotRepositoryImpl _build({
  required _FakeRemote remote,
  required _FakeLocal local,
}) {
  return ChatbotRepositoryImpl(remote: remote, local: local);
}

HttpFailure _envFailure({
  int status = 400,
  required String code,
  String message = 'Something went wrong.',
  Map<String, dynamic> errors = const {},
}) {
  return HttpFailure(
    statusCode: status,
    code: code,
    message: message,
    errors: errors,
  );
}

void main() {
  // ─── startConversation ──────────────────────────────────────────────

  group('startConversation', () {
    test('happy path: persists recovery id', () async {
      final remote = _FakeRemote()
        ..startResponse = ConversationStartResponseModel.fromJson(
          fx.startResponse(conversationId: 7777),
        );
      final local = _FakeLocal();
      final repo = _build(remote: remote, local: local);

      final session = await repo.startConversation(
        personaKey: 'dispute',
        context: const {'booking_id': 9001},
      );

      expect(session.conversationId, 7777);
      // Per-booking recovery — bookingId came from the start context.
      expect(local.activeIds[9001], 7777);
    });

    test('not_eligible_to_start → NotEligibleToStartFailure', () async {
      final remote = _FakeRemote()
        ..throwOnStart = _envFailure(code: 'not_eligible_to_start');
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.startConversation(personaKey: 'dispute', context: const {}),
        throwsA(isA<NotEligibleToStartFailure>()),
      );
    });

    test('persona_not_found → PersonaNotFoundFailure', () async {
      final remote = _FakeRemote()
        ..throwOnStart = _envFailure(status: 404, code: 'persona_not_found');
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.startConversation(personaKey: 'x', context: const {}),
        throwsA(isA<PersonaNotFoundFailure>()),
      );
    });

    test('SocketException → ChatbotNetworkFailure', () async {
      final remote = _FakeRemote()..throwOnStart = const SocketException('offline');
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.startConversation(personaKey: 'dispute', context: const {}),
        throwsA(isA<ChatbotNetworkFailure>()),
      );
    });

    test('untyped exception → UnknownChatbotFailure', () async {
      final remote = _FakeRemote()..throwOnStart = StateError('boom');
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.startConversation(personaKey: 'dispute', context: const {}),
        throwsA(isA<UnknownChatbotFailure>()),
      );
    });
  });

  // ─── fetchConversation ──────────────────────────────────────────────

  group('fetchConversation', () {
    test('happy path returns session from detail', () async {
      final remote = _FakeRemote()
        ..getResponse = ConversationDetailModel.fromJson(
          fx.conversationDetail(conversationId: 42),
        );
      final repo = _build(remote: remote, local: _FakeLocal());
      final session = await repo.fetchConversation(42);
      expect(session.conversationId, 42);
    });

    test('conversation_not_found → ConversationNotFoundFailure', () async {
      final remote = _FakeRemote()
        ..throwOnGet = _envFailure(status: 404, code: 'conversation_not_found');
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.fetchConversation(99),
        throwsA(isA<ConversationNotFoundFailure>()),
      );
    });
  });

  // ─── Turn writes ────────────────────────────────────────────────────

  group('sendTextTurn', () {
    test('happy path returns merged session from detail GET', () async {
      final remote = _FakeRemote()
        ..turnResponse = TurnResultModel.fromJson(fx.turnResponse())
        ..getResponse = ConversationDetailModel.fromJson(
          fx.conversationDetail(),
        );
      final repo = _build(remote: remote, local: _FakeLocal());
      final session = await repo.sendTextTurn(
        conversationId: 1, bookingId: 9001, text: 'hi',
      );
      expect(session.conversationId, 7001);
      // _runTurn always GETs detail after the POST.
      expect(remote.getCalls, 1);
    });

    test(
      'turn auto-closes the conversation → clears recovery id + draft',
      () async {
        // Both the turn AND the detail reflect closure — that's how the
        // backend actually responds when a turn auto-closes (the next
        // detail GET sees the same closed state). The repo reads
        // closed-ness from the turn response (authoritative actor); the
        // detail GET is just for the transcript.
        final remote = _FakeRemote()
          ..turnResponse = TurnResultModel.fromJson(
            fx.turnResponse(
              isClosed: true,
              outputRefs: const {'support_ticket_id': 9},
            ),
          )
          ..getResponse = ConversationDetailModel.fromJson(
            fx.conversationDetail(
              isClosed: true,
              outputRefs: const {'support_ticket_id': 9},
            ),
          );
        final local = _FakeLocal();
        local.activeIds[9001] = 7001;
        local.drafts[7001] = 'half-typed';
        final repo = _build(remote: remote, local: local);

        await repo.sendTextTurn(
          conversationId: 7001, bookingId: 9001, text: 'final',
        );

        // Repository clears the recovery target + the persisted draft.
        expect(local.activeIds[9001], isNull);
        expect(local.drafts[7001], isNull);
        expect(local.draftClearCalls, greaterThanOrEqualTo(1));
      },
    );

    test('conversation_closed → ConversationClosedFailure', () async {
      final remote = _FakeRemote()
        ..throwOnSendText = _envFailure(
          status: 409,
          code: 'conversation_closed',
        );
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.sendTextTurn(conversationId: 1, bookingId: 9001, text: 'x'),
        throwsA(isA<ConversationClosedFailure>()),
      );
    });

    test('llm_quota_exceeded → LlmQuotaExceededFailure', () async {
      final remote = _FakeRemote()
        ..throwOnSendText = _envFailure(
          status: 429,
          code: 'llm_quota_exceeded',
        );
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.sendTextTurn(conversationId: 1, bookingId: 9001, text: 'x'),
        throwsA(isA<LlmQuotaExceededFailure>()),
      );
    });

    test('unsupported_message_kind → UnsupportedMessageKindFailure', () async {
      final remote = _FakeRemote()
        ..throwOnSendText = _envFailure(
          code: 'unsupported_message_kind',
        );
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.sendTextTurn(conversationId: 1, bookingId: 9001, text: 'x'),
        throwsA(isA<UnsupportedMessageKindFailure>()),
      );
    });

    test('SocketException → ChatbotNetworkFailure', () async {
      final remote = _FakeRemote()
        ..throwOnSendText = const SocketException('offline');
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.sendTextTurn(conversationId: 1, bookingId: 9001, text: 'x'),
        throwsA(isA<ChatbotNetworkFailure>()),
      );
    });
  });

  // ─── submitFormTurn ─────────────────────────────────────────────────

  group('submitFormTurn', () {
    test('validation_error → FormValidationFailure with field map', () async {
      final remote = _FakeRemote()
        ..throwOnSubmitForm = _envFailure(
          code: 'validation_error',
          errors: const {
            'iban': ['IBAN format is invalid.'],
            'bank_name': ['Required.'],
          },
        );
      final repo = _build(remote: remote, local: _FakeLocal());
      try {
        await repo.submitFormTurn(conversationId: 1, bookingId: 9001, values: const {});
        fail('expected FormValidationFailure');
      } on FormValidationFailure catch (e) {
        expect(e.fieldErrors['iban'], ['IBAN format is invalid.']);
        expect(e.fieldErrors['bank_name'], ['Required.']);
      }
    });

    test(
      'validation_error with non-list error value normalises to single-element list',
      () async {
        final remote = _FakeRemote()
          ..throwOnSubmitForm = _envFailure(
            code: 'validation_error',
            errors: const {'iban': 'IBAN is short.'},
          );
        final repo = _build(remote: remote, local: _FakeLocal());
        try {
          await repo.submitFormTurn(conversationId: 1, bookingId: 9001, values: const {});
          fail('expected FormValidationFailure');
        } on FormValidationFailure catch (e) {
          expect(e.fieldErrors['iban'], ['IBAN is short.']);
        }
      },
    );
  });

  // ─── notifyAttachmentsDone ──────────────────────────────────────────

  group('notifyAttachmentsDone', () {
    test('happy path: returns session via GET-detail', () async {
      final remote = _FakeRemote()
        ..turnResponse = TurnResultModel.fromJson(fx.turnResponse())
        ..getResponse = ConversationDetailModel.fromJson(
          fx.conversationDetail(),
        );
      final repo = _build(remote: remote, local: _FakeLocal());
      final session = await repo.notifyAttachmentsDone(
        conversationId: 7001, bookingId: 9001,
      );
      expect(session.conversationId, 7001);
    });
  });

  // ─── uploadAttachment ───────────────────────────────────────────────

  group('uploadAttachment', () {
    test('returns attachments_count from wire model', () async {
      final remote = _FakeRemote()
        ..uploadResponse = AttachmentUploadResponseModel.fromJson(
          fx.attachmentUploadResponse(attachmentsCount: 3),
        );
      final repo = _build(remote: remote, local: _FakeLocal());
      final count = await repo.uploadAttachment(
        conversationId: 1,
        filename: 'x.jpg',
        bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
      );
      expect(count, 3);
    });

    test(
      'attachment_too_large → AttachmentTooLargeFailure with maxMb from envelope',
      () async {
        final remote = _FakeRemote()
          ..throwOnUpload = _envFailure(
            status: 413,
            code: 'attachment_too_large',
            errors: const {'max_mb': 8},
          );
        final repo = _build(remote: remote, local: _FakeLocal());
        try {
          await repo.uploadAttachment(
            conversationId: 1,
            filename: 'x.jpg',
            bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
          );
          fail('expected AttachmentTooLargeFailure');
        } on AttachmentTooLargeFailure catch (e) {
          expect(e.maxMb, 8);
        }
      },
    );

    test(
      'attachment_too_large without max_mb in envelope falls back to 10',
      () async {
        final remote = _FakeRemote()
          ..throwOnUpload = _envFailure(
            status: 413,
            code: 'attachment_too_large',
          );
        final repo = _build(remote: remote, local: _FakeLocal());
        try {
          await repo.uploadAttachment(
            conversationId: 1,
            filename: 'x.jpg',
            bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
          );
          fail('expected AttachmentTooLargeFailure');
        } on AttachmentTooLargeFailure catch (e) {
          expect(e.maxMb, 10);
        }
      },
    );

    test(
      'attachment_count_exceeded → AttachmentCountExceededFailure with max from envelope',
      () async {
        final remote = _FakeRemote()
          ..throwOnUpload = _envFailure(
            code: 'attachment_count_exceeded',
            errors: const {'max': 5},
          );
        final repo = _build(remote: remote, local: _FakeLocal());
        try {
          await repo.uploadAttachment(
            conversationId: 1,
            filename: 'x.jpg',
            bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
          );
          fail('expected AttachmentCountExceededFailure');
        } on AttachmentCountExceededFailure catch (e) {
          expect(e.maxCount, 5);
        }
      },
    );
  });

  // ─── closeConversation ─────────────────────────────────────────────

  group('closeConversation', () {
    test(
      'POST + GET-detail, clears recovery id, drops draft',
      () async {
        final remote = _FakeRemote()
          ..closeResponseValue = CloseResponseModel.fromJson(fx.closeResponse())
          ..getResponse = ConversationDetailModel.fromJson(
            fx.conversationDetail(
              isClosed: true,
              outputRefs: const {'support_ticket_id': 1284},
            ),
          );
        final local = _FakeLocal();
        local.activeIds[9001] = 7001;
        local.drafts[7001] = 'in-progress';
        final repo = _build(remote: remote, local: local);

        final session = await repo.closeConversation(
          conversationId: 7001, bookingId: 9001,
        );

        expect(session.isClosed, isTrue);
        expect(session.outputRefs!.ticketId, 1284);
        expect(local.activeIds[9001], isNull);
        expect(local.drafts[7001], isNull);
        expect(remote.closeCalls, 1);
        expect(remote.getCalls, 1);
      },
    );

    test('SocketException on close → ChatbotNetworkFailure', () async {
      final remote = _FakeRemote()
        ..throwOnClose = const SocketException('offline');
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.closeConversation(conversationId: 1, bookingId: 9001),
        throwsA(isA<ChatbotNetworkFailure>()),
      );
    });
  });

  // ─── Unknown code catch-all ─────────────────────────────────────────

  group('unrecognised wire codes', () {
    test('arbitrary code → UnknownChatbotFailure', () async {
      final remote = _FakeRemote()
        ..throwOnGet = _envFailure(code: 'something_new_from_backend');
      final repo = _build(remote: remote, local: _FakeLocal());
      await expectLater(
        () => repo.fetchConversation(1),
        throwsA(isA<UnknownChatbotFailure>()),
      );
    });
  });
}

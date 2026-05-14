// Wire-level tests for ChatbotRemoteDataSource.
//
// Covers:
//   * URL composition for every endpoint (start / get / message / upload /
//     close), including the persona key + conversation id path segments.
//   * Auth header attachment from secure storage on every authed call.
//   * Multipart upload field name == 'file' (matches backend serializer).
//   * Successful body decoding into the matching wire model.
//   * HttpFailure mapping for the documented error envelopes
//     (`not_eligible_to_start`, `conversation_not_found`,
//     `conversation_closed`, `llm_quota_exceeded`, `validation_error`,
//     `attachment_too_large`, `attachment_count_exceeded`).
//   * SocketException propagation (the repository, not this layer, maps
//     it to ChatbotNetworkFailure).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/chatbot/data/data_sources/chatbot_remote_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../_fixtures/wire_payloads.dart' as fx;

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _Captured {
  http.Request? request;
}

ChatbotRemoteDataSource _build({
  required http.Client client,
  required FlutterSecureStorage storage,
}) {
  return ChatbotRemoteDataSource(client: client, secureStorage: storage);
}

void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });

  // ─── startConversation ────────────────────────────────────────────────

  group('startConversation', () {
    test('POSTs /api/chat/<persona>/start/ with context body', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(fx.startResponse()), 200);
      });

      await _build(client: client, storage: storage).startConversation(
        personaKey: 'dispute',
        context: const {'booking_id': 9001},
      );

      final req = captured.request!;
      expect(req.method, 'POST');
      expect(req.url.path, '/api/chat/dispute/start/');
      expect(req.headers['authorization'], 'Token test-token');
      expect(
        jsonDecode(req.body),
        {
          'context': {'booking_id': 9001},
        },
      );
    });

    test('decodes 200 envelope into ConversationStartResponseModel', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            fx.startResponse(conversationId: 7042, personaKey: 'dispute'),
          ),
          200,
        ),
      );

      final model = await _build(client: client, storage: storage)
          .startConversation(personaKey: 'dispute', context: const {});

      expect(model.conversationId, 7042);
      expect(model.personaKey, 'dispute');
      expect(model.currentPhase, 'UNDERSTAND');
      expect(model.uiInputKind, 'text');
    });

    test('400 not_eligible_to_start → HttpFailure with code', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            fx.errorEnvelope(
              status: 400,
              code: 'not_eligible_to_start',
              message: 'Booking already disputed.',
            ),
          ),
          400,
        ),
      );
      try {
        await _build(client: client, storage: storage).startConversation(
          personaKey: 'dispute',
          context: const {'booking_id': 1},
        );
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 400);
        expect(e.code, 'not_eligible_to_start');
        expect(e.message, 'Booking already disputed.');
      }
    });

    test('404 persona_not_found → HttpFailure with code', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            fx.errorEnvelope(status: 404, code: 'persona_not_found'),
          ),
          404,
        ),
      );
      try {
        await _build(client: client, storage: storage).startConversation(
          personaKey: 'mystery',
          context: const {},
        );
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 404);
        expect(e.code, 'persona_not_found');
      }
    });
  });

  // ─── getConversation ──────────────────────────────────────────────────

  group('getConversation', () {
    test('GETs /api/chat/conversations/<id>/ with auth header', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(
          jsonEncode(fx.conversationDetail(conversationId: 88)),
          200,
        );
      });

      await _build(client: client, storage: storage).getConversation(88);

      final req = captured.request!;
      expect(req.method, 'GET');
      expect(req.url.path, '/api/chat/conversations/88/');
      expect(req.headers['authorization'], 'Token test-token');
    });

    test('200 with closed=true decodes output_refs', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            fx.conversationDetail(
              conversationId: 88,
              isClosed: true,
              closedAt: '2026-05-14T12:00:00+00:00',
              outputRefs: const {'support_ticket_id': 4242},
            ),
          ),
          200,
        ),
      );

      final model = await _build(
        client: client,
        storage: storage,
      ).getConversation(88);

      expect(model.isClosed, isTrue);
      expect(model.outputRefs['support_ticket_id'], 4242);
    });

    test('404 conversation_not_found → HttpFailure', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            fx.errorEnvelope(status: 404, code: 'conversation_not_found'),
          ),
          404,
        ),
      );
      try {
        await _build(client: client, storage: storage).getConversation(99);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.code, 'conversation_not_found');
      }
    });
  });

  // ─── sendTextMessage ──────────────────────────────────────────────────

  group('sendTextMessage', () {
    test('POSTs /message/ with kind=text + bare-string payload', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(fx.turnResponse()), 200);
      });

      await _build(client: client, storage: storage).sendTextMessage(
        conversationId: 7001,
        text: 'the AC is still broken',
      );

      final req = captured.request!;
      expect(req.method, 'POST');
      expect(req.url.path, '/api/chat/conversations/7001/message/');
      expect(jsonDecode(req.body), {
        'kind': 'text',
        'payload': 'the AC is still broken',
      });
    });

    test('409 conversation_closed → HttpFailure', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            fx.errorEnvelope(status: 409, code: 'conversation_closed'),
          ),
          409,
        ),
      );
      try {
        await _build(client: client, storage: storage)
            .sendTextMessage(conversationId: 1, text: 'x');
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 409);
        expect(e.code, 'conversation_closed');
      }
    });

    test('429 llm_quota_exceeded → HttpFailure', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            fx.errorEnvelope(status: 429, code: 'llm_quota_exceeded'),
          ),
          429,
        ),
      );
      try {
        await _build(client: client, storage: storage)
            .sendTextMessage(conversationId: 1, text: 'x');
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 429);
        expect(e.code, 'llm_quota_exceeded');
      }
    });
  });

  // ─── submitForm ───────────────────────────────────────────────────────

  group('submitForm', () {
    test('POSTs /message/ with kind=form + payload=values', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(fx.turnResponse()), 200);
      });

      await _build(client: client, storage: storage).submitForm(
        conversationId: 7001,
        values: const {
          'bank_name': 'HBL',
          'account_title': 'Hamayon Khan',
          'iban': 'PK00ABCD0123456789012345',
        },
      );

      expect(jsonDecode(captured.request!.body), {
        'kind': 'form',
        'payload': {
          'bank_name': 'HBL',
          'account_title': 'Hamayon Khan',
          'iban': 'PK00ABCD0123456789012345',
        },
      });
    });

    test('400 validation_error envelope carries errors map', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            fx.errorEnvelope(
              status: 400,
              code: 'validation_error',
              message: 'Please correct the highlighted fields.',
              errors: const {
                'iban': ['IBAN format is invalid.'],
              },
            ),
          ),
          400,
        ),
      );
      try {
        await _build(client: client, storage: storage)
            .submitForm(conversationId: 1, values: const {});
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.code, 'validation_error');
        expect(e.errors['iban'], ['IBAN format is invalid.']);
      }
    });
  });

  // ─── notifyAttachmentsDone ────────────────────────────────────────────

  group('notifyAttachmentsDone', () {
    test('POSTs /message/ with kind=attachment_done + empty payload', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(fx.turnResponse()), 200);
      });
      await _build(
        client: client,
        storage: storage,
      ).notifyAttachmentsDone(7001);

      expect(jsonDecode(captured.request!.body), {
        'kind': 'attachment_done',
        'payload': const {},
      });
    });
  });

  // ─── uploadAttachment (multipart) ─────────────────────────────────────

  group('uploadAttachment', () {
    // Synthetic JPEG bytes — the wire-level test doesn't care that
    // these aren't a real image (the backend's ImageField is mocked out
    // by MockClient).
    final fakeJpegBytes = Uint8List.fromList(
      const [0xFF, 0xD8, 0xFF, 0xD9],
    );

    test(
      'multipart POST with field name "file" + filename + auth header',
      () async {
        http.BaseRequest? capturedReq;
        final client = MockClient.streaming((request, bodyStream) async {
          capturedReq = request;
          await bodyStream.drain<void>();
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(fx.attachmentUploadResponse()))),
            200,
          );
        });

        final result = await _build(
          client: client,
          storage: storage,
        ).uploadAttachment(
          conversationId: 7001,
          filename: 'evidence.jpg',
          bytes: fakeJpegBytes,
        );

        expect(result.attachmentId, 42);
        expect(result.attachmentsCount, 1);

        final multipart = capturedReq! as http.MultipartRequest;
        expect(multipart.method, 'POST');
        expect(
          multipart.url.path,
          '/api/chat/conversations/7001/attachments/',
        );
        expect(multipart.headers['Authorization'], 'Token test-token');
        expect(multipart.files, hasLength(1));
        expect(multipart.files.first.field, 'file');
        expect(multipart.files.first.filename, 'evidence.jpg');
        // .jpg → image/jpeg sniffed by _maybeImageContentType.
        expect(
          multipart.files.first.contentType.toString(),
          'image/jpeg',
        );
      },
    );

    test('413 attachment_too_large surfaces errors.max_mb', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode(
                fx.errorEnvelope(
                  status: 413,
                  code: 'attachment_too_large',
                  errors: const {'max_mb': 10},
                ),
              ),
            ),
          ),
          413,
        );
      });

      try {
        await _build(client: client, storage: storage).uploadAttachment(
          conversationId: 1,
          filename: 'huge.jpg',
          bytes: fakeJpegBytes,
        );
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 413);
        expect(e.code, 'attachment_too_large');
        expect(e.errors['max_mb'], 10);
      }
    });

    test('400 attachment_count_exceeded surfaces errors.max', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode(
                fx.errorEnvelope(
                  status: 400,
                  code: 'attachment_count_exceeded',
                  errors: const {'max': 10},
                ),
              ),
            ),
          ),
          400,
        );
      });

      try {
        await _build(client: client, storage: storage).uploadAttachment(
          conversationId: 1,
          filename: 'over_limit.jpg',
          bytes: fakeJpegBytes,
        );
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.code, 'attachment_count_exceeded');
        expect(e.errors['max'], 10);
      }
    });
  });

  // ─── closeConversation ────────────────────────────────────────────────

  group('closeConversation', () {
    test('POSTs /close/ with empty body and parses CloseResponseModel', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(fx.closeResponse()), 200);
      });

      final model = await _build(
        client: client,
        storage: storage,
      ).closeConversation(7001);

      expect(captured.request!.method, 'POST');
      expect(captured.request!.url.path, '/api/chat/conversations/7001/close/');
      expect(jsonDecode(captured.request!.body), const {});
      expect(model.closedAt, '2026-05-14T12:00:00+00:00');
      expect(model.outputRefs['support_ticket_id'], 1284);
    });
  });

  // ─── Auth header — missing token ──────────────────────────────────────

  group('auth header — no token stored', () {
    test('omits Authorization header when secureStorage returns null', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(
          jsonEncode(fx.conversationDetail(conversationId: 1)),
          200,
        );
      });

      await _build(client: client, storage: storage).getConversation(1);
      expect(
        captured.request!.headers.containsKey('authorization'),
        isFalse,
      );
    });
  });

  // ─── SocketException propagation ──────────────────────────────────────

  group('SocketException propagation', () {
    test('not caught by data source (repository handles it)', () async {
      final client = MockClient((_) async {
        throw const SocketException('offline');
      });
      expect(
        () => _build(client: client, storage: storage).getConversation(1),
        throwsA(isA<SocketException>()),
      );
    });
  });

  // ─── Non-JSON 5xx fallback ────────────────────────────────────────────

  group('non-JSON body fallback', () {
    test('HTML 502 body falls back to synthetic server_error', () async {
      final client = MockClient(
        (_) async => http.Response('<html>Bad Gateway</html>', 502),
      );
      try {
        await _build(client: client, storage: storage).getConversation(1);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 502);
        expect(e.code, 'server_error');
      }
    });
  });
}

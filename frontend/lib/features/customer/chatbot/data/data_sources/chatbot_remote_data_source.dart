// Wire-level entry point for the chatbot's five endpoints.
//
// Throws [HttpFailure] (parsed from the standard error envelope) for
// any non-2xx response. Lets [SocketException] propagate so the
// repository can map it to [ChatbotNetworkFailure]. Mirrors the
// pattern of [CustomerBookingsRemoteDataSource] so the repository's
// `_mapFailure` switch keys off the same envelope shape across both
// features.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../models/attachment_upload_response_model.dart';
import '../models/close_response_model.dart';
import '../models/conversation_detail_model.dart';
import '../models/conversation_start_response_model.dart';
import '../models/turn_result_model.dart';

abstract class IChatbotRemoteDataSource {
  /// `POST /api/chat/<personaKey>/start/`
  Future<ConversationStartResponseModel> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  });

  /// `GET /api/chat/conversations/<id>/`
  Future<ConversationDetailModel> getConversation(int conversationId);

  /// `POST /api/chat/conversations/<id>/message/` with kind `text`.
  Future<TurnResultModel> sendTextMessage({
    required int conversationId,
    required String text,
  });

  /// `POST /api/chat/conversations/<id>/message/` with kind `form`.
  Future<TurnResultModel> submitForm({
    required int conversationId,
    required Map<String, dynamic> values,
  });

  /// `POST /api/chat/conversations/<id>/message/` with kind
  /// `attachment_done`. Advances out of EVIDENCE without uploading
  /// further files (zero attachments is allowed by the backend).
  Future<TurnResultModel> notifyAttachmentsDone(int conversationId);

  /// `POST /api/chat/conversations/<id>/attachments/` (multipart).
  ///
  /// Bytes-based contract (cross-platform: web has no real File). The
  /// caller (composer) reads bytes once via `XFile.readAsBytes()` and
  /// passes them along with the original filename for the multipart
  /// `filename` field — the backend uses it for content-type sniffing
  /// and storage path generation.
  Future<AttachmentUploadResponseModel> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  });

  /// `POST /api/chat/conversations/<id>/close/`. Idempotent — second
  /// call returns the same `closed_at` + `output_refs` as the first.
  Future<CloseResponseModel> closeConversation(int conversationId);
}

class ChatbotRemoteDataSource implements IChatbotRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  /// Matches the key written by `AuthLocalDataSource` (same convention
  /// every authenticated data source uses across the codebase).
  static const String _tokenKey = 'auth_token';

  ChatbotRemoteDataSource({required this.client, required this.secureStorage});

  // ─── Start ─────────────────────────────────────────────────────────────

  @override
  Future<ConversationStartResponseModel> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/chat/$personaKey/start/');
    final response = await _authedPostJson(uri, {'context': context});
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ConversationStartResponseModel.fromJson(json);
  }

  // ─── Get ───────────────────────────────────────────────────────────────

  @override
  Future<ConversationDetailModel> getConversation(int conversationId) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/chat/conversations/$conversationId/',
    );
    final response = await _authedGet(uri);
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ConversationDetailModel.fromJson(json);
  }

  // ─── Message turns ─────────────────────────────────────────────────────

  @override
  Future<TurnResultModel> sendTextMessage({
    required int conversationId,
    required String text,
  }) {
    return _postMessage(
      conversationId: conversationId,
      body: {
        'kind': 'text',
        'payload': text,
      },
    );
  }

  @override
  Future<TurnResultModel> submitForm({
    required int conversationId,
    required Map<String, dynamic> values,
  }) {
    return _postMessage(
      conversationId: conversationId,
      body: {'kind': 'form', 'payload': values},
    );
  }

  @override
  Future<TurnResultModel> notifyAttachmentsDone(int conversationId) {
    return _postMessage(
      conversationId: conversationId,
      // Empty payload — the kind discriminator is enough.
      body: {'kind': 'attachment_done', 'payload': {}},
    );
  }

  Future<TurnResultModel> _postMessage({
    required int conversationId,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/chat/conversations/$conversationId/message/',
    );
    final response = await _authedPostJson(uri, body);
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return TurnResultModel.fromJson(json);
  }

  // ─── Attachment upload (multipart) ─────────────────────────────────────

  @override
  Future<AttachmentUploadResponseModel> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/chat/conversations/$conversationId/attachments/',
    );
    final token = await secureStorage.read(key: _tokenKey);

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Token $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        // Field name matches `AttachmentUploadSerializer.file`.
        'file',
        bytes,
        filename: filename,
        // Mime type left null → http_parser falls back to
        // application/octet-stream. The backend's ImageField re-validates
        // the actual bytes regardless, so getting this wrong only costs a
        // 400 envelope, not data corruption.
        contentType: _maybeImageContentType(filename),
      ),
    );

    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AttachmentUploadResponseModel.fromJson(json);
  }

  /// Best-effort content-type sniff by filename extension. Returning
  /// null is fine — `http_parser` falls back to
  /// `application/octet-stream` and the backend's ImageField re-validates
  /// the actual bytes.
  MediaType? _maybeImageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.heic')) return MediaType('image', 'heic');
    return null;
  }

  // ─── Close ─────────────────────────────────────────────────────────────

  @override
  Future<CloseResponseModel> closeConversation(int conversationId) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/chat/conversations/$conversationId/close/',
    );
    // Empty body — close takes no payload.
    final response = await _authedPostJson(uri, const {});
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CloseResponseModel.fromJson(json);
  }

  // ─── Shared transport helpers ──────────────────────────────────────────

  Future<http.Response> _authedGet(Uri uri) async {
    final token = await secureStorage.read(key: _tokenKey);
    return client.get(
      uri,
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Token $token',
      },
    );
  }

  Future<http.Response> _authedPostJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final token = await secureStorage.read(key: _tokenKey);
    return client.post(
      uri,
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Token $token',
      },
      body: jsonEncode(body),
    );
  }

  /// Maps a non-2xx response to an [HttpFailure] from the standard
  /// envelope. Mirrors the helper in
  /// [CustomerBookingsRemoteDataSource]. Falls back to a synthetic
  /// `server_error` for non-JSON bodies so the repository's switch
  /// always has a code to key off.
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'] as String,
          message: (body['message'] as String?) ?? 'An error occurred',
          errors: (body['errors'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
      }
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: body is Map
            ? (body['detail']?.toString() ??
                  body['error']?.toString() ??
                  'Unknown error')
            : 'Unknown error',
      );
    } catch (e) {
      if (e is HttpFailure) rethrow;
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'server_error',
        message: 'Server error: ${response.statusCode}',
      );
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/common/errors/http_failure.dart';
import '../../../../core/constants.dart';
import '../../../../core/realtime/presentation/providers/dependency_injection.dart';
import '../../data/datasources/secure_storage_auth_token_reader.dart';
import '../../domain/entities/booking_ui_block.dart';
import '../../domain/ports/auth_token_reader.dart';
import 'dependency_injection.dart';

part 'booking_action_executor.g.dart';

/// Dispatches a server-emitted [BookingUiAction] over HTTP.
///
/// Endpoint strings come from `orchestrator_ui.py` and start with
/// `/bookings/...` — we concatenate `${AppConstants.baseUrl}${endpoint}`
/// to produce the full URL. The server is the source of truth for the
/// path; the frontend never constructs orchestrator URLs.
///
/// `body` is optional. The action button widget classifies actions by
/// endpoint suffix (see `BookingOrchestratorActionButton._classify`)
/// and provides a body for the cash-collection flow (auto-built from
/// `booking.pricing.finalCashToCollect`) and the customer-cancel flow
/// (default reason). Sessions 5/6 will replace those minimal bodies
/// with rich sheets.
///
/// **Storage abstraction (CLAUDE.md):** the executor depends on
/// [IAuthTokenReader], not on `flutter_secure_storage` directly. The
/// token-key literal and the storage-package types live behind the
/// interface so changing the storage backend (e.g. a hardware-backed
/// keystore on Android) doesn't touch this file.
class BookingActionExecutor {
  final http.Client _client;
  final IAuthTokenReader _authTokenReader;

  BookingActionExecutor(this._client, this._authTokenReader);

  /// Throws [HttpFailure] on non-2xx; SocketException bubbles to the
  /// button widget which surfaces a "no connection" snackbar.
  Future<void> execute(
    BookingUiAction action, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _authTokenReader.read();
    final uri = Uri.parse('${AppConstants.baseUrl}${action.endpoint}');
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Token $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    final method = action.method.toUpperCase();

    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: encodedBody),
      'PATCH' => await _client.patch(uri, headers: headers, body: encodedBody),
      'PUT' => await _client.put(uri, headers: headers, body: encodedBody),
      // DELETE: deliberately omit body. RFC 7231 leaves DELETE bodies
      // unspecified and a non-trivial fraction of proxies / servers
      // reject or silently strip them; the orchestrator surface has no
      // body-bearing DELETEs today and the safer default is to drop it.
      'DELETE' => await _client.delete(uri, headers: headers),
      _ => throw StateError('Unsupported HTTP method: ${action.method}'),
    };
    _ensureOk(response);
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    // Audit S-14 (Batch B): defensive parse via HttpFailure.fromEnvelope
    // — coerces non-string code/message and tolerates non-JSON bodies.
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    throw HttpFailure.fromEnvelope(
      statusCode: response.statusCode,
      body: decoded,
      fallbackMessage: 'Action failed (${response.statusCode}).',
    );
  }
}

@Riverpod(keepAlive: true)
IAuthTokenReader orchestratorAuthTokenReader(Ref ref) =>
    SecureStorageAuthTokenReader(ref.watch(orchestratorSecureStorageProvider));

@Riverpod(keepAlive: true)
BookingActionExecutor bookingActionExecutor(Ref ref) => BookingActionExecutor(
  ref.watch(eventHttpClientProvider),
  ref.watch(orchestratorAuthTokenReaderProvider),
);

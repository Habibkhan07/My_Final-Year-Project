// SharedPreferences-backed local cache for the chatbot feature.
//
// **Two purposes only:**
//
//   * Tier-2 (UX cache): per-conversation free-text draft. Lets a
//     user who backgrounds the app mid-typing return to their
//     half-written sentence. PAYOUT phase opts out at the repository
//     level (IBAN is PII; see `FormDirective.persistDraft`).
//
//   * Tier-3 (session recovery): the id of the currently-active
//     conversation, so the next cold boot can rehydrate the user
//     into the chatbot screen if they had one open.
//
// **What this is NOT.** This is not an offline-first cache. The
// chatbot requires a server round-trip on every turn — there is no
// local fallback that would let the user advance the state machine
// without network. The repository surfaces `SocketException` as
// [ChatbotNetworkFailure] regardless of what's cached here.
//
// **Why SharedPreferences and not sqflite.** Draft text is a single
// string per conversation; the recovery key is a single int. Adding
// a sqlite dependency for two scalar reads/writes would just be more
// surface area.
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

abstract class IChatbotLocalDataSource {
  /// Persist [text] as the draft for [conversationId]. Pass `null` to
  /// clear an existing draft (called on successful turn-send so the
  /// next session start doesn't show stale content).
  Future<void> saveDraftText({
    required int conversationId,
    required String? text,
  });

  /// Read the draft text for [conversationId], or `null` if none was
  /// stored. Never throws — returns `null` on any decode error.
  Future<String?> loadDraftText(int conversationId);

  /// Mark [conversationId] as the active recovery target for the
  /// specific [bookingId]. Per-booking keying prevents the cross-
  /// booking leak where a still-open dispute on booking A would be
  /// rehydrated when the user opened the dispute help on booking B.
  /// Passing a `null` [conversationId] clears the marker (on close /
  /// explicit abandon).
  Future<void> setActiveConversationId({
    required int bookingId,
    required int? conversationId,
  });

  /// The recovery target conversation id for [bookingId], or `null`
  /// when none is set.
  Future<int?> getActiveConversationId(int bookingId);

  /// Drop every chatbot-related key. Used on logout / account switch
  /// (the feature's `dependency_injection.dart` does not yet wire a
  /// logout hook — flagged for the auth feature to add once it ships
  /// a "clear feature caches" signal).
  Future<void> clear();
}

class ChatbotLocalDataSource implements IChatbotLocalDataSource {
  final SharedPreferences _prefs;

  static const _logName = 'features.customer.chatbot.local_data_source';

  /// Bump on schema change. Bumped from v1 → v2 when the recovery key
  /// became per-booking (was a single global int, which leaked across
  /// bookings — see plan §C). Old v1 keys are silently ignored.
  static const _versionSuffix = '_v2';

  /// Recovery-target prefix; the booking id is appended for the full
  /// key (`CHATBOT_ACTIVE_CONVERSATION_ID_v2:42` for booking 42). The
  /// dispute persona enforces "one open conversation per (user,
  /// booking)" server-side, so per-booking keying is sufficient.
  static const _activeConversationPrefix =
      'CHATBOT_ACTIVE_CONVERSATION_ID$_versionSuffix:';

  /// Prefix; the conversation id is appended for the full key. Per-id
  /// keys keep drafts isolated when (rare) a user has multiple
  /// sessions in their history.
  static const _draftPrefix = 'CHATBOT_DRAFT_TEXT$_versionSuffix:';

  ChatbotLocalDataSource(this._prefs);

  // ─── Drafts ────────────────────────────────────────────────────────────

  @override
  Future<void> saveDraftText({
    required int conversationId,
    required String? text,
  }) async {
    final key = '$_draftPrefix$conversationId';
    try {
      if (text == null || text.isEmpty) {
        await _prefs.remove(key);
        return;
      }
      await _prefs.setString(key, text);
    } catch (e, st) {
      // A draft-save failure must never bubble to the caller — the
      // notifier's `saveDraftText` is fire-and-forget from the
      // composer's text-change listener. Log and swallow.
      log(
        'failed to persist draft for conv=$conversationId',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<String?> loadDraftText(int conversationId) async {
    final key = '$_draftPrefix$conversationId';
    try {
      return _prefs.getString(key);
    } catch (e, st) {
      log(
        'failed to load draft for conv=$conversationId',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // ─── Recovery target ───────────────────────────────────────────────────

  @override
  Future<void> setActiveConversationId({
    required int bookingId,
    required int? conversationId,
  }) async {
    final key = '$_activeConversationPrefix$bookingId';
    try {
      if (conversationId == null) {
        await _prefs.remove(key);
        return;
      }
      await _prefs.setInt(key, conversationId);
    } catch (e, st) {
      log(
        'failed to set active conversation id for booking=$bookingId',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<int?> getActiveConversationId(int bookingId) async {
    final key = '$_activeConversationPrefix$bookingId';
    try {
      return _prefs.getInt(key);
    } catch (e, st) {
      log(
        'failed to read active conversation id for booking=$bookingId',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // ─── Wholesale clear ───────────────────────────────────────────────────

  @override
  Future<void> clear() async {
    try {
      final keys = _prefs.getKeys();
      for (final k in keys) {
        if (k.startsWith(_activeConversationPrefix) ||
            k.startsWith(_draftPrefix)) {
          await _prefs.remove(k);
        }
      }
    } catch (e, st) {
      log('failed to clear', name: _logName, error: e, stackTrace: st);
    }
  }
}

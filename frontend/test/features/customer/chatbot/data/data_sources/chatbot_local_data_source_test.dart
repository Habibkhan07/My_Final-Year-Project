// SharedPreferences-backed tests for ChatbotLocalDataSource.
//
// Covers:
//   * Draft set/get/clear contract — empty string is treated as "clear".
//   * Per-booking recovery id set/get/clear contract (was a single
//     global int; now per-booking — see plan §C).
//   * Per-conversation draft keying (two conversations don't share state).
//   * Per-booking recovery isolation: one booking's recovery id does
//     not bleed into another booking.
//   * `clear()` removes only chatbot-prefixed keys, leaves unrelated
//     SharedPreferences entries alone.
//
// SharedPreferences itself is a wrapper around platform storage; in
// tests we use `setMockInitialValues({})` + `getInstance()` to get the
// in-memory fake. There's no value in mocking the SharedPreferences
// class directly — that would test the mock, not the data source.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/data/data_sources/chatbot_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _draftKey = 'CHATBOT_DRAFT_TEXT_v2:';
const _activePrefix = 'CHATBOT_ACTIVE_CONVERSATION_ID_v2:';

Future<ChatbotLocalDataSource> _build([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ChatbotLocalDataSource(prefs);
}

void main() {
  // ─── Drafts ─────────────────────────────────────────────────────────

  group('saveDraftText / loadDraftText', () {
    test('saves non-null text under per-conversation key', () async {
      final ds = await _build();
      await ds.saveDraftText(conversationId: 42, text: 'half-written sentence');
      final read = await ds.loadDraftText(42);
      expect(read, 'half-written sentence');
    });

    test('passing null clears the key', () async {
      final ds = await _build({'${_draftKey}42': 'stale'});
      await ds.saveDraftText(conversationId: 42, text: null);
      expect(await ds.loadDraftText(42), isNull);
    });

    test('passing empty string clears the key', () async {
      final ds = await _build({'${_draftKey}42': 'stale'});
      await ds.saveDraftText(conversationId: 42, text: '');
      expect(await ds.loadDraftText(42), isNull);
    });

    test('loadDraftText returns null when no key stored', () async {
      final ds = await _build();
      expect(await ds.loadDraftText(99), isNull);
    });

    test('per-conversation isolation: 1 and 2 do not share state', () async {
      final ds = await _build();
      await ds.saveDraftText(conversationId: 1, text: 'one');
      await ds.saveDraftText(conversationId: 2, text: 'two');
      expect(await ds.loadDraftText(1), 'one');
      expect(await ds.loadDraftText(2), 'two');
    });
  });

  // ─── Recovery id (per-booking) ──────────────────────────────────────

  group('setActiveConversationId / getActiveConversationId', () {
    test('stores int per booking and reads it back', () async {
      final ds = await _build();
      await ds.setActiveConversationId(bookingId: 9001, conversationId: 7001);
      expect(await ds.getActiveConversationId(9001), 7001);
    });

    test('passing null removes the per-booking key', () async {
      final ds = await _build({'${_activePrefix}9001': 7001});
      await ds.setActiveConversationId(bookingId: 9001, conversationId: null);
      expect(await ds.getActiveConversationId(9001), isNull);
    });

    test('returns null when nothing set for that booking', () async {
      final ds = await _build();
      expect(await ds.getActiveConversationId(9001), isNull);
    });

    test(
      'per-booking isolation: booking A recovery does not leak into booking B',
      () async {
        // The whole point of the v2 keying — pre-fix, a still-open
        // dispute on booking A would be rehydrated when the user
        // opened the dispute help on booking B (cross-booking leak).
        final ds = await _build();
        await ds.setActiveConversationId(bookingId: 308, conversationId: 12);
        expect(await ds.getActiveConversationId(309), isNull);
        expect(await ds.getActiveConversationId(308), 12);
      },
    );
  });

  // ─── Wholesale clear ────────────────────────────────────────────────

  group('clear()', () {
    test(
      'removes every per-booking recovery key + every draft key',
      () async {
        final ds = await _build({
          '${_activePrefix}9001': 7001,
          '${_activePrefix}9002': 7002,
          '${_draftKey}1': 'a',
          '${_draftKey}2': 'b',
        });
        await ds.clear();
        expect(await ds.getActiveConversationId(9001), isNull);
        expect(await ds.getActiveConversationId(9002), isNull);
        expect(await ds.loadDraftText(1), isNull);
        expect(await ds.loadDraftText(2), isNull);
      },
    );

    test('does not remove unrelated SharedPreferences keys', () async {
      // Simulate another feature's key sharing the prefs space — clear()
      // must scope its removal to the chatbot prefix only.
      SharedPreferences.setMockInitialValues({
        '${_activePrefix}42': 1,
        '${_draftKey}42': 'draft',
        'unrelated.feature.key': 'survive',
      });
      final prefs = await SharedPreferences.getInstance();
      final ds = ChatbotLocalDataSource(prefs);

      await ds.clear();

      expect(prefs.getString('unrelated.feature.key'), 'survive');
      expect(prefs.containsKey('${_activePrefix}42'), isFalse);
      expect(prefs.containsKey('${_draftKey}42'), isFalse);
    });
  });
}

// Public-safe snapshot of the persona's internal state, as served by
// `_state_summary` in `backend/chatbot/views.py`. Excludes any
// persona-internal counters or LLM forced-advance reasons.
//
// Wire spec: `backend/chatbot/api/CHATBOT_API.md` §`state_summary`.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_phase.dart';

part 'state_summary.freezed.dart';

/// What the UI is allowed to know about the conversation's runtime
/// state. The screen does not render this directly today; it is
/// persisted on the session entity so a future debug panel or "explain
/// this dispute" screen can surface what fields were captured before
/// the close.
///
/// [capturedFields] is an opaque map from the server. Specifically for
/// the dispute persona it currently carries `issue_summary`,
/// `bank_name`, `account_title`, `iban` once those are captured —
/// **note that IBAN is included server-side because the same map
/// is the admin's view**. The client treats this as opaque debug data
/// and never re-renders the IBAN.
@freezed
abstract class StateSummary with _$StateSummary {
  const factory StateSummary({
    required ChatPhase phase,
    required int attachmentsCount,
    @Default({}) Map<String, dynamic> capturedFields,
  }) = _StateSummary;
}

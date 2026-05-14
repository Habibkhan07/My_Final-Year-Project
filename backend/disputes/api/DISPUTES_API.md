# DISPUTES_API.md — Disputes Domain (admin-facing)

> The `disputes` Django app holds bank-payout intents for refund-eligible disputes. The dispute *ticket* itself is `bookings.SupportTicket` — this app exists for the PII boundary around `RefundIntent`.

The customer-facing chatbot that *produces* tickets and refund intents is documented in [`chatbot/api/CHATBOT_API.md`](../../chatbot/api/CHATBOT_API.md).

---

## Models

### `RefundIntent` (`disputes/models.py`)

| Field | Type | Notes |
|---|---|---|
| `ticket` | OneToOne → `bookings.SupportTicket` | CASCADE on ticket delete (rare in practice) |
| `bank_name` | CharField(64) | e.g. "HBL", "Meezan" |
| `account_title` | CharField(128) | Full name as on the bank account |
| `iban` | CharField(34) | Pakistani format: `PK36HABB...` |
| `created_at` | DateTime | Auto |

Created by `disputes.services.ticket_creation.create_from_chatbot_session` when the chatbot dispute persona reaches the PAYOUT phase. **Never** created from admin — there is no add permission.

`__str__` deliberately returns `<RefundIntent for ticket #N>` (no bank fields) — admin list views and Sentry breadcrumbs use `__str__`, and a chatty repr would leak PII into observability tooling.

---

## Admin permissions

### The `finance_admin` group

Created by `disputes/migrations/0002_finance_admin_group.py` (data migration). Grants:

| Permission | Granted? | Why |
|---|---|---|
| `bookings.view_supportticket` | ✓ | Read the dispute queue |
| `bookings.change_supportticket` | ✓ | Resolve / adjudicate |
| `disputes.view_refundintent` | ✓ | Read bank details for out-of-band payout |
| `disputes.add_refundintent` | ✗ | Service-created only |
| `disputes.change_refundintent` | ✗ | Write-once (customer re-files for typo correction) |
| `disputes.delete_refundintent` | ✗ | Audit retention |

To add a staff user to this group:
1. Django admin → Authentication and Authorization → Users → select user → set `is_staff=True`.
2. Same user page → Groups → add `finance_admin` → Save.

### Visibility rules (enforced in `disputes/admin.py`)

`RefundIntentAdmin` overrides `has_module_permission` and `has_view_permission` to require `finance_admin` group membership (or superuser). Staff outside the group will not see "Refund intents" appear in the admin index at all.

`has_add_permission`, `has_change_permission`, `has_delete_permission` all return `False` **unconditionally** — even superusers cannot create or edit rows from admin. Rows are produced exclusively by `disputes.services.ticket_creation`.

---

## Admin workflow

**Triage queue**
1. Admin user (staff, finance_admin group) logs into Django admin.
2. Navigates to `Bookings → Support tickets`.
3. List view filtered by `status=OPEN` shows pending disputes; `dispute_intake_method` column distinguishes `CHATBOT` (chat-driven) from `FORM` (form-driven).
4. Click a ticket → detail page shows:
   - `initial_reason` (raw narrative)
   - `chat_log` JSON (ai_summary, captured_fields, transcript, attachments, needs_review)
   - Linked refund intent (if any) — `view_refundintent` permission required to see the FK link.

**`needs_review` filter**
- Tickets with `chat_log.needs_review=true` need a closer look. The summary validation tripped (e.g. AI hallucinated content) OR the conversation force-advanced past the turn cap.
- Filter via the `Has needs review` filter (TODO: add a custom admin filter in a follow-up; for now, search by `needs_review` keyword in chat_log).

**Resolution**
- Use the existing `Resolve` link in `SupportTicketAdmin` (lives in `bookings/admin.py`) — opens the resolution form that POSTs to `bookings.services.orchestrator.admin_resolve_dispute`.
- Pick an `outcome`: `REFUND_CUSTOMER`, `PENALIZE_TECH`, `DISMISS`.
- If `REFUND_CUSTOMER` is chosen: navigate to the linked `RefundIntent`, copy the IBAN, issue the payout via out-of-band banking (the platform does not have a programmatic payout integration in v1).

---

## SQL: querying chat_log JSON

`chat_log` is a JSONField on `bookings.SupportTicket`. Useful queries:

```python
# All AI-flagged tickets
SupportTicket.objects.filter(
    dispute_intake_method='CHATBOT',
    chat_log__needs_review=True,
)

# Conversations that aborted before filing
# (these don't produce tickets, so query Conversation directly)
Conversation.objects.filter(
    persona_key='dispute',
    is_closed=True,
    state__aborted_reason='insufficient_info_after_cap',
)

# All tickets filed from chatbot today
from django.utils import timezone
SupportTicket.objects.filter(
    dispute_intake_method='CHATBOT',
    opened_at__date=timezone.localdate(),
)
```

---

## PII handling

| Surface | What it contains | Who sees it |
|---|---|---|
| `SupportTicket.initial_reason` | Customer's raw narrative (free text) | Anyone with `view_supportticket` |
| `SupportTicket.chat_log` | Transcript + AI summary + captured fields | Same as above |
| `RefundIntent.iban` | Bank account number | **Only** `finance_admin` group |
| `RefundIntent.account_title` | Customer's full name | **Only** `finance_admin` group |
| Sentry / app logs | Never — `CHATBOT_SCRUB_FIELDS` setting removes these from request bodies before logging |

The chatbot service writes the raw narrative AND the AI summary AND the field dict to `chat_log`. Admin uses the raw narrative as the source of truth; `ai_summary` is a convenience that may be `needs_review`-flagged.

---

## Related docs

- `chatbot/api/CHATBOT_API.md` — customer-facing chatbot framework + dispute persona behavior
- `bookings/models.py` — `SupportTicket` schema (the actual ticket model)
- `bookings/services/orchestrator.py` — `admin_resolve_dispute` (resolution workflow)

"""Per-user, per-day LLM call quota — shared across all chatbot personas.

The quota is a soft guard against (a) free-tier project-level exhaustion
when one user runs away with a broken client and (b) deliberate abuse
(scripts pummeling the chat endpoints). It is NOT a billing meter — that
lives elsewhere in finance.

Why a single shared budget across personas: in v1 only the dispute bot
ships and it makes ~3 LLM calls per session. At 50/day a single user can
file ~16 disputes per day, which is far beyond legitimate use. When a
general Q&A bot lands in v1.1 and becomes chatty, we can split the
budget per persona — but that's premature today.

Race-safety: ``select_for_update`` locks the per-day row before the
increment, so two parallel requests that both see ``count = 49`` can't
both increment to 50 (which would leave a 51 row). The atomic F() update
prevents the read-modify-write race in the single-process case.
"""
from __future__ import annotations

from django.conf import settings
from django.db import transaction
from django.db.models import F
from django.utils import timezone

from chatbot.models import DailyLlmCallQuota


class QuotaExceeded(Exception):
    """Raised when the user has consumed today's quota.

    Translated to ``429 llm_quota_exceeded`` by the view layer; the UI
    surfaces a friendly message and does NOT retry automatically.
    """


def consume(user) -> None:
    """Increment today's call counter for ``user``, locking the row.

    Raises ``QuotaExceeded`` (without incrementing) when the new value
    would exceed ``settings.CHATBOT_DAILY_CALL_LIMIT``.
    """
    today = timezone.localdate()
    limit = settings.CHATBOT_DAILY_CALL_LIMIT

    with transaction.atomic():
        row, _ = (
            DailyLlmCallQuota.objects
            .select_for_update()
            .get_or_create(user=user, date=today)
        )
        if row.count >= limit:
            raise QuotaExceeded()
        # F() avoids re-reading the count we just locked; one UPDATE.
        DailyLlmCallQuota.objects.filter(pk=row.pk).update(count=F("count") + 1)

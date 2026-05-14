"""Tests for chatbot.services.quota.

Pins:
  - count increments per call within a single day
  - hitting the limit raises QuotaExceeded WITHOUT incrementing further
  - other users have independent budgets
  - settings override (CHATBOT_DAILY_CALL_LIMIT) is respected at call time
"""
from __future__ import annotations

import pytest
from django.utils import timezone

from chatbot.models import DailyLlmCallQuota
from chatbot.services.quota import QuotaExceeded, consume
from tests.factories.accounts import UserFactory


@pytest.mark.django_db
class TestConsume:
    def test_first_call_creates_row_at_one(self):
        user = UserFactory()
        consume(user)
        row = DailyLlmCallQuota.objects.get(user=user, date=timezone.localdate())
        assert row.count == 1

    def test_subsequent_calls_increment(self):
        user = UserFactory()
        consume(user)
        consume(user)
        consume(user)
        row = DailyLlmCallQuota.objects.get(user=user, date=timezone.localdate())
        assert row.count == 3

    def test_raises_when_at_limit(self, settings):
        settings.CHATBOT_DAILY_CALL_LIMIT = 3
        user = UserFactory()
        consume(user)
        consume(user)
        consume(user)
        with pytest.raises(QuotaExceeded):
            consume(user)

    def test_raises_does_not_increment(self, settings):
        # A rejected call must not bump the counter — otherwise repeated
        # rejected calls would compound and break the "exactly N allowed"
        # contract that users expect.
        settings.CHATBOT_DAILY_CALL_LIMIT = 2
        user = UserFactory()
        consume(user)
        consume(user)
        with pytest.raises(QuotaExceeded):
            consume(user)
        row = DailyLlmCallQuota.objects.get(user=user, date=timezone.localdate())
        assert row.count == 2

    def test_other_user_has_independent_budget(self):
        user_a = UserFactory()
        user_b = UserFactory()
        consume(user_a)
        consume(user_a)
        consume(user_b)
        row_a = DailyLlmCallQuota.objects.get(user=user_a, date=timezone.localdate())
        row_b = DailyLlmCallQuota.objects.get(user=user_b, date=timezone.localdate())
        assert row_a.count == 2
        assert row_b.count == 1

    def test_zero_limit_rejects_first_call(self, settings):
        settings.CHATBOT_DAILY_CALL_LIMIT = 0
        user = UserFactory()
        with pytest.raises(QuotaExceeded):
            consume(user)

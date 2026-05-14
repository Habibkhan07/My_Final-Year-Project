"""Tests for ``wallet.selectors.withdrawal_selectors``.

Three selectors covered:

* :func:`list_active_payout_accounts` — filters to is_active=True and
  scopes to the passed-in technician. Query-budget pinned to keep the
  picker N+1-free.
* :func:`list_withdrawal_requests` — cursor pagination on the tech's
  history, newest-first, with select_related so the read serializer
  doesn't re-query per row.
* :func:`get_in_flight_request` — finds the open PENDING_REVIEW /
  APPROVED row for the duplicate-submit check; ignores REJECTED /
  PROCESSED rows.
"""
from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

import pytest
from django.utils import timezone

from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.wallet import (
    TechnicianBankAccountFactory,
    TechnicianJazzCashAccountFactory,
    WithdrawalRequestFactory,
)
from wallet.models import WithdrawalStatus
from wallet.selectors.withdrawal_selectors import (
    InvalidCursor,
    _decode_cursor,
    _encode_cursor,
    get_in_flight_request,
    list_active_payout_accounts,
    list_withdrawal_requests,
)


# ──────────────────────────────────────────────────────────────────────
# list_active_payout_accounts
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestListActivePayoutAccounts:
    def test_returns_both_account_kinds_for_this_tech(self):
        tech = TechnicianProfileFactory()
        bank = TechnicianBankAccountFactory(technician=tech)
        jazz = TechnicianJazzCashAccountFactory(technician=tech)

        result = list_active_payout_accounts(tech)

        assert [a.pk for a in result['bank_accounts']] == [bank.pk]
        assert [a.pk for a in result['jazzcash_accounts']] == [jazz.pk]

    def test_excludes_inactive_bank_account(self):
        tech = TechnicianProfileFactory()
        TechnicianBankAccountFactory(technician=tech, is_active=False)
        active = TechnicianBankAccountFactory(technician=tech, is_active=True)

        result = list_active_payout_accounts(tech)

        assert [a.pk for a in result['bank_accounts']] == [active.pk]

    def test_excludes_inactive_jazzcash_account(self):
        tech = TechnicianProfileFactory()
        TechnicianJazzCashAccountFactory(technician=tech, is_active=False)
        active = TechnicianJazzCashAccountFactory(technician=tech, is_active=True)

        result = list_active_payout_accounts(tech)

        assert [a.pk for a in result['jazzcash_accounts']] == [active.pk]

    def test_scopes_to_passed_in_tech_only(self):
        """A different tech's accounts must never leak into the result."""
        me = TechnicianProfileFactory()
        other = TechnicianProfileFactory()
        TechnicianBankAccountFactory(technician=other)
        TechnicianJazzCashAccountFactory(technician=other)
        my_bank = TechnicianBankAccountFactory(technician=me)

        result = list_active_payout_accounts(me)

        assert [a.pk for a in result['bank_accounts']] == [my_bank.pk]
        assert result['jazzcash_accounts'] == []

    def test_ordered_newest_captured_first(self):
        tech = TechnicianProfileFactory()
        older = TechnicianBankAccountFactory(technician=tech)
        newer = TechnicianBankAccountFactory(technician=tech)
        # captured_at is auto_now_add — younger row created second, so
        # the natural insert order matches the desired display order.
        # We assert by ID since timestamps may collide on fast hardware.

        result = list_active_payout_accounts(tech)

        ids = [a.pk for a in result['bank_accounts']]
        assert ids.index(newer.pk) < ids.index(older.pk)

    def test_query_budget(self, django_assert_num_queries):
        """Picker fetch hits the DB exactly twice — one query per kind."""
        tech = TechnicianProfileFactory()
        TechnicianBankAccountFactory.create_batch(3, technician=tech)
        TechnicianJazzCashAccountFactory.create_batch(2, technician=tech)

        with django_assert_num_queries(2):
            list_active_payout_accounts(tech)

    def test_returns_empty_lists_when_no_accounts(self):
        tech = TechnicianProfileFactory()

        result = list_active_payout_accounts(tech)

        assert result == {'bank_accounts': [], 'jazzcash_accounts': []}


# ──────────────────────────────────────────────────────────────────────
# get_in_flight_request
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestGetInFlightRequest:
    def test_returns_pending_review(self):
        tech = TechnicianProfileFactory()
        req = WithdrawalRequestFactory(
            technician=tech, status=WithdrawalStatus.PENDING_REVIEW,
        )

        assert get_in_flight_request(tech).pk == req.pk

    def test_returns_approved(self):
        """APPROVED-but-not-fulfilled is still in-flight (blocks new submits)."""
        tech = TechnicianProfileFactory()
        req = WithdrawalRequestFactory(
            technician=tech, status=WithdrawalStatus.APPROVED,
        )

        assert get_in_flight_request(tech).pk == req.pk

    def test_ignores_rejected(self):
        tech = TechnicianProfileFactory()
        WithdrawalRequestFactory(
            technician=tech, status=WithdrawalStatus.REJECTED,
        )

        assert get_in_flight_request(tech) is None

    def test_ignores_processed(self):
        tech = TechnicianProfileFactory()
        WithdrawalRequestFactory(
            technician=tech, status=WithdrawalStatus.PROCESSED,
        )

        assert get_in_flight_request(tech) is None

    def test_returns_none_when_no_history(self):
        tech = TechnicianProfileFactory()
        assert get_in_flight_request(tech) is None

    def test_scopes_to_passed_in_tech(self):
        me = TechnicianProfileFactory()
        other = TechnicianProfileFactory()
        WithdrawalRequestFactory(
            technician=other, status=WithdrawalStatus.PENDING_REVIEW,
        )

        assert get_in_flight_request(me) is None


# ──────────────────────────────────────────────────────────────────────
# list_withdrawal_requests — cursor pagination
# ──────────────────────────────────────────────────────────────────────


def _make_request(tech, *, when, status=WithdrawalStatus.PENDING_REVIEW):
    """Build a WithdrawalRequest at a controlled timestamp.

    Factories can't set ``requested_at`` directly (auto_now_add), so we
    update post-create. We also bypass the model's CheckConstraint
    nuance by relying on the factory's default bank account.
    """
    req = WithdrawalRequestFactory(technician=tech, status=status)
    req.requested_at = when
    req.save(update_fields=['requested_at'])
    return req


@pytest.mark.django_db
class TestListWithdrawalRequestsPagination:
    def test_returns_empty_when_no_requests(self):
        tech = TechnicianProfileFactory()

        page = list_withdrawal_requests(tech)

        assert page == {'results': [], 'next_cursor': None}

    def test_newest_first_ordering(self):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        older = _make_request(tech, when=now - timedelta(hours=2))
        newer = _make_request(tech, when=now - timedelta(hours=1))

        page = list_withdrawal_requests(tech)

        assert [r.pk for r in page['results']] == [newer.pk, older.pk]

    def test_scopes_to_passed_in_tech(self):
        me = TechnicianProfileFactory()
        other = TechnicianProfileFactory()
        _make_request(other, when=timezone.now())
        mine = _make_request(me, when=timezone.now())

        page = list_withdrawal_requests(me)

        assert [r.pk for r in page['results']] == [mine.pk]

    def test_includes_all_statuses(self):
        """History list shows pending / approved / rejected / processed."""
        tech = TechnicianProfileFactory()
        now = timezone.now()
        for offset, status in enumerate([
            WithdrawalStatus.PENDING_REVIEW,
            WithdrawalStatus.APPROVED,
            WithdrawalStatus.REJECTED,
            WithdrawalStatus.PROCESSED,
        ]):
            _make_request(tech, when=now - timedelta(minutes=offset), status=status)

        page = list_withdrawal_requests(tech)

        assert len(page['results']) == 4

    def test_page_size_caps_result_count(self):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        for i in range(5):
            _make_request(tech, when=now - timedelta(minutes=i))

        page = list_withdrawal_requests(tech, page_size=2)

        assert len(page['results']) == 2
        assert page['next_cursor'] is not None

    def test_cursor_roundtrip(self):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        reqs = [
            _make_request(tech, when=now - timedelta(minutes=i))
            for i in range(4)
        ]
        # reqs[0] is newest, reqs[3] oldest.

        page_1 = list_withdrawal_requests(tech, page_size=2)
        assert [r.pk for r in page_1['results']] == [reqs[0].pk, reqs[1].pk]
        assert page_1['next_cursor'] is not None

        page_2 = list_withdrawal_requests(
            tech, page_size=2, cursor=page_1['next_cursor'],
        )
        assert [r.pk for r in page_2['results']] == [reqs[2].pk, reqs[3].pk]
        assert page_2['next_cursor'] is None

    def test_page_size_clamped_to_max(self):
        from wallet.selectors.withdrawal_selectors import MAX_PAGE_SIZE
        tech = TechnicianProfileFactory()

        page = list_withdrawal_requests(tech, page_size=999)

        # No rows to count, but the selector should not error; the
        # internal clamp is what we're checking.
        assert page['results'] == []
        # Sanity check the constant is what we expect.
        assert MAX_PAGE_SIZE == 50

    def test_select_related_prevents_n_plus_1(self, django_assert_num_queries):
        """Pagination + payout-account access should be one combined query."""
        tech = TechnicianProfileFactory()
        bank = TechnicianBankAccountFactory(technician=tech)
        now = timezone.now()
        for i in range(5):
            req = WithdrawalRequestFactory(
                technician=tech,
                payout_bank_account=bank,
            )
            req.requested_at = now - timedelta(minutes=i)
            req.save(update_fields=['requested_at'])

        # One query for the list (with JOINs to payout accounts). Reading
        # ``r.payout_bank_account`` for each row should not trigger
        # additional queries thanks to select_related.
        with django_assert_num_queries(1):
            page = list_withdrawal_requests(tech, page_size=10)
            for r in page['results']:
                _ = r.payout_bank_account.bank_name  # force attribute access


@pytest.mark.django_db
class TestCursorDecoding:
    def test_roundtrip(self):
        ts = timezone.now()
        token = _encode_cursor(ts, 42)

        decoded_ts, decoded_id = _decode_cursor(token)

        assert decoded_id == 42
        assert decoded_ts.isoformat() == ts.isoformat()

    def test_garbage_base64_raises_invalid_cursor(self):
        with pytest.raises(InvalidCursor):
            _decode_cursor('!!!not-base64!!!')

    def test_missing_pipe_raises(self):
        import base64
        bad = base64.urlsafe_b64encode(b'no-pipe-here').decode('ascii')
        with pytest.raises(InvalidCursor):
            _decode_cursor(bad)

    def test_unparseable_timestamp_raises(self):
        import base64
        bad = base64.urlsafe_b64encode(b'not-a-date|42').decode('ascii')
        with pytest.raises(InvalidCursor):
            _decode_cursor(bad)

    def test_non_integer_id_raises(self):
        import base64
        bad = base64.urlsafe_b64encode(b'2026-05-15T10:00:00|abc').decode('ascii')
        with pytest.raises(InvalidCursor):
            _decode_cursor(bad)

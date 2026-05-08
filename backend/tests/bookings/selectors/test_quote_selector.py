"""Read-side tests for ``bookings.selectors.quote_selector``.

Every accessor enforces the no-N+1 rule via ``django_assert_num_queries``.
The exact query count is asserted in a tight band: too tight and the test
breaks on benign fk-eager-load tweaks; too loose and a regression slips
through. Pinned to current behavior with a comment explaining the breakdown.
"""

from decimal import Decimal

import pytest

from bookings.models import Quote
from bookings.selectors.quote_selector import (
    get_active_quote,
    list_booking_items,
    list_quote_history,
)
from tests.factories.bookings import (
    BookingItemFactory,
    JobBookingInProgressFactory,
    JobBookingInspectingFactory,
    JobBookingQuotedFactory,
    QuoteFactory,
    QuoteLineItemFactory,
)
from tests.factories.catalog import LaborSubServiceFactory


pytestmark = pytest.mark.django_db


class TestGetActiveQuote:
    def test_returns_most_recent_submitted(self):
        booking = JobBookingQuotedFactory()
        QuoteFactory(booking=booking, revision_number=1, status=Quote.STATUS_SUPERSEDED)
        active = QuoteFactory(booking=booking, revision_number=2, status=Quote.STATUS_SUBMITTED)
        result = get_active_quote(booking)
        assert result == active

    def test_falls_back_to_most_recent_when_no_submitted(self):
        booking = JobBookingInProgressFactory()
        QuoteFactory(booking=booking, revision_number=1, status=Quote.STATUS_DECLINED)
        approved = QuoteFactory(booking=booking, revision_number=2, status=Quote.STATUS_APPROVED)
        result = get_active_quote(booking)
        assert result == approved

    def test_returns_none_when_no_quotes(self):
        booking = JobBookingInspectingFactory()
        assert get_active_quote(booking) is None

    def test_no_n_plus_one_on_line_items(self, django_assert_num_queries):
        # 1 query: SELECT submitted quotes (returns the one).
        # 1 query: prefetch line_items.
        # 1 query: prefetch line_items__sub_service.
        booking = JobBookingQuotedFactory()
        quote = QuoteFactory(booking=booking, revision_number=1, status=Quote.STATUS_SUBMITTED)
        sub = LaborSubServiceFactory()
        for _ in range(3):
            QuoteLineItemFactory(quote=quote, sub_service=sub)
        with django_assert_num_queries(3):
            q = get_active_quote(booking)
            assert q is not None
            for li in q.line_items.all():
                _ = li.sub_service.name


class TestListQuoteHistory:
    def test_orders_oldest_first(self):
        booking = JobBookingInProgressFactory()
        QuoteFactory(booking=booking, revision_number=2, status=Quote.STATUS_APPROVED)
        QuoteFactory(booking=booking, revision_number=1, status=Quote.STATUS_SUPERSEDED)
        history = list_quote_history(booking)
        assert [q.revision_number for q in history] == [1, 2]

    def test_empty_for_no_quotes(self):
        booking = JobBookingInspectingFactory()
        assert list_quote_history(booking) == []


class TestListBookingItems:
    def test_orders_by_id(self):
        booking = JobBookingInProgressFactory()
        a = BookingItemFactory(booking=booking, price_charged=Decimal('500.00'))
        b = BookingItemFactory(booking=booking, price_charged=Decimal('700.00'))
        items = list_booking_items(booking)
        assert [i.id for i in items] == [a.id, b.id]

    def test_no_n_plus_one_on_sub_service_and_quote(self, django_assert_num_queries):
        booking = JobBookingInProgressFactory()
        quote = QuoteFactory(booking=booking, revision_number=1, status=Quote.STATUS_APPROVED)
        for _ in range(4):
            BookingItemFactory(booking=booking, sourced_quote=quote)
        # Single query thanks to select_related — sub_service and
        # sourced_quote ride along on the items SELECT.
        with django_assert_num_queries(1):
            items = list_booking_items(booking)
            for it in items:
                _ = it.sub_service.name
                _ = it.sourced_quote.revision_number

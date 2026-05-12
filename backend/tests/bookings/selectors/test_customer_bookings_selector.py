"""
Tests for ``bookings.selectors.customer_bookings_selector``.

Covers exhaustively:

  * Cursor encode/decode (round-trip + malformed token paths).
  * ``_resolve_ui_block`` — every status row, REJECTED variants by
    EventLog reason, fallback when no EventLog row.
  * ``list_customer_bookings`` —
    - segments (upcoming + past)
    - explicit status_filter override
    - pagination (single page, multi-page boundary, exact-fit page)
    - cursor seek predicate (asc and desc directions)
    - since filter
    - IDOR scope (user A's queryset never returns user B's rows)
    - select_related performance contract via ``django_assert_num_queries``
    - REJECTED reason dispatch (technician_declined / sla_timeout / missing)
    - aged-out CONFIRMED rows surface in past, not upcoming
    - server_time present and tz-aware
    - empty result
  * ``count_customer_bookings`` — empty, mixed, IDOR.
"""
from __future__ import annotations

import datetime
from decimal import Decimal

import pytest
from django.db import connection
from django.utils import timezone

from bookings.models import JobBooking
from bookings.selectors.customer_bookings_selector import (
    CursorDecodeError,
    SEGMENT_PAST,
    SEGMENT_UPCOMING,
    TONE_NEGATIVE,
    TONE_NEUTRAL,
    TONE_POSITIVE,
    TONE_WARNING,
    _decode_cursor,
    _encode_cursor,
    _resolve_ui_block,
    count_customer_bookings,
    list_customer_bookings,
)
from realtime.constants.event_types import EventType
from realtime.models.events import EventLog
from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingFactory
from tests.factories.customers import CustomerAddressFactory, CustomerProfileFactory


pytestmark = pytest.mark.django_db


# =====================================================================
# Helpers
# =====================================================================


def _booking_in_future(*, customer, **kwargs) -> JobBooking:
    """Default-build: scheduled_start tomorrow, scheduled_end +1h."""
    start = timezone.now() + datetime.timedelta(days=1)
    end = start + datetime.timedelta(hours=1)
    return JobBookingFactory(
        customer=customer,
        scheduled_start=start,
        scheduled_end=end,
        **kwargs,
    )


def _booking_in_past(*, customer, **kwargs) -> JobBooking:
    """scheduled window already over."""
    end = timezone.now() - datetime.timedelta(hours=1)
    start = end - datetime.timedelta(hours=1)
    return JobBookingFactory(
        customer=customer,
        scheduled_start=start,
        scheduled_end=end,
        **kwargs,
    )


def _make_rejection_log(*, user, job_id: int, reason: str) -> EventLog:
    return EventLog.objects.create(
        user=user,
        event_type=EventType.BOOKING_REJECTED.value,
        target_role=EventLog.TARGET_CUSTOMER,
        payload={"job_id": job_id, "reason": reason},
        is_critical=False,
    )


# =====================================================================
# Cursor encode / decode
# =====================================================================


class TestCursor:
    """Opaque base64 token that survives the wire and round-trips."""

    def test_round_trip_preserves_components(self):
        when = timezone.now()
        token = _encode_cursor(when, 99482)
        decoded_when, decoded_id = _decode_cursor(token)
        assert decoded_id == 99482
        # Microsecond fidelity is preserved through ISO-8601.
        assert abs((decoded_when - when).total_seconds()) < 1e-6

    def test_token_is_url_safe(self):
        when = timezone.now()
        token = _encode_cursor(when, 1)
        # url-safe alphabet has no '+' or '/' or '='.
        assert "+" not in token
        assert "/" not in token
        assert "=" not in token  # padding stripped

    def test_decode_garbage_string_raises(self):
        with pytest.raises(CursorDecodeError):
            _decode_cursor("not-a-real-token")

    def test_decode_empty_string_raises(self):
        with pytest.raises(CursorDecodeError):
            _decode_cursor("")

    def test_decode_valid_base64_but_wrong_shape_raises(self):
        # Valid base64 of `{"unexpected": 1}` — missing ss/id keys.
        import base64
        import json

        bad = base64.urlsafe_b64encode(
            json.dumps({"unexpected": 1}).encode()
        ).rstrip(b"=").decode()
        with pytest.raises(CursorDecodeError):
            _decode_cursor(bad)

    def test_decode_non_int_id_raises(self):
        import base64
        import json

        bad = base64.urlsafe_b64encode(
            json.dumps({"ss": "2026-01-01T00:00:00Z", "id": "not-an-int"}).encode()
        ).rstrip(b"=").decode()
        with pytest.raises(CursorDecodeError):
            _decode_cursor(bad)


# =====================================================================
# _resolve_ui_block — canonical status → ui table
# =====================================================================


class TestResolveUiBlock:
    """
    Every row of the table in CUSTOMER_BOOKINGS_API.md §1.7. Drift between
    this table and the Flutter event-patch mapper would surface as a
    flicker on event arrival, so the test asserts the literal copy and
    tone the API doc commits to.
    """

    def test_awaiting(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
            technician_display_name="Ali Khan",
            rejection_reason=None,
        )
        assert ui == {
            "badge_text": "Awaiting tech",
            "badge_tone": TONE_WARNING,
            "headline": "Waiting for Ali Khan to confirm",
        }

    def test_confirmed(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_CONFIRMED,
            technician_display_name="Ali Khan",
            rejection_reason=None,
        )
        assert ui == {
            "badge_text": "Confirmed",
            "badge_tone": TONE_POSITIVE,
            "headline": "Confirmed with Ali Khan",
        }

    def test_completed(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_COMPLETED,
            technician_display_name="Ali Khan",
            rejection_reason=None,
        )
        assert ui == {
            "badge_text": "Completed",
            "badge_tone": TONE_POSITIVE,
            "headline": "Completed by Ali Khan",
        }

    def test_cancelled_by_customer(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_CANCELLED,
            technician_display_name="Ali Khan",
            rejection_reason=None,
            cancel_reason='customer_cancelled_pre_accept',
        )
        assert ui == {
            "badge_text": "Cancelled",
            "badge_tone": TONE_NEUTRAL,
            "headline": "You cancelled this booking",
        }

    def test_cancelled_by_technician(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_CANCELLED,
            technician_display_name="Ali Khan",
            rejection_reason=None,
            cancel_reason='technician_cancelled',
        )
        assert ui == {
            "badge_text": "Cancelled",
            "badge_tone": TONE_NEUTRAL,
            "headline": "Ali Khan cancelled this booking",
        }

    def test_cancelled_by_reschedule(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_CANCELLED,
            technician_display_name="Ali Khan",
            rejection_reason=None,
            cancel_reason='customer_rescheduled',
        )
        assert ui == {
            "badge_text": "Cancelled",
            "badge_tone": TONE_NEUTRAL,
            "headline": "Rescheduled to a new booking",
        }

    def test_cancelled_unknown_reason(self):
        # Legacy rows / events that pre-date the cancel_reason field don't
        # falsely blame the customer — neutral copy instead.
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_CANCELLED,
            technician_display_name="Ali Khan",
            rejection_reason=None,
            cancel_reason=None,
        )
        assert ui == {
            "badge_text": "Cancelled",
            "badge_tone": TONE_NEUTRAL,
            "headline": "Booking was cancelled",
        }

    def test_rejected_technician_declined(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_REJECTED,
            technician_display_name="Ali Khan",
            rejection_reason="technician_declined",
        )
        assert ui == {
            "badge_text": "Unavailable",
            "badge_tone": TONE_NEGATIVE,
            "headline": "Ali Khan couldn't take this",
        }

    def test_rejected_sla_timeout(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_REJECTED,
            technician_display_name="Ali Khan",
            rejection_reason="sla_timeout",
        )
        assert ui == {
            "badge_text": "Timed out",
            "badge_tone": TONE_NEGATIVE,
            "headline": "Ali Khan didn't respond in time",
        }

    def test_rejected_unknown_reason_falls_back_to_declined_copy(self):
        # Forward-compat: unrecognized reason should not crash; the
        # safer-default copy ("couldn't take") wins.
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_REJECTED,
            technician_display_name="Ali Khan",
            rejection_reason="some_future_reason",
        )
        assert ui["badge_text"] == "Unavailable"
        assert ui["badge_tone"] == TONE_NEGATIVE

    def test_rejected_with_no_reason_falls_back(self):
        # Legacy bookings predating EventLog get None — must not crash.
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_REJECTED,
            technician_display_name="Ali Khan",
            rejection_reason=None,
        )
        assert ui["badge_text"] == "Unavailable"
        assert ui["badge_tone"] == TONE_NEGATIVE

    def test_pending_legacy(self):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_PENDING,
            technician_display_name="Ali Khan",
            rejection_reason=None,
        )
        assert ui["badge_tone"] == TONE_NEUTRAL
        assert ui["badge_text"] == "Pending"

    def test_unknown_status_falls_through_neutral(self):
        ui = _resolve_ui_block(
            status="SOMETHING_NEW_FROM_FUTURE_BACKEND",
            technician_display_name="Ali Khan",
            rejection_reason=None,
        )
        assert ui["badge_tone"] == TONE_NEUTRAL
        assert ui["headline"] == "Booking is being prepared"


# =====================================================================
# list_customer_bookings — segments + filtering + pagination + cursor
# =====================================================================


class TestListSegmentUpcoming:

    def test_includes_awaiting_in_future(self):
        user = UserFactory()
        b = _booking_in_future(
            customer=user, status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert [item["id"] for item in result.items] == [b.id]

    def test_includes_confirmed_in_future(self):
        user = UserFactory()
        b = _booking_in_future(
            customer=user, status=JobBooking.STATUS_CONFIRMED,
        )
        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert [item["id"] for item in result.items] == [b.id]

    def test_excludes_terminal_statuses(self):
        user = UserFactory()
        for status in (
            JobBooking.STATUS_REJECTED,
            JobBooking.STATUS_CANCELLED,
            JobBooking.STATUS_COMPLETED,
        ):
            _booking_in_future(customer=user, status=status)

        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert result.items == []

    def test_excludes_aged_out_confirmed(self):
        # Confirmed booking whose scheduled_end is in the past — happened
        # but no formal completion event. Belongs in past.
        user = UserFactory()
        _booking_in_past(customer=user, status=JobBooking.STATUS_CONFIRMED)

        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert result.items == []

    def test_orders_next_soonest_first(self):
        user = UserFactory()
        soon = _booking_in_future(customer=user)
        soon.scheduled_start = timezone.now() + datetime.timedelta(hours=2)
        soon.scheduled_end = soon.scheduled_start + datetime.timedelta(hours=1)
        soon.save()

        later = _booking_in_future(customer=user)
        later.scheduled_start = timezone.now() + datetime.timedelta(days=2)
        later.scheduled_end = later.scheduled_start + datetime.timedelta(hours=1)
        later.save()

        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert [item["id"] for item in result.items] == [soon.id, later.id]


class TestListSegmentPast:

    def test_includes_terminal_statuses(self):
        user = UserFactory()
        rejected = _booking_in_future(
            customer=user, status=JobBooking.STATUS_REJECTED,
        )
        cancelled = _booking_in_past(
            customer=user, status=JobBooking.STATUS_CANCELLED,
        )
        completed = _booking_in_past(
            customer=user, status=JobBooking.STATUS_COMPLETED,
        )

        result = list_customer_bookings(user=user, segment=SEGMENT_PAST)
        ids = {item["id"] for item in result.items}
        assert ids == {rejected.id, cancelled.id, completed.id}

    def test_includes_aged_out_confirmed(self):
        user = UserFactory()
        aged = _booking_in_past(customer=user, status=JobBooking.STATUS_CONFIRMED)

        result = list_customer_bookings(user=user, segment=SEGMENT_PAST)
        assert [item["id"] for item in result.items] == [aged.id]

    def test_excludes_active_upcoming(self):
        user = UserFactory()
        _booking_in_future(customer=user, status=JobBooking.STATUS_CONFIRMED)
        _booking_in_future(customer=user, status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)

        result = list_customer_bookings(user=user, segment=SEGMENT_PAST)
        assert result.items == []

    def test_orders_most_recent_first(self):
        user = UserFactory()
        # Two completed bookings with distinct scheduled_starts — latest wins.
        old = _booking_in_past(customer=user, status=JobBooking.STATUS_COMPLETED)
        old.scheduled_start = timezone.now() - datetime.timedelta(days=10)
        old.scheduled_end = old.scheduled_start + datetime.timedelta(hours=1)
        old.save()

        recent = _booking_in_past(customer=user, status=JobBooking.STATUS_COMPLETED)
        recent.scheduled_start = timezone.now() - datetime.timedelta(days=1)
        recent.scheduled_end = recent.scheduled_start + datetime.timedelta(hours=1)
        recent.save()

        result = list_customer_bookings(user=user, segment=SEGMENT_PAST)
        assert [item["id"] for item in result.items] == [recent.id, old.id]


class TestEverySegmentCoverageMatrix:
    """Locks the rule: every JobBooking status appears in exactly one
    segment for a booking whose scheduled window is in the future.

    Past regressions had bookings in COMPLETED_INSPECTION_ONLY / NO_SHOW
    / DISPUTED / EN_ROUTE / ARRIVED / INSPECTING / QUOTED / IN_PROGRESS
    falling through both segments and becoming invisible. This test
    parametrizes over every status from STATUS_CHOICES so adding a new
    status without updating the selector breaks the build loudly.
    """

    # Active-mid-job statuses live in Upcoming regardless of date.
    _ACTIVE = {
        JobBooking.STATUS_EN_ROUTE,
        JobBooking.STATUS_ARRIVED,
        JobBooking.STATUS_INSPECTING,
        JobBooking.STATUS_QUOTED,
        JobBooking.STATUS_IN_PROGRESS,
    }
    # Ageable statuses live in Upcoming when scheduled_end is in the future.
    _AGEABLE = {
        JobBooking.STATUS_PENDING,
        JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        JobBooking.STATUS_CONFIRMED,
    }
    # Terminal statuses live in Past.
    _TERMINAL = {
        JobBooking.STATUS_COMPLETED,
        JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
        JobBooking.STATUS_CANCELLED,
        JobBooking.STATUS_REJECTED,
        JobBooking.STATUS_NO_SHOW,
        JobBooking.STATUS_DISPUTED,
    }

    def test_every_status_resolves_to_exactly_one_segment(self):
        all_known = self._ACTIVE | self._AGEABLE | self._TERMINAL
        choices = {s for s, _ in JobBooking.STATUS_CHOICES}
        unaccounted = choices - all_known
        assert not unaccounted, (
            f"New booking status(es) without segment assignment: {unaccounted}. "
            "Update _ACTIVE_UPCOMING_STATUSES / _AGEABLE_UPCOMING_STATUSES / "
            "_PAST_STATUSES in customer_bookings_selector.py."
        )

        user = UserFactory()
        for status in choices:
            booking = _booking_in_future(customer=user, status=status)
            upcoming_ids = {
                item["id"]
                for item in list_customer_bookings(
                    user=user, segment=SEGMENT_UPCOMING,
                ).items
            }
            past_ids = {
                item["id"]
                for item in list_customer_bookings(
                    user=user, segment=SEGMENT_PAST,
                ).items
            }
            in_upcoming = booking.id in upcoming_ids
            in_past = booking.id in past_ids
            expected_upcoming = status in (self._ACTIVE | self._AGEABLE)
            expected_past = status in self._TERMINAL
            assert in_upcoming == expected_upcoming, (
                f"status={status!r} in_upcoming={in_upcoming} expected={expected_upcoming}"
            )
            assert in_past == expected_past, (
                f"status={status!r} in_past={in_past} expected={expected_past}"
            )
            assert in_upcoming != in_past, (
                f"status={status!r} appeared in both / neither segment"
            )
            # Clean up so the next iteration's lists are scoped.
            booking.delete()


class TestListStatusFilterOverride:

    def test_explicit_status_overrides_segment_time_window(self):
        # status_filter ignores the time-window predicate — Confirmed
        # rows in the past surface even though "upcoming" segment would
        # exclude them.
        user = UserFactory()
        b = _booking_in_past(customer=user, status=JobBooking.STATUS_CONFIRMED)

        result = list_customer_bookings(
            user=user,
            segment=SEGMENT_UPCOMING,
            status_filter=[JobBooking.STATUS_CONFIRMED],
        )
        assert [item["id"] for item in result.items] == [b.id]

    def test_multi_status_filter(self):
        user = UserFactory()
        a = _booking_in_future(
            customer=user, status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        c = _booking_in_future(
            customer=user, status=JobBooking.STATUS_CONFIRMED,
        )
        # Cancelled — should be excluded.
        _booking_in_future(customer=user, status=JobBooking.STATUS_CANCELLED)

        result = list_customer_bookings(
            user=user,
            segment=SEGMENT_UPCOMING,
            status_filter=[
                JobBooking.STATUS_AWAITING_TECH_ACCEPT,
                JobBooking.STATUS_CONFIRMED,
            ],
        )
        ids = {item["id"] for item in result.items}
        assert ids == {a.id, c.id}


class TestListPagination:

    def test_single_page_no_more(self):
        user = UserFactory()
        for _ in range(3):
            _booking_in_future(customer=user)

        result = list_customer_bookings(user=user, page_size=10)
        assert len(result.items) == 3
        assert result.has_more is False
        assert result.next_cursor is None

    def test_multi_page_boundary(self):
        # Five bookings, page_size 2 → page1=2 with cursor, page2=2 with
        # cursor, page3=1 with no cursor.
        user = UserFactory()
        bookings = []
        for i in range(5):
            b = _booking_in_future(customer=user)
            b.scheduled_start = timezone.now() + datetime.timedelta(days=i + 1)
            b.scheduled_end = b.scheduled_start + datetime.timedelta(hours=1)
            b.save()
            bookings.append(b)

        page1 = list_customer_bookings(
            user=user, segment=SEGMENT_UPCOMING, page_size=2,
        )
        assert len(page1.items) == 2
        assert page1.has_more is True
        assert page1.next_cursor is not None

        page2 = list_customer_bookings(
            user=user,
            segment=SEGMENT_UPCOMING,
            page_size=2,
            cursor=page1.next_cursor,
        )
        assert len(page2.items) == 2
        assert page2.has_more is True
        assert page2.next_cursor is not None

        page3 = list_customer_bookings(
            user=user,
            segment=SEGMENT_UPCOMING,
            page_size=2,
            cursor=page2.next_cursor,
        )
        assert len(page3.items) == 1
        assert page3.has_more is False
        assert page3.next_cursor is None

        # Concatenating all three pages reconstructs the full ordered set.
        all_ids = (
            [it["id"] for it in page1.items]
            + [it["id"] for it in page2.items]
            + [it["id"] for it in page3.items]
        )
        assert all_ids == [b.id for b in bookings]

    def test_exact_fit_page_no_more(self):
        # Page size equals total: has_more should be False (slice trick
        # only triggers when N+1 actually returned).
        user = UserFactory()
        for _ in range(3):
            _booking_in_future(customer=user)

        result = list_customer_bookings(user=user, page_size=3)
        assert len(result.items) == 3
        assert result.has_more is False
        assert result.next_cursor is None

    def test_page_size_clamped_to_max(self):
        user = UserFactory()
        for _ in range(3):
            _booking_in_future(customer=user)

        # 9999 way over MAX_PAGE_SIZE (50) — selector should clamp.
        result = list_customer_bookings(user=user, page_size=9999)
        # Three items so has_more=False regardless. Just exercising the
        # clamp path doesn't blow up.
        assert len(result.items) == 3

    def test_page_size_below_one_clamped(self):
        user = UserFactory()
        for _ in range(2):
            _booking_in_future(customer=user)

        # 0 / negative clamp to 1 (defensive — view validates this too).
        result = list_customer_bookings(user=user, page_size=0)
        assert len(result.items) == 1
        assert result.has_more is True


class TestListCursorSeek:

    def test_cursor_from_past_segment_descends_correctly(self):
        # Past is ordered DESC; cursor should pull strictly older rows.
        user = UserFactory()
        days = [10, 7, 5, 3, 1]
        bookings = []
        for d in days:
            b = _booking_in_past(
                customer=user, status=JobBooking.STATUS_COMPLETED,
            )
            b.scheduled_start = timezone.now() - datetime.timedelta(days=d)
            b.scheduled_end = b.scheduled_start + datetime.timedelta(hours=1)
            b.save()
            bookings.append(b)
        # Order DESC: 1d ago, 3d, 5d, 7d, 10d.

        page1 = list_customer_bookings(
            user=user, segment=SEGMENT_PAST, page_size=2,
        )
        ids_p1 = [it["id"] for it in page1.items]
        # Most-recent first.
        assert ids_p1 == [bookings[4].id, bookings[3].id]

        page2 = list_customer_bookings(
            user=user, segment=SEGMENT_PAST, page_size=2,
            cursor=page1.next_cursor,
        )
        ids_p2 = [it["id"] for it in page2.items]
        assert ids_p2 == [bookings[2].id, bookings[1].id]

    def test_invalid_cursor_raises_decode_error(self):
        user = UserFactory()
        with pytest.raises(CursorDecodeError):
            list_customer_bookings(
                user=user, segment=SEGMENT_UPCOMING, cursor="@@@invalid@@@",
            )


class TestListSinceFilter:

    def test_since_filters_by_created_at(self):
        user = UserFactory()
        old_b = _booking_in_future(customer=user)
        old_b.created_at = timezone.now() - datetime.timedelta(days=2)
        old_b.save()

        new_b = _booking_in_future(customer=user)
        new_b.created_at = timezone.now() - datetime.timedelta(hours=1)
        new_b.save()

        cutoff = timezone.now() - datetime.timedelta(hours=2)
        result = list_customer_bookings(
            user=user, segment=SEGMENT_UPCOMING, since=cutoff,
        )
        ids = {item["id"] for item in result.items}
        assert ids == {new_b.id}


# =====================================================================
# REJECTED reason resolution from EventLog
# =====================================================================


class TestRejectedReasonResolution:

    def test_resolves_technician_declined_from_event_log(self):
        user = UserFactory()
        b = _booking_in_future(customer=user, status=JobBooking.STATUS_REJECTED)
        _make_rejection_log(
            user=user, job_id=b.id, reason="technician_declined",
        )

        result = list_customer_bookings(user=user, segment=SEGMENT_PAST)
        assert len(result.items) == 1
        item = result.items[0]
        assert item["ui"]["badge_text"] == "Unavailable"

    def test_resolves_sla_timeout_from_event_log(self):
        user = UserFactory()
        b = _booking_in_future(customer=user, status=JobBooking.STATUS_REJECTED)
        _make_rejection_log(user=user, job_id=b.id, reason="sla_timeout")

        result = list_customer_bookings(user=user, segment=SEGMENT_PAST)
        item = result.items[0]
        assert item["ui"]["badge_text"] == "Timed out"
        assert "didn't respond in time" in item["ui"]["headline"]

    def test_no_event_log_falls_back_to_declined(self):
        # Legacy booking predating EventLog rollout — must not crash.
        user = UserFactory()
        _booking_in_future(customer=user, status=JobBooking.STATUS_REJECTED)

        result = list_customer_bookings(user=user, segment=SEGMENT_PAST)
        item = result.items[0]
        assert item["ui"]["badge_text"] == "Unavailable"

    def test_multiple_log_rows_uses_most_recent(self):
        # Defensive: if a buggy retry minted two rows for the same
        # booking, the most recent (DESC by created_at) wins.
        user = UserFactory()
        b = _booking_in_future(customer=user, status=JobBooking.STATUS_REJECTED)
        # Older row says technician_declined.
        old = _make_rejection_log(
            user=user, job_id=b.id, reason="technician_declined",
        )
        EventLog.objects.filter(pk=old.pk).update(
            created_at=timezone.now() - datetime.timedelta(hours=1),
        )
        # Newer row corrects to sla_timeout.
        _make_rejection_log(user=user, job_id=b.id, reason="sla_timeout")

        result = list_customer_bookings(user=user, segment=SEGMENT_PAST)
        item = result.items[0]
        assert item["ui"]["badge_text"] == "Timed out"

    def test_event_log_for_other_user_ignored(self):
        # A's rejection log must NOT leak into B's serialized booking.
        # B's REJECTED booking with no log row should fall back to the
        # generic "Unavailable" copy, not pick up A's "Timed out".
        user_a = UserFactory()
        user_b = UserFactory()
        b_b = _booking_in_future(
            customer=user_b, status=JobBooking.STATUS_REJECTED,
        )
        # User A logs an sla_timeout for *some* booking — irrelevant.
        _make_rejection_log(
            user=user_a, job_id=b_b.id, reason="sla_timeout",
        )

        result = list_customer_bookings(user=user_b, segment=SEGMENT_PAST)
        item = result.items[0]
        assert item["ui"]["badge_text"] == "Unavailable"


# =====================================================================
# IDOR — queryset is always scoped to the requesting user
# =====================================================================


class TestIdorScoping:

    def test_user_a_cannot_see_user_b_bookings(self):
        a = UserFactory()
        b = UserFactory()
        _booking_in_future(customer=b)  # B's booking
        _booking_in_future(customer=b)

        result = list_customer_bookings(user=a, segment=SEGMENT_UPCOMING)
        assert result.items == []

    def test_counts_scoped_per_user(self):
        a = UserFactory()
        b = UserFactory()
        for _ in range(3):
            _booking_in_future(customer=b)
        for _ in range(1):
            _booking_in_future(customer=a)

        a_counts = count_customer_bookings(user=a)
        b_counts = count_customer_bookings(user=b)
        assert a_counts.upcoming == 1
        assert b_counts.upcoming == 3


# =====================================================================
# Performance contract — query count is constant per page
# =====================================================================


class TestQueryCount:
    """
    Contract: rendering N bookings on one page must NOT issue N FK
    follow-up queries. ``select_related`` on technician__user / service
    / sub_service / address keeps everything in one round-trip; the
    EventLog batch lookup adds at most one more.
    """

    def test_constant_query_count_for_page(self, django_assert_num_queries):
        user = UserFactory()
        # Customer profile is OneToOne — create once, share across the
        # five bookings under test.
        profile = CustomerProfileFactory(user=user)
        # Five rows with full FK fan-out (technician, sub_service via
        # the LazyAttribute, address). The selector must NOT scale
        # queries with N.
        for _ in range(5):
            address = CustomerAddressFactory(customer=profile)
            JobBookingFactory(
                customer=user,
                address=address,
                status=JobBooking.STATUS_CONFIRMED,
                scheduled_start=timezone.now() + datetime.timedelta(days=1),
                scheduled_end=timezone.now() + datetime.timedelta(days=1, hours=1),
            )

        # 1 select for the booking page + select_related joins
        # 0 follow-up queries for technicians / services / sub_services
        #   (everything joined in)
        # 1 conditional select for EventLog rejection-reason batch (only
        #   issued when the page contains at least one REJECTED row —
        #   here it's not, so we expect exactly 1 query).
        with django_assert_num_queries(1):
            result = list_customer_bookings(
                user=user, segment=SEGMENT_UPCOMING, page_size=10,
            )
            # Force item materialization (model __iter__ / dict build).
            _ = [item["technician"]["display_name"] for item in result.items]

    def test_scales_to_two_queries_when_rejected_present(
        self, django_assert_num_queries,
    ):
        # When the page contains REJECTED rows, the EventLog batch
        # lookup runs — exactly ONE extra query, NOT one-per-row.
        user = UserFactory()
        for _ in range(5):
            b = _booking_in_future(
                customer=user, status=JobBooking.STATUS_REJECTED,
            )
            _make_rejection_log(
                user=user, job_id=b.id, reason="technician_declined",
            )

        with django_assert_num_queries(2):
            result = list_customer_bookings(
                user=user, segment=SEGMENT_PAST, page_size=10,
            )
            _ = [item["ui"]["badge_text"] for item in result.items]

    def test_counts_two_queries_only(self, django_assert_num_queries):
        user = UserFactory()
        for _ in range(3):
            _booking_in_future(customer=user)
        for _ in range(2):
            _booking_in_past(
                customer=user, status=JobBooking.STATUS_COMPLETED,
            )

        # Two cheap COUNT(*) — one for upcoming, one for past.
        with django_assert_num_queries(2):
            result = count_customer_bookings(user=user)
            assert result.upcoming == 3
            assert result.past == 2


# =====================================================================
# Serialized item shape — every documented field is present and typed
# =====================================================================


class TestSerializedShape:

    def test_item_has_all_documented_top_level_keys(self):
        user = UserFactory()
        address = CustomerAddressFactory(
            customer=CustomerProfileFactory(user=user),
            label="Home",
            locality_label="DHA Phase 5, Lahore",
        )
        b = _booking_in_future(
            customer=user,
            address=address,
            status=JobBooking.STATUS_CONFIRMED,
            price_amount=Decimal("2500.00"),
            price_context="Fixed Price",
        )

        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        item = result.items[0]

        # Top-level keys per CUSTOMER_BOOKINGS_API.md §1.4.
        assert set(item.keys()) == {
            "id",
            "status",
            "service",
            "technician",
            "address_label",
            "scheduled_start",
            "scheduled_end",
            "created_at",
            "price",
            "ui",
        }
        assert item["id"] == b.id
        assert item["status"] == JobBooking.STATUS_CONFIRMED
        assert item["address_label"] == "Home — DHA Phase 5, Lahore"
        assert item["price"]["amount"] == 2500
        assert item["price"]["ui_label"] == "Rs. 2,500"

    def test_address_label_null_when_address_deleted(self):
        # SET_NULL behavior: deleting the address row leaves booking.address=None.
        user = UserFactory()
        address = CustomerAddressFactory(
            customer=CustomerProfileFactory(user=user),
        )
        b = _booking_in_future(customer=user, address=address)
        # Detach.
        b.address = None
        b.save()

        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert result.items[0]["address_label"] is None

    def test_address_label_falls_back_to_street_address(self):
        # When label + locality both blank/null, the street address is
        # the last resort. Defensive — pre-locality-rollout rows.
        user = UserFactory()
        address = CustomerAddressFactory(
            customer=CustomerProfileFactory(user=user),
            label="",
            locality_label=None,
            street_address="House 12, Street 34",
        )
        _booking_in_future(customer=user, address=address)

        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert result.items[0]["address_label"] == "House 12, Street 34"

    def test_technician_display_name_falls_back_to_username(self):
        # No first/last name → username is used. Mirrors
        # _build_job_accepted_payload behavior on the realtime path.
        from tests.factories.technicians import TechnicianProfileFactory

        nameless_user = UserFactory(
            first_name="", last_name="", username="+923001112222",
        )
        tech = TechnicianProfileFactory(user=nameless_user)
        user = UserFactory()
        _booking_in_future(customer=user, technician=tech)

        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert result.items[0]["technician"]["display_name"] == "+923001112222"

    def test_price_ui_label_uses_comma_grouping(self):
        user = UserFactory()
        _booking_in_future(
            customer=user, price_amount=Decimal("123456.00"),
        )
        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert result.items[0]["price"]["ui_label"] == "Rs. 123,456"

    def test_iso_timestamps_round_trip(self):
        user = UserFactory()
        b = _booking_in_future(customer=user)

        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        item = result.items[0]
        # Each timestamp is a parseable ISO-8601 string.
        from datetime import datetime as _dt

        for k in ("scheduled_start", "scheduled_end", "created_at"):
            parsed = _dt.fromisoformat(item[k])
            assert parsed is not None

    def test_server_time_is_tz_aware(self):
        user = UserFactory()
        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert result.server_time.tzinfo is not None


# =====================================================================
# Empty results
# =====================================================================


class TestEmptyResult:

    def test_empty_user_returns_empty_list(self):
        user = UserFactory()
        result = list_customer_bookings(user=user, segment=SEGMENT_UPCOMING)
        assert result.items == []
        assert result.has_more is False
        assert result.next_cursor is None

    def test_empty_counts_are_zero(self):
        user = UserFactory()
        result = count_customer_bookings(user=user)
        assert result.upcoming == 0
        assert result.past == 0


# =====================================================================
# Counts — mirrors list segment definitions
# =====================================================================


class TestCounts:

    def test_counts_match_list_segment_predicates(self):
        user = UserFactory()
        # Two upcoming.
        _booking_in_future(customer=user, status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        _booking_in_future(customer=user, status=JobBooking.STATUS_CONFIRMED)
        # Three past — terminal + aged-out.
        _booking_in_future(customer=user, status=JobBooking.STATUS_REJECTED)
        _booking_in_past(customer=user, status=JobBooking.STATUS_COMPLETED)
        _booking_in_past(customer=user, status=JobBooking.STATUS_CONFIRMED)

        upcoming_list = list_customer_bookings(
            user=user, segment=SEGMENT_UPCOMING, page_size=50,
        )
        past_list = list_customer_bookings(
            user=user, segment=SEGMENT_PAST, page_size=50,
        )
        counts = count_customer_bookings(user=user)

        assert counts.upcoming == len(upcoming_list.items) == 2
        assert counts.past == len(past_list.items) == 3

    def test_counts_server_time_tz_aware(self):
        user = UserFactory()
        result = count_customer_bookings(user=user)
        assert result.server_time.tzinfo is not None

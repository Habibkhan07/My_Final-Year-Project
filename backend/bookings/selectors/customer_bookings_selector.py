"""
Customer-side bookings list + counts selector.

The customer's "My Bookings" tab consumes one of two endpoints — list
(``GET /api/bookings/``) and counts (``GET /api/bookings/counts/``) —
both of which delegate their entire DB read into this module.

Design contract
---------------
* The list response is paginated with an **opaque cursor**, not page
  numbers. The list mutates in realtime (a tech's accept lands as a
  ``job_accepted`` event while the customer is staring at the list);
  page-based pagination would surface an item from page 1 again on page
  2 if a new booking arrived in between. The cursor is a base64-url
  encoded ``(scheduled_start, id)`` tuple that survives those inserts.

* The selector resolves a **server-side ``ui`` block** for every item
  (``badge_text`` / ``badge_tone`` / ``headline``). The Flutter card is
  dumb — it switches on the ``badge_tone`` enum to pick a design token
  but never on the raw ``status`` string for copy. The same status→ui
  table is **mirrored client-side** in the Flutter event-patch mapper
  (Option ii of the realtime list-patch design): when ``job_accepted``
  / ``booking_rejected`` arrives over WS, the mapper recomputes the ui
  block locally instead of round-tripping a detail fetch. Drift between
  this table and the Flutter mirror is the only known cost; the table
  is small enough that bounded duplication is the cheaper trade.

* For ``REJECTED`` rows the selector reads the **latest matching
  ``EventLog`` row** to discriminate ``technician_declined`` from
  ``sla_timeout`` for headline + badge copy. We do this in a single
  batched query keyed on ``payload__job_id__in=[...]`` rather than per
  row — the cost is one extra round-trip per page, not N. When no log
  row is found (e.g. legacy bookings predating ``EventLog``) we fall
  back to a generic "Unavailable" copy.

Performance contract
--------------------
* ``select_related('technician__user', 'service', 'sub_service', 'address')``
  is mandatory — every payload builder reads at least one of these.
* Counts are two cheap aggregate queries; nothing nested.
* The page query slices ``page_size + 1`` to detect ``has_more`` without
  a second COUNT(*).

Security
--------
The base queryset is always ``JobBooking.objects.filter(customer=user)``.
This is the **only** scoping that prevents IDOR on the list and detail
surfaces — there is no per-row permission check at the view layer because
a row that shouldn't be visible never enters the queryset.
"""
from __future__ import annotations

import base64
import json
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Iterable, Optional

from django.db.models import Q, QuerySet
from django.utils import timezone

from bookings.models import JobBooking
from realtime.constants.event_types import EventType
from realtime.models.events import EventLog


# ─────────────────────────────────────────────────────────────────────────
# Public constants — exposed to views/serializers for query validation.
# ─────────────────────────────────────────────────────────────────────────

SEGMENT_UPCOMING = "upcoming"
SEGMENT_PAST = "past"
ALLOWED_SEGMENTS = frozenset({SEGMENT_UPCOMING, SEGMENT_PAST})

# Status sets resolved from a segment.
#
# The Upcoming tab is split into two sub-buckets:
#
#   * **Ageable** — PENDING / AWAITING_TECH_ACCEPT / CONFIRMED. These can
#     "age out" of Upcoming when ``scheduled_end < now`` (the customer
#     booked something, the slot passed, and nothing ever happened). They
#     drop to Past in that case so the customer is not misled into
#     thinking a stale slot is still alive.
#
#   * **Active** — EN_ROUTE / ARRIVED / INSPECTING / QUOTED / IN_PROGRESS.
#     These represent a job that is actively in progress *right now*.
#     They MUST NOT age out by ``scheduled_end``: a job running over its
#     scheduled window is still a live job the customer wants to track.
#     They always live in Upcoming until they hit a terminal status.
#
# PENDING is legacy (never persisted by current code paths after
# migration 0007) — included in ageable as a defensive grace bucket so
# any pre-migration row would not silently disappear from the customer's
# view.
_AGEABLE_UPCOMING_STATUSES = (
    JobBooking.STATUS_PENDING,
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
)
_ACTIVE_UPCOMING_STATUSES = (
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
    JobBooking.STATUS_IN_PROGRESS,
)
_UPCOMING_STATUSES = _AGEABLE_UPCOMING_STATUSES + _ACTIVE_UPCOMING_STATUSES

# All terminal statuses belong in Past. Previously this set omitted
# COMPLETED_INSPECTION_ONLY, NO_SHOW, and DISPUTED — bookings in those
# states were invisible to the customer on both tabs.
_PAST_STATUSES = (
    JobBooking.STATUS_COMPLETED,
    JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
    JobBooking.STATUS_CANCELLED,
    JobBooking.STATUS_REJECTED,
    JobBooking.STATUS_NO_SHOW,
    JobBooking.STATUS_DISPUTED,
)
ALLOWED_STATUSES = frozenset(s for s, _ in JobBooking.STATUS_CHOICES)

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 50

# UI tone enum — must stay in sync with the Flutter ``BookingUiTone`` enum.
TONE_POSITIVE = "positive"
TONE_WARNING = "warning"
TONE_NEGATIVE = "negative"
TONE_NEUTRAL = "neutral"
TONE_INFO = "info"

# Rejection-reason discriminators on the BOOKING_REJECTED event payload.
_REASON_TECH_DECLINED = "technician_declined"
_REASON_SLA_TIMEOUT = "sla_timeout"


# ─────────────────────────────────────────────────────────────────────────
# Cursor encoding — opaque to callers, defined once here.
# ─────────────────────────────────────────────────────────────────────────


class CursorDecodeError(ValueError):
    """Raised when an inbound cursor is malformed. View maps to 400."""


def _encode_cursor(scheduled_start: datetime, booking_id: int) -> str:
    """Pack ``(scheduled_start_iso, id)`` into a url-safe base64 token."""
    payload = json.dumps(
        {"ss": scheduled_start.isoformat(), "id": int(booking_id)},
        separators=(",", ":"),
    ).encode("utf-8")
    return base64.urlsafe_b64encode(payload).rstrip(b"=").decode("ascii")


def _decode_cursor(token: str) -> tuple[datetime, int]:
    """Reverse of ``_encode_cursor``. Raises CursorDecodeError on garbage."""
    try:
        # urlsafe_b64decode requires correct padding; restore it.
        padding = "=" * (-len(token) % 4)
        raw = base64.urlsafe_b64decode(token + padding)
        body = json.loads(raw.decode("utf-8"))
        ss = datetime.fromisoformat(body["ss"])
        booking_id = int(body["id"])
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        raise CursorDecodeError("Cursor is malformed.") from exc
    return ss, booking_id


# ─────────────────────────────────────────────────────────────────────────
# UI resolver — single source of truth for status → display strings.
# Mirrored client-side in the Flutter event-patch mapper.
# ─────────────────────────────────────────────────────────────────────────


def _resolve_ui_block(
    *,
    status: str,
    technician_display_name: str,
    rejection_reason: Optional[str],
) -> dict[str, str]:
    """
    Compute the dumb-UI block for a single booking row.

    ``technician_display_name`` is the upstream-resolved fallback chain
    (``user.get_full_name()`` then ``user.username``); the caller has
    already ensured a non-empty value.

    ``rejection_reason`` is consulted only when ``status == REJECTED``.
    Unknown / missing reason falls back to the technician-declined copy
    (the more common path) — this is also the safest default for legacy
    rows whose ``EventLog`` entry pre-dates the reason discriminator.
    """
    if status == JobBooking.STATUS_AWAITING_TECH_ACCEPT:
        return {
            "badge_text": "Awaiting tech",
            "badge_tone": TONE_WARNING,
            "headline": f"Waiting for {technician_display_name} to confirm",
        }

    if status == JobBooking.STATUS_CONFIRMED:
        return {
            "badge_text": "Confirmed",
            "badge_tone": TONE_POSITIVE,
            "headline": f"Confirmed with {technician_display_name}",
        }

    # Active mid-job statuses — previously fell through to the generic
    # "Pending — Booking is being prepared" copy, which is misleading for
    # a booking the tech is actively servicing.
    if status == JobBooking.STATUS_EN_ROUTE:
        return {
            "badge_text": "On the way",
            "badge_tone": TONE_INFO,
            "headline": f"{technician_display_name} is on the way",
        }

    if status == JobBooking.STATUS_ARRIVED:
        return {
            "badge_text": "Arrived",
            "badge_tone": TONE_INFO,
            "headline": f"{technician_display_name} is at your address",
        }

    if status == JobBooking.STATUS_INSPECTING:
        return {
            "badge_text": "Inspecting",
            "badge_tone": TONE_INFO,
            "headline": f"{technician_display_name} is preparing your quote",
        }

    if status == JobBooking.STATUS_QUOTED:
        return {
            "badge_text": "Quote ready",
            "badge_tone": TONE_WARNING,
            "headline": "Review your quote",
        }

    if status == JobBooking.STATUS_IN_PROGRESS:
        return {
            "badge_text": "In progress",
            "badge_tone": TONE_INFO,
            "headline": f"{technician_display_name} is doing the work",
        }

    if status == JobBooking.STATUS_COMPLETED:
        return {
            "badge_text": "Completed",
            "badge_tone": TONE_POSITIVE,
            "headline": f"Completed by {technician_display_name}",
        }

    if status == JobBooking.STATUS_COMPLETED_INSPECTION_ONLY:
        return {
            "badge_text": "Inspection only",
            "badge_tone": TONE_NEUTRAL,
            "headline": "You declined the quote — inspection fee was due",
        }

    if status == JobBooking.STATUS_CANCELLED:
        return {
            "badge_text": "Cancelled",
            "badge_tone": TONE_NEUTRAL,
            "headline": "You cancelled this booking",
        }

    if status == JobBooking.STATUS_REJECTED:
        if rejection_reason == _REASON_SLA_TIMEOUT:
            return {
                "badge_text": "Timed out",
                "badge_tone": TONE_NEGATIVE,
                "headline": f"{technician_display_name} didn't respond in time",
            }
        # technician_declined (explicit) OR unknown / missing → same copy.
        return {
            "badge_text": "Unavailable",
            "badge_tone": TONE_NEGATIVE,
            "headline": f"{technician_display_name} couldn't take this",
        }

    if status == JobBooking.STATUS_NO_SHOW:
        return {
            "badge_text": "No-show",
            "badge_tone": TONE_NEGATIVE,
            "headline": "This booking ended in a no-show",
        }

    if status == JobBooking.STATUS_DISPUTED:
        return {
            "badge_text": "Disputed",
            "badge_tone": TONE_NEGATIVE,
            "headline": "A dispute has been opened on this booking",
        }

    # PENDING (legacy) and any future status not yet mapped.
    return {
        "badge_text": "Pending",
        "badge_tone": TONE_NEUTRAL,
        "headline": "Booking is being prepared",
    }


# ─────────────────────────────────────────────────────────────────────────
# Helpers — display name fallback, price formatting.
# ─────────────────────────────────────────────────────────────────────────


def _technician_display_name(booking: JobBooking) -> str:
    """``get_full_name`` → ``username`` fallback, mirrors the realtime payload."""
    user = booking.technician.user
    return user.get_full_name() or user.username


def _service_name(booking: JobBooking) -> str:
    """Sub-service preferred (more specific) — mirrors the realtime payload."""
    if booking.sub_service_id:
        return booking.sub_service.name
    return booking.service.name


def _service_icon_name(booking: JobBooking) -> str:
    """SubService.icon_name preferred; falls back to Service.icon_name."""
    if booking.sub_service_id and getattr(booking.sub_service, "icon_name", ""):
        return booking.sub_service.icon_name
    return getattr(booking.service, "icon_name", "") or ""


def _address_label(booking: JobBooking) -> Optional[str]:
    """
    One-line address summary for the card. ``label`` is the user-given
    name ("Home", "Office") and ``locality_label`` is the reverse-geocoded
    suburb (e.g. "DHA Phase 5, Lahore"). Returns null when the address
    has been deleted (FK is SET_NULL) — the card hides the row entirely.
    """
    address = booking.address
    if address is None:
        return None
    label = (address.label or "").strip()
    locality = (address.locality_label or "").strip()
    if label and locality:
        return f"{label} — {locality}"
    if label:
        return label
    if locality:
        return locality
    return (address.street_address or "").strip() or None


def _format_price_label(amount: Any) -> str:
    """Comma-grouped rupee label, e.g. ``Rs. 2,500``. Mirrors ResolvedIntent."""
    try:
        as_int = int(amount)
    except (TypeError, ValueError):
        return f"Rs. {amount}"
    return f"Rs. {as_int:,}"


# ─────────────────────────────────────────────────────────────────────────
# Rejection-reason batched lookup.
# ─────────────────────────────────────────────────────────────────────────


def _load_rejection_reasons(
    *, user, booking_ids: Iterable[int]
) -> dict[int, str]:
    """
    Single batched query: most-recent BOOKING_REJECTED event per booking
    in the page, keyed by ``payload.job_id``. Returns a ``{job_id: reason}``
    map. Bookings with no log row are simply absent from the dict.

    The query is scoped to ``user`` for two reasons: it's an additional
    IDOR belt-and-braces (the booking queryset is already user-scoped,
    but cross-user EventLog reads have no business here either), and it
    keeps the index path on ``evlog_user_created_idx`` sharp.
    """
    ids = list(booking_ids)
    if not ids:
        return {}

    rows = (
        EventLog.objects
        .filter(
            user=user,
            event_type=EventType.BOOKING_REJECTED.value,
            payload__job_id__in=ids,
        )
        .order_by("-created_at")
        .values_list("payload", flat=True)
    )

    out: dict[int, str] = {}
    for payload in rows:
        if not isinstance(payload, dict):
            continue
        job_id = payload.get("job_id")
        reason = payload.get("reason")
        if job_id is None or reason is None:
            continue
        # Earlier insertions win because we ordered DESC and only fill
        # the first-seen reason per job_id.
        try:
            key = int(job_id)
        except (TypeError, ValueError):
            continue
        if key in out:
            continue
        out[key] = str(reason)
    return out


# ─────────────────────────────────────────────────────────────────────────
# Public selector API.
# ─────────────────────────────────────────────────────────────────────────


@dataclass(frozen=True)
class CustomerBookingsListResult:
    """Return type of :func:`list_customer_bookings`. Stable wire contract."""
    items: list[dict[str, Any]]
    next_cursor: Optional[str]
    has_more: bool
    server_time: datetime


def _base_qs(user) -> "QuerySet[JobBooking]":
    """Always-on customer scope + the joins every payload reads."""
    # SECURITY: customer=user is the IDOR boundary. Every public function
    # in this module starts here.
    return (
        JobBooking.objects
        .filter(customer=user)
        .select_related(
            "technician__user",
            "service",
            "sub_service",
            "address",
        )
    )


def _apply_segment(
    qs: "QuerySet[JobBooking]",
    *,
    segment: str,
    now: datetime,
) -> tuple["QuerySet[JobBooking]", str]:
    """
    Translate the segment label into a status filter + scheduled_end
    window, returning the sort order ('asc'|'desc') the caller should
    apply. Segment is the dumb-UI shortcut; explicit ``status`` filters
    bypass this helper entirely.

    **Upcoming** =
        active-mid-job statuses (always, regardless of scheduled_end)
        OR ageable statuses whose scheduled_end is still in the future.

    **Past** = terminal statuses OR an ageable row whose scheduled_end
    has passed (booked something, slot passed, nothing happened). Active
    mid-job rows never fall into Past via the age-out path — they leave
    via a real terminal transition.
    """
    if segment == SEGMENT_UPCOMING:
        qs = qs.filter(
            Q(status__in=_ACTIVE_UPCOMING_STATUSES)
            | Q(
                status__in=_AGEABLE_UPCOMING_STATUSES,
                scheduled_end__gte=now,
            )
        )
        return qs, "asc"

    # SEGMENT_PAST
    qs = qs.filter(
        Q(status__in=_PAST_STATUSES)
        | Q(status__in=_AGEABLE_UPCOMING_STATUSES, scheduled_end__lt=now)
    )
    return qs, "desc"


def _apply_cursor(
    qs: "QuerySet[JobBooking]",
    *,
    cursor: Optional[str],
    direction: str,
) -> "QuerySet[JobBooking]":
    """Apply seek-pagination predicate. Cursor decode errors propagate."""
    if not cursor:
        return qs
    ss, last_id = _decode_cursor(cursor)
    if direction == "asc":
        # Strict-greater on (scheduled_start, id).
        return qs.filter(
            Q(scheduled_start__gt=ss)
            | Q(scheduled_start=ss, id__gt=last_id)
        )
    return qs.filter(
        Q(scheduled_start__lt=ss)
        | Q(scheduled_start=ss, id__lt=last_id)
    )


def _serialize_booking(
    booking: JobBooking,
    *,
    rejection_reason: Optional[str],
) -> dict[str, Any]:
    """Build the wire-shape dict for a single list item."""
    tech_name = _technician_display_name(booking)
    ui = _resolve_ui_block(
        status=booking.status,
        technician_display_name=tech_name,
        rejection_reason=rejection_reason,
    )
    return {
        "id": booking.id,
        "status": booking.status,
        "service": {
            "name": _service_name(booking),
            "icon_name": _service_icon_name(booking),
        },
        "technician": {
            "id": booking.technician_id,
            "display_name": tech_name,
            "profile_picture_url": _profile_picture_url(booking),
        },
        "address_label": _address_label(booking),
        "scheduled_start": booking.scheduled_start.isoformat(),
        "scheduled_end": booking.scheduled_end.isoformat(),
        "created_at": booking.created_at.isoformat(),
        "price": {
            "amount": int(booking.price_amount),
            "context": booking.price_context or "",
            "ui_label": _format_price_label(booking.price_amount),
        },
        "ui": ui,
    }


def _profile_picture_url(booking: JobBooking) -> Optional[str]:
    """ImageField → public URL or null. Caller doesn't have request, so
    we return the storage URL as-is; settings determine absolute vs.
    relative form."""
    field = getattr(booking.technician, "profile_picture", None)
    if not field:
        return None
    try:
        return field.url
    except (ValueError, AttributeError):
        return None


def list_customer_bookings(
    *,
    user,
    segment: str = SEGMENT_UPCOMING,
    status_filter: Optional[Iterable[str]] = None,
    cursor: Optional[str] = None,
    page_size: int = DEFAULT_PAGE_SIZE,
    since: Optional[datetime] = None,
) -> CustomerBookingsListResult:
    """
    Paginated, segment-filtered list of the user's bookings.

    Parameters
    ----------
    user :
        The authenticated customer. Queryset is scoped here for IDOR.
    segment :
        ``"upcoming"`` (default) or ``"past"``. Resolved into a status
        set + scheduled_end window. Ignored if ``status_filter`` is set.
    status_filter :
        Optional explicit status csv override. When set, the segment's
        time-window predicate is dropped and ordering falls back to
        ``scheduled_start DESC`` (most-recent first).
    cursor :
        Opaque token from the previous response's ``next_cursor``.
    page_size :
        Caller-validated; clamped here as a defense in depth.
    since :
        Optional ``created_at__gte`` for incremental sync. The list
        notifier doesn't use this in v1; reserved for future polling
        callers.

    Returns
    -------
    CustomerBookingsListResult
    """
    page_size = max(1, min(int(page_size), MAX_PAGE_SIZE))
    now = timezone.now()

    qs = _base_qs(user)
    if since is not None:
        qs = qs.filter(created_at__gte=since)

    if status_filter:
        qs = qs.filter(status__in=list(status_filter))
        direction = "desc"
    else:
        qs, direction = _apply_segment(qs, segment=segment, now=now)

    qs = _apply_cursor(qs, cursor=cursor, direction=direction)

    if direction == "asc":
        qs = qs.order_by("scheduled_start", "id")
    else:
        qs = qs.order_by("-scheduled_start", "-id")

    # Slice page_size + 1 to detect has_more without an extra COUNT(*).
    rows = list(qs[: page_size + 1])
    has_more = len(rows) > page_size
    page = rows[:page_size]

    rejection_map = _load_rejection_reasons(
        user=user,
        booking_ids=[b.id for b in page if b.status == JobBooking.STATUS_REJECTED],
    )

    items = [
        _serialize_booking(b, rejection_reason=rejection_map.get(b.id))
        for b in page
    ]

    next_cursor: Optional[str] = None
    if has_more and page:
        last = page[-1]
        next_cursor = _encode_cursor(last.scheduled_start, last.id)

    return CustomerBookingsListResult(
        items=items,
        next_cursor=next_cursor,
        has_more=has_more,
        server_time=now,
    )


@dataclass(frozen=True)
class CustomerBookingsCountsResult:
    upcoming: int
    past: int
    server_time: datetime


def count_customer_bookings(*, user) -> CustomerBookingsCountsResult:
    """
    Two cheap aggregate queries — no row materialization, no joins.

    Used by the segmented control to render badge counts without
    paginating either segment. Re-runs on the same realtime triggers as
    the list notifier (status flip events).

    SECURITY: ``customer=user`` scope is inherited from ``_base_qs``.
    """
    now = timezone.now()
    base = JobBooking.objects.filter(customer=user)

    # Mirror `_apply_segment` exactly — the badge counts MUST match the
    # list filter, or the user sees N in the badge and ≠ N rows on tap.
    upcoming_count = (
        base.filter(
            Q(status__in=_ACTIVE_UPCOMING_STATUSES)
            | Q(
                status__in=_AGEABLE_UPCOMING_STATUSES,
                scheduled_end__gte=now,
            )
        ).count()
    )
    past_count = (
        base.filter(
            Q(status__in=_PAST_STATUSES)
            | Q(status__in=_AGEABLE_UPCOMING_STATUSES, scheduled_end__lt=now)
        ).count()
    )
    return CustomerBookingsCountsResult(
        upcoming=upcoming_count,
        past=past_count,
        server_time=now,
    )

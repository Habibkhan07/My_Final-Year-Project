"""
Tech-side scheduled-jobs list + counts selector.

Powers the technician "Schedule" tab — the audience-flipped counterpart of
the customer "My Bookings" tab. Same wire envelope and cursor pagination
as :mod:`bookings.selectors.customer_bookings_selector`; the differences
are audience-driven:

* Base queryset is scoped to the **technician** FK, not the customer FK.
* Each row's ``customer`` block replaces the ``technician`` block.
* Server-resolved ``ui`` block uses **tech-framed copy** — "Booked with
  {customer_name}", "You're on the way to {customer_name}", "You declined
  this job", etc.
* Each row carries a ``payout`` block (net take-home, post-commission)
  instead of a ``price`` block (customer's gross bill). The card displays
  what the tech earns, not what the customer pays.
* Counts endpoint returns ``{upcoming, past, server_time}`` — earnings
  aggregates live on the Metrics tab; this selector deliberately does
  not duplicate them (see CLAUDE.md "wallet-vs-metrics-separation"
  feedback memory).

The cursor format and segment partition logic are **deliberately identical**
to the customer-side selector — the bookings list mutates in realtime on
both sides for the same reasons (a status flip mid-scroll), and divergence
would create a second class of bugs.

Performance contract
--------------------
* ``select_related('customer', 'service', 'sub_service', 'address',
  'commission')`` is mandatory — every payload builder reads at least
  one of these. ``commission`` is the reverse OneToOne from
  ``wallet.JobCommission`` and is the authoritative payout source for
  COMPLETED bookings.
* Counts are two cheap aggregate queries; nothing nested.
* The page query slices ``page_size + 1`` to detect ``has_more`` without
  a second ``COUNT(*)``.

Security
--------
The base queryset is always
``JobBooking.objects.filter(technician=tech_profile)``. This is the
**only** scoping that prevents IDOR on the list and counts surfaces —
there is no per-row permission check at the view layer because a row
that shouldn't be visible never enters the queryset. The view resolves
``request.user.tech_profile`` via try/except and returns 403 to non-tech
users before this selector is ever called.
"""
from __future__ import annotations

import base64
import json
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Any, Iterable, Optional

from django.db.models import Q, QuerySet
from django.utils import timezone

from bookings.models import JobBooking
from bookings.services.job_request_dispatch import TECHNICIAN_NET_RATE
from technicians.models import TechnicianProfile


# ─────────────────────────────────────────────────────────────────────────
# Public constants — exposed to views/serializers for query validation.
# ─────────────────────────────────────────────────────────────────────────

SEGMENT_UPCOMING = "upcoming"
SEGMENT_PAST = "past"
ALLOWED_SEGMENTS = frozenset({SEGMENT_UPCOMING, SEGMENT_PAST})

# Status partition — mirrors customer side exactly so a status that lives
# in Upcoming for the customer also lives in Upcoming for the tech. The
# split between "ageable" and "active" exists for the same reason as the
# customer side: a job actively in progress must NOT age out by
# scheduled_end (running over the window is still a live job), but a
# booking that nobody ever accepted (AWAITING) or that was confirmed and
# then forgotten (CONFIRMED with scheduled_end in the past) should drop
# out of Upcoming.
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

_PAST_STATUSES = (
    JobBooking.STATUS_COMPLETED,
    JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
    JobBooking.STATUS_CANCELLED,
    JobBooking.STATUS_TECH_DECLINED,
    JobBooking.STATUS_TECH_NO_RESPONSE,
    JobBooking.STATUS_NO_SHOW,
    JobBooking.STATUS_DISPUTED,
)
ALLOWED_STATUSES = frozenset(s for s, _ in JobBooking.STATUS_CHOICES)

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 50

# UI tone enum — must stay in sync with the Flutter ``BookingUiTone`` enum.
# Same values as the customer-side selector for consistency.
TONE_POSITIVE = "positive"
TONE_WARNING = "warning"
TONE_NEGATIVE = "negative"
TONE_NEUTRAL = "neutral"
TONE_INFO = "info"

# ─────────────────────────────────────────────────────────────────────────
# Cursor encoding — opaque to callers, defined once here.
#
# Format is identical to the customer-side selector (base64-url of
# ``{ss, id}``) so a future shared-pagination helper can absorb both.
# ─────────────────────────────────────────────────────────────────────────


class CursorDecodeError(ValueError):
    """Raised when an inbound cursor is malformed. View maps to 400."""


def _encode_cursor(scheduled_start: datetime, booking_id: int) -> str:
    payload = json.dumps(
        {"ss": scheduled_start.isoformat(), "id": int(booking_id)},
        separators=(",", ":"),
    ).encode("utf-8")
    return base64.urlsafe_b64encode(payload).rstrip(b"=").decode("ascii")


def _decode_cursor(token: str) -> tuple[datetime, int]:
    try:
        padding = "=" * (-len(token) % 4)
        raw = base64.urlsafe_b64decode(token + padding)
        body = json.loads(raw.decode("utf-8"))
        ss = datetime.fromisoformat(body["ss"])
        booking_id = int(body["id"])
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        raise CursorDecodeError("Cursor is malformed.") from exc
    return ss, booking_id


# ─────────────────────────────────────────────────────────────────────────
# UI resolver — tech-framed copy table.
# ─────────────────────────────────────────────────────────────────────────


def _resolve_ui_block(
    *,
    status: str,
    customer_display_name: str,
    cancel_reason: Optional[str],
) -> dict[str, str]:
    """
    Tech-POV display block. The tech is the actor in this UI, so headlines
    use second person ("You're on the way", "You declined") where the
    customer-side would say third person.

    Tech-acceptance failure cause is encoded in the status enum:
    ``TECH_DECLINED`` (tech tapped Decline) vs ``TECH_NO_RESPONSE`` (SLA
    timer fired). Pre-migration 0013 these collapsed to ``REJECTED`` and
    the cause came from a side-channel EventLog lookup; now the status
    carries it.

    AWAITING is included for completeness even though Schedule is not the
    tech's primary surface for unaccepted requests (that's the
    incoming_job_requests feature). If a row sits in AWAITING long enough
    to be visible here, the tech sees a clear call to action.
    """
    if status == JobBooking.STATUS_AWAITING_TECH_ACCEPT:
        return {
            "badge_text": "New request",
            "badge_tone": TONE_WARNING,
            "headline": f"Tap to review — {customer_display_name}",
        }

    if status == JobBooking.STATUS_CONFIRMED:
        return {
            "badge_text": "Confirmed",
            "badge_tone": TONE_POSITIVE,
            "headline": f"Booked with {customer_display_name}",
        }

    if status == JobBooking.STATUS_EN_ROUTE:
        return {
            "badge_text": "On the way",
            "badge_tone": TONE_INFO,
            "headline": f"You're on the way to {customer_display_name}",
        }

    if status == JobBooking.STATUS_ARRIVED:
        return {
            "badge_text": "Arrived",
            "badge_tone": TONE_INFO,
            "headline": "You've arrived at the address",
        }

    if status == JobBooking.STATUS_INSPECTING:
        return {
            "badge_text": "Inspecting",
            "badge_tone": TONE_INFO,
            "headline": "Preparing the quote",
        }

    if status == JobBooking.STATUS_QUOTED:
        return {
            "badge_text": "Quote sent",
            "badge_tone": TONE_WARNING,
            "headline": f"Awaiting {customer_display_name}'s review",
        }

    if status == JobBooking.STATUS_IN_PROGRESS:
        return {
            "badge_text": "In progress",
            "badge_tone": TONE_INFO,
            "headline": "Working on the job",
        }

    if status == JobBooking.STATUS_COMPLETED:
        return {
            "badge_text": "Completed",
            "badge_tone": TONE_POSITIVE,
            "headline": f"Completed for {customer_display_name}",
        }

    if status == JobBooking.STATUS_COMPLETED_INSPECTION_ONLY:
        # The quote was declined — tech kept the inspection fee in cash;
        # no commission was taken (per WalletFinanceAdapter contract).
        return {
            "badge_text": "Inspection only",
            "badge_tone": TONE_NEUTRAL,
            "headline": "Customer declined the quote — inspection fee kept",
        }

    if status == JobBooking.STATUS_CANCELLED:
        if cancel_reason == "technician_cancelled":
            headline = "You cancelled this booking"
        elif cancel_reason == "customer_rescheduled":
            # Stub parent of a reschedule chain. The child booking lives
            # as a separate row; this row marks the original slot.
            headline = f"{customer_display_name} rescheduled"
        elif cancel_reason and cancel_reason.startswith("customer_"):
            headline = f"{customer_display_name} cancelled"
        else:
            # Missing audit — don't blame either party.
            headline = "Booking was cancelled"
        return {
            "badge_text": "Cancelled",
            "badge_tone": TONE_NEUTRAL,
            "headline": headline,
        }

    if status == JobBooking.STATUS_TECH_DECLINED:
        return {
            "badge_text": "Declined",
            "badge_tone": TONE_NEGATIVE,
            "headline": "You declined this job",
        }

    if status == JobBooking.STATUS_TECH_NO_RESPONSE:
        # SLA timed out before the tech replied — implies a missed
        # notification, not a deliberate decline. Different mental model
        # than active decline; copy reflects that.
        return {
            "badge_text": "Timed out",
            "badge_tone": TONE_NEGATIVE,
            "headline": "You missed the response window",
        }

    if status == JobBooking.STATUS_NO_SHOW:
        return {
            "badge_text": "No-show",
            "badge_tone": TONE_NEGATIVE,
            "headline": "Customer wasn't there",
        }

    if status == JobBooking.STATUS_DISPUTED:
        return {
            "badge_text": "Disputed",
            "badge_tone": TONE_NEGATIVE,
            "headline": "A dispute was opened on this booking",
        }

    # PENDING (legacy) and any future status not yet mapped.
    return {
        "badge_text": "Pending",
        "badge_tone": TONE_NEUTRAL,
        "headline": "Booking is being prepared",
    }


# ─────────────────────────────────────────────────────────────────────────
# Helpers — display name fallbacks, address, payout, icon.
# ─────────────────────────────────────────────────────────────────────────


def _customer_display_name(booking: JobBooking) -> str:
    """``get_full_name`` → ``username`` fallback. Mirrors realtime payload."""
    user = booking.customer
    full_name = user.get_full_name()
    return full_name if full_name else user.username


def _service_name(booking: JobBooking) -> str:
    """Sub-service preferred when present (more specific job description)."""
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
    One-line address summary for the card. On the tech side this is the
    **destination** — where the tech is driving to. Customer-side serves
    the same shape under the same field name; the FE swap is purely
    semantic.

    Returns null when the address FK was SET_NULL (deleted address row),
    falling through to ``actual_address_snapshot`` if present, then null.
    """
    address = booking.address
    if address is not None:
        label = (address.label or "").strip()
        locality = (address.locality_label or "").strip()
        if label and locality:
            return f"{label} — {locality}"
        if label:
            return label
        if locality:
            return locality
        street = (address.street_address or "").strip()
        if street:
            return street

    # Address row deleted — fall back to the booking-time snapshot which
    # survives address deletion (frozen at booking creation).
    snapshot = (booking.actual_address_snapshot or "").strip()
    return snapshot if snapshot else None


def _format_rupee_label(amount: Any) -> str:
    """Comma-grouped rupee label, e.g. ``Rs. 1,620``. Mirrors customer side."""
    try:
        as_int = int(amount)
    except (TypeError, ValueError):
        return f"Rs. {amount}"
    return f"Rs. {as_int:,}"


def _resolve_payout_block(booking: JobBooking) -> dict[str, Any]:
    """
    Tech net take-home for this booking.

    Two-tier resolution:

    * **COMPLETED with a JobCommission row** — read the snapshotted
      ``payout_amount - commission_amount``. This is the authoritative
      net the wallet ledger actually moved. ``JobCommission`` uses the
      potentially-confusing field name ``payout_amount`` to mean *gross
      bill* (what the customer paid); net is the difference.

    * **Anything else** — project from ``price_amount`` using
      ``TECHNICIAN_NET_RATE`` (currently 80%). The label notes "Est."
      so the tech understands the value is pre-completion.

    Notes:
    * COMPLETED_INSPECTION_ONLY pays no commission (tech kept the
      inspection fee in cash); we surface the inspection fee as the
      payout context.
    * REJECTED / CANCELLED / NO_SHOW / DISPUTED show the projected
      payout the tech *would have* earned. Marked "Forgone" so it does
      not read as a real earning.
    * Empty ``context`` lets the FE hide the payout context row.
    """
    status = booking.status

    # Try the authoritative source for COMPLETED.
    commission = getattr(booking, "commission", None)
    if status == JobBooking.STATUS_COMPLETED and commission is not None:
        net = commission.payout_amount - commission.commission_amount
        commission_paid = int(commission.commission_amount)
        return {
            "amount": int(net),
            "context": f"After Rs. {commission_paid:,} commission",
            "ui_label": _format_rupee_label(net),
        }

    # COMPLETED without a JobCommission row — production-rare (orchestrator
    # always writes one on IN_PROGRESS → COMPLETED), but seeded fixtures
    # can bypass it. Label as "Payout" without the "Est." prefix so the
    # tech does not read a completed job as still pending.
    if status == JobBooking.STATUS_COMPLETED:
        projected = (booking.price_amount or Decimal("0")) * TECHNICIAN_NET_RATE
        return {
            "amount": int(projected),
            "context": "Payout",
            "ui_label": _format_rupee_label(projected),
        }

    # COMPLETED_INSPECTION_ONLY — tech kept the inspection fee cash.
    if status == JobBooking.STATUS_COMPLETED_INSPECTION_ONLY:
        fee = booking.inspection_fee or Decimal("0")
        return {
            "amount": int(fee),
            "context": "Inspection fee (cash)",
            "ui_label": _format_rupee_label(fee),
        }

    # Forgone earnings — surface the projection but label it accordingly
    # so the tech does not mistake it for income.
    if status in (
        JobBooking.STATUS_TECH_DECLINED,
        JobBooking.STATUS_TECH_NO_RESPONSE,
        JobBooking.STATUS_CANCELLED,
        JobBooking.STATUS_NO_SHOW,
        JobBooking.STATUS_DISPUTED,
    ):
        projected = (booking.price_amount or Decimal("0")) * TECHNICIAN_NET_RATE
        return {
            "amount": int(projected),
            "context": "Forgone",
            "ui_label": _format_rupee_label(projected),
        }

    # Default: projected net for everything else (AWAITING through
    # IN_PROGRESS). The job hasn't completed yet, so the commission
    # snapshot doesn't exist — project from PLATFORM_COMMISSION_RATE.
    projected = (booking.price_amount or Decimal("0")) * TECHNICIAN_NET_RATE
    return {
        "amount": int(projected),
        "context": "Est. payout",
        "ui_label": _format_rupee_label(projected),
    }


# ─────────────────────────────────────────────────────────────────────────
# Public selector API.
# ─────────────────────────────────────────────────────────────────────────


@dataclass(frozen=True)
class ScheduledJobsListResult:
    """Return type of :func:`list_scheduled_jobs`. Stable wire contract."""
    items: list[dict[str, Any]]
    next_cursor: Optional[str]
    has_more: bool
    server_time: datetime


@dataclass(frozen=True)
class ScheduledJobsCountsResult:
    """Return type of :func:`count_scheduled_jobs`."""
    upcoming: int
    past: int
    server_time: datetime


def _base_qs(tech_profile: TechnicianProfile) -> "QuerySet[JobBooking]":
    """Always-on tech scope + the joins every payload reads."""
    # SECURITY: technician=tech_profile is the IDOR boundary. Every
    # public function in this module starts here. ``commission`` is a
    # reverse OneToOne and must be select_related'd to avoid one extra
    # query per COMPLETED row when building the payout block.
    return (
        JobBooking.objects
        .filter(technician=tech_profile)
        .select_related(
            "customer",
            "service",
            "sub_service",
            "address",
            "commission",
        )
    )


def _apply_segment(
    qs: "QuerySet[JobBooking]",
    *,
    segment: str,
    now: datetime,
) -> tuple["QuerySet[JobBooking]", str]:
    """Translate segment → status filter + sort direction. See module docstring."""
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
    """Seek-pagination predicate. Cursor decode errors propagate to the view."""
    if not cursor:
        return qs
    ss, last_id = _decode_cursor(cursor)
    if direction == "asc":
        return qs.filter(
            Q(scheduled_start__gt=ss)
            | Q(scheduled_start=ss, id__gt=last_id)
        )
    return qs.filter(
        Q(scheduled_start__lt=ss)
        | Q(scheduled_start=ss, id__lt=last_id)
    )


def _serialize_booking(booking: JobBooking) -> dict[str, Any]:
    """Build the wire-shape dict for a single list item."""
    customer_name = _customer_display_name(booking)
    ui = _resolve_ui_block(
        status=booking.status,
        customer_display_name=customer_name,
        cancel_reason=booking.cancel_reason,
    )
    return {
        "id": booking.id,
        "status": booking.status,
        "service": {
            "name": _service_name(booking),
            "icon_name": _service_icon_name(booking),
        },
        "customer": {
            "id": booking.customer_id,
            "display_name": customer_name,
            # CustomerProfile has no profile_picture field in v1.
            # FE renders an initials avatar when null.
            "profile_picture_url": None,
        },
        "address_label": _address_label(booking),
        "scheduled_start": booking.scheduled_start.isoformat(),
        "scheduled_end": booking.scheduled_end.isoformat(),
        "created_at": booking.created_at.isoformat(),
        "payout": _resolve_payout_block(booking),
        "ui": ui,
    }


def list_scheduled_jobs(
    *,
    tech_profile: TechnicianProfile,
    segment: str = SEGMENT_UPCOMING,
    status_filter: Optional[Iterable[str]] = None,
    cursor: Optional[str] = None,
    page_size: int = DEFAULT_PAGE_SIZE,
    since: Optional[datetime] = None,
) -> ScheduledJobsListResult:
    """
    Paginated, segment-filtered list of the technician's bookings.

    Parameters
    ----------
    tech_profile :
        The authenticated tech's profile. Queryset is scoped here for IDOR.
    segment :
        ``"upcoming"`` (default) or ``"past"``. Ignored if ``status_filter``
        is set.
    status_filter :
        Optional explicit status csv override. When set, the segment's
        time-window predicate is dropped and ordering falls back to
        ``scheduled_start DESC``.
    cursor :
        Opaque token from the previous response's ``next_cursor``.
    page_size :
        Caller-validated; clamped here as a defense in depth.
    since :
        Optional ``created_at__gte`` for incremental sync. v1 list notifier
        doesn't use this; reserved for future polling callers.
    """
    page_size = max(1, min(int(page_size), MAX_PAGE_SIZE))
    now = timezone.now()

    qs = _base_qs(tech_profile)
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

    items = [_serialize_booking(b) for b in page]

    next_cursor: Optional[str] = None
    if has_more and page:
        last = page[-1]
        next_cursor = _encode_cursor(last.scheduled_start, last.id)

    return ScheduledJobsListResult(
        items=items,
        next_cursor=next_cursor,
        has_more=has_more,
        server_time=now,
    )


def count_scheduled_jobs(
    *, tech_profile: TechnicianProfile
) -> ScheduledJobsCountsResult:
    """
    Two cheap aggregate queries for the segmented-control badges. Mirrors
    ``_apply_segment`` exactly so badge counts equal what the user sees
    on tap — a mismatched count is a worse UX than a slightly stale one.

    SECURITY: ``technician=tech_profile`` scope is inherited from the
    caller-supplied profile, which the view resolved from
    ``request.user.tech_profile``.
    """
    now = timezone.now()
    base = JobBooking.objects.filter(technician=tech_profile)

    upcoming_count = base.filter(
        Q(status__in=_ACTIVE_UPCOMING_STATUSES)
        | Q(
            status__in=_AGEABLE_UPCOMING_STATUSES,
            scheduled_end__gte=now,
        )
    ).count()
    past_count = base.filter(
        Q(status__in=_PAST_STATUSES)
        | Q(status__in=_AGEABLE_UPCOMING_STATUSES, scheduled_end__lt=now)
    ).count()

    return ScheduledJobsCountsResult(
        upcoming=upcoming_count,
        past=past_count,
        server_time=now,
    )

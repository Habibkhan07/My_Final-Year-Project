"""Period-aware technician activity metrics for the Metrics screen.

Returns:
    {
        "period": "day" | "week" | "month" | "year",
        "total_jobs": int,
        "total_cash": float,
        "buckets": [
            {"label": "Mon", "jobs": 2, "cash": 4500.0},
            ...
        ],
    }

Buckets per period (all zeros backfilled so the chart never has gaps):
    day   — last 7 days, daily         (labels: 'Mon','Tue',...,'Today')
    week  — current ISO week, daily    (labels: 'Mon'..'Sun')
    month — last 30 days, daily        (labels: '1'..'30' = day-of-month)
    year  — current year, monthly      (labels: 'Jan'..'Dec')

Commission deducted is intentionally NOT here — that's a wallet-side
transaction, not a customer-revenue metric. The wallet's transaction
history (separate flag.md follow-up) is its proper home.
"""
from datetime import date, timedelta

from django.db.models import Count, Sum
from django.db.models.functions import TruncDate, TruncMonth
from django.utils import timezone

from bookings.models import JobBooking
from technicians.models import TechnicianProfile

# Single source of truth for the wire enum.
PERIOD_DAY = 'day'
PERIOD_WEEK = 'week'
PERIOD_MONTH = 'month'
PERIOD_YEAR = 'year'
VALID_PERIODS = (PERIOD_DAY, PERIOD_WEEK, PERIOD_MONTH, PERIOD_YEAR)

_WEEK_LABELS = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')
_MONTH_LABELS = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
)


def get_technician_metrics(technician: TechnicianProfile, period: str = PERIOD_WEEK) -> dict:
    """Return period-aware metrics for [technician].

    Raises ValueError on unknown period. The view validates beforehand;
    this is a defence-in-depth check.
    """
    if period not in VALID_PERIODS:
        raise ValueError(f"Unknown period: {period!r}")

    today = timezone.localdate()

    if period == PERIOD_DAY:
        # Last 7 days ending today. Today is the rightmost bar.
        start = today - timedelta(days=6)
        buckets = _daily_buckets(
            technician, start, today,
            labels=[_day_label(start + timedelta(days=i), today) for i in range(7)],
        )
    elif period == PERIOD_WEEK:
        # Current ISO week — Monday → Sunday.
        week_start = today - timedelta(days=today.weekday())
        buckets = _daily_buckets(
            technician, week_start, week_start + timedelta(days=6),
            labels=list(_WEEK_LABELS),
        )
    elif period == PERIOD_MONTH:
        # Last 30 days ending today.
        start = today - timedelta(days=29)
        buckets = _daily_buckets(
            technician, start, today,
            labels=[str((start + timedelta(days=i)).day) for i in range(30)],
        )
    else:  # PERIOD_YEAR
        # Current calendar year, Jan → Dec.
        year_start = date(today.year, 1, 1)
        year_end = date(today.year, 12, 31)
        buckets = _monthly_buckets(
            technician, year_start, year_end,
            labels=list(_MONTH_LABELS),
        )

    return {
        'period': period,
        'total_jobs': sum(b['jobs'] for b in buckets),
        'total_cash': sum(b['cash'] for b in buckets),
        'buckets': buckets,
    }


def _day_label(day: date, today: date) -> str:
    """Use 'Today' for the last bar; otherwise the short weekday name."""
    if day == today:
        return 'Today'
    return _WEEK_LABELS[day.weekday()]


def _daily_buckets(technician, start_date, end_date, labels):
    """Daily aggregation over an inclusive date range. Backfills zeros."""
    rows = (
        JobBooking.objects
        .filter(
            technician=technician,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start__date__gte=start_date,
            scheduled_start__date__lte=end_date,
        )
        .annotate(day=TruncDate('scheduled_start'))
        .values('day')
        .annotate(jobs=Count('id'), cash=Sum('price_amount'))
        .order_by('day')
    )
    day_map = {r['day']: (r['jobs'], float(r['cash'] or 0)) for r in rows}

    num_days = (end_date - start_date).days + 1
    out = []
    for i in range(num_days):
        d = start_date + timedelta(days=i)
        jobs, cash = day_map.get(d, (0, 0.0))
        out.append({'label': labels[i], 'jobs': jobs, 'cash': cash})
    return out


def _monthly_buckets(technician, year_start, year_end, labels):
    """Monthly aggregation over an inclusive date range. Backfills zeros."""
    rows = (
        JobBooking.objects
        .filter(
            technician=technician,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start__date__gte=year_start,
            scheduled_start__date__lte=year_end,
        )
        .annotate(month=TruncMonth('scheduled_start'))
        .values('month')
        .annotate(jobs=Count('id'), cash=Sum('price_amount'))
        .order_by('month')
    )
    month_map = {
        r['month'].month: (r['jobs'], float(r['cash'] or 0))
        for r in rows
    }

    out = []
    for month_idx in range(1, 13):
        jobs, cash = month_map.get(month_idx, (0, 0.0))
        out.append({'label': labels[month_idx - 1], 'jobs': jobs, 'cash': cash})
    return out

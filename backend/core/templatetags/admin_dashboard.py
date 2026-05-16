"""Admin dashboard data — the KPI cards + activity feed on the index page.

One inclusion tag, queried fresh on every page-load (the dashboard is
admin-only and traffic is in the single digits per minute, so caching
would be premature). All queries are lock-free reads against indexed
columns.
"""
from __future__ import annotations

from datetime import datetime, time
from decimal import Decimal
from zoneinfo import ZoneInfo

from django import template
from django.db.models import Sum
from django.urls import reverse

register = template.Library()


# Pakistan-local "today" for the dashboard. The global TIME_ZONE is UTC
# (the DB host lacks tz tables — see settings.py), so we hardcode the
# product locale here. PKT has no DST so a fixed name is safe year-round.
_PKT = ZoneInfo('Asia/Karachi')


def _local_day_bounds():
    """Return (start_utc, end_utc) for ``today`` in Pakistan time.

    Computed in Python so the resulting query is a plain UTC-range filter
    on the DB — never invokes MySQL's ``CONVERT_TZ`` (which requires tz
    tables loaded on the host).
    """
    today_local = datetime.now(_PKT).date()
    start_local = datetime.combine(today_local, time.min, tzinfo=_PKT)
    end_local = datetime.combine(today_local, time.max, tzinfo=_PKT)
    return start_local.astimezone(ZoneInfo('UTC')), end_local.astimezone(ZoneInfo('UTC'))


def _local_now():
    """``now`` rendered in Pakistan time for the dashboard header."""
    return datetime.now(_PKT)


def _local_month_bounds():
    """(start_utc, end_utc) for the current calendar month in Pakistan time."""
    today_local = datetime.now(_PKT).date()
    month_start_local = datetime.combine(
        today_local.replace(day=1), time.min, tzinfo=_PKT,
    )
    # Roll forward one month to get an exclusive upper bound, then
    # subtract one microsecond for an inclusive __range filter.
    if today_local.month == 12:
        next_month_first = today_local.replace(year=today_local.year + 1, month=1, day=1)
    else:
        next_month_first = today_local.replace(month=today_local.month + 1, day=1)
    month_end_local = datetime.combine(next_month_first, time.min, tzinfo=_PKT)
    return (
        month_start_local.astimezone(ZoneInfo('UTC')),
        month_end_local.astimezone(ZoneInfo('UTC')),
    )


def _local_year_bounds():
    """(start_utc, end_utc) for the current calendar year in Pakistan time."""
    today_local = datetime.now(_PKT).date()
    year_start_local = datetime.combine(
        today_local.replace(month=1, day=1), time.min, tzinfo=_PKT,
    )
    next_year_first = today_local.replace(year=today_local.year + 1, month=1, day=1)
    year_end_local = datetime.combine(next_year_first, time.min, tzinfo=_PKT)
    return (
        year_start_local.astimezone(ZoneInfo('UTC')),
        year_end_local.astimezone(ZoneInfo('UTC')),
    )


@register.inclusion_tag('admin/_dashboard.html', takes_context=True)
def fx_admin_dashboard(context):
    """Render the KPI + activity dashboard block.

    Resilient to missing tables — if an app isn't migrated yet we
    silently skip its card rather than 500 the whole admin index.
    """
    from bookings.models import JobBooking, SupportTicket
    from technicians.models import TechnicianProfile
    from wallet.models import WithdrawalRequest, WithdrawalStatus

    now = _local_now()
    today_start_utc, today_end_utc = _local_day_bounds()

    kpis = []

    # Pending technician approvals
    try:
        pending_techs = TechnicianProfile.objects.filter(status='PENDING').count()
    except Exception:
        pending_techs = None
    if pending_techs is not None:
        kpis.append({
            'label': 'Pending tech approvals',
            'value': pending_techs,
            'sub': 'Awaiting your decision',
            'tone': 'attention' if pending_techs else 'primary',
            'url': reverse('admin:technicians_technicianprofile_changelist') + '?status__exact=PENDING',
        })

    # Open disputes
    try:
        open_disputes = SupportTicket.objects.filter(status='OPEN').count()
    except Exception:
        open_disputes = None
    if open_disputes is not None:
        kpis.append({
            'label': 'Open disputes',
            'value': open_disputes,
            'sub': 'Tickets awaiting resolution',
            'tone': 'danger' if open_disputes else 'primary',
            'url': reverse('admin:bookings_supportticket_changelist') + '?status__exact=OPEN',
        })

    # Pending withdrawals
    try:
        pending_withdrawals = WithdrawalRequest.objects.filter(
            status=WithdrawalStatus.PENDING_REVIEW,
        )
        pending_count = pending_withdrawals.count()
        pending_total = pending_withdrawals.aggregate(s=Sum('amount'))['s'] or Decimal('0')
    except Exception:
        pending_count = None
        pending_total = None
    if pending_count is not None:
        kpis.append({
            'label': 'Pending withdrawals',
            'value': pending_count,
            'sub': f'Rs. {int(pending_total):,} to disburse' if pending_total else 'No pending payouts',
            'tone': 'attention' if pending_count else 'primary',
            'url': reverse('admin:wallet_withdrawalrequest_changelist') + '?status__exact=PENDING_REVIEW',
        })

    # Today's bookings — Python-computed UTC range, so the DB query
    # never has to call CONVERT_TZ. Avoids the "tz tables not loaded"
    # failure mode on MySQL hosts without ``mysql_tzinfo_to_sql`` run.
    try:
        bookings_today = JobBooking.objects.filter(
            scheduled_start__range=(today_start_utc, today_end_utc),
        ).count()
    except Exception:
        bookings_today = None
    if bookings_today is not None:
        kpis.append({
            'label': "Today's bookings",
            'value': bookings_today,
            'sub': 'Scheduled for today',
            'tone': 'primary',
            'url': reverse('admin:bookings_jobbooking_changelist'),
        })

    # Active jobs (mid-job statuses)
    try:
        active_jobs = JobBooking.objects.filter(
            status__in=list(JobBooking.POST_ARRIVAL_STATUSES) + [JobBooking.STATUS_EN_ROUTE],
        ).count()
    except Exception:
        active_jobs = None
    if active_jobs is not None:
        kpis.append({
            'label': 'Active jobs',
            'value': active_jobs,
            'sub': 'En-route or on-site now',
            'tone': 'positive' if active_jobs else 'primary',
            'url': reverse('admin:bookings_jobbooking_changelist'),
        })

    # Techs online AND dispatchable (matchmaker requires lat/lng).
    # "Available to dispatch" must match the matchmaker's discovery filter
    # exactly, or this KPI overstates what the dispatch pipeline can see.
    try:
        online_techs = TechnicianProfile.objects.filter(
            status='APPROVED',
            is_online=True,
            is_active=True,
            base_latitude__isnull=False,
            base_longitude__isnull=False,
        ).count()
    except Exception:
        online_techs = None
    if online_techs is not None:
        kpis.append({
            'label': 'Technicians online',
            'value': online_techs,
            'sub': 'Available to dispatch',
            'tone': 'positive' if online_techs else 'attention',
            'url': reverse('admin:technicians_technicianprofile_changelist') + '?is_online__exact=1',
        })


    # -------------------------------------------------------------------
    # Finance tiles — only rendered for users in the ``finance_admin``
    # group (or superusers). Supervisor / engineer don't see them: the
    # numbers are platform revenue, not operations.
    # -------------------------------------------------------------------
    request = context.get('request')
    if request is not None:
        from core.common.admin_permissions import is_finance_admin
        if is_finance_admin(request.user):
            kpis.extend(_finance_kpis())

    return {
        'kpis': kpis,
        'now': now,
        'request': request,
    }


def _finance_kpis() -> list[dict]:
    """Build the four finance-only tiles.

    Resilient to missing tables / migrations — each tile is wrapped in
    its own ``try/except`` so a single failure can't take the dashboard
    down. The wallet ledger is the source of truth for commission;
    bookings are the source of truth for customer cash routed; the
    technician profile is the source of truth for current wallet
    liability.
    """
    from bookings.models import JobBooking
    from technicians.models import TechnicianProfile
    from wallet.models import TransactionType, WalletTransaction

    tiles: list[dict] = []
    month_start_utc, month_end_utc = _local_month_bounds()
    year_start_utc, year_end_utc = _local_year_bounds()

    # Deep-link URLs. Wrapped in ``try`` so a single missing reverse
    # never silently disables a whole tile — Django admin reverse can
    # raise NoReverseMatch if a target isn't registered.
    def _safe_reverse(name: str, query: str = '') -> str:
        try:
            return reverse(name) + query
        except Exception:
            return ''

    commission_url_month = _safe_reverse(
        'admin:wallet_wallettransaction_changelist',
        '?transaction_type__exact=COMMISSION_DEBIT',
    )
    commission_url_year = commission_url_month
    liability_url = _safe_reverse(
        'admin:technicians_technicianprofile_changelist',
        '?status__exact=APPROVED',
    )
    cash_routed_url = _safe_reverse(
        'admin:bookings_jobbooking_changelist',
        '?status__exact=COMPLETED',
    )

    # Commission rows are written as NEGATIVE amounts (debits from the
    # tech wallet). Sum will be ≤ 0; negate to display as positive
    # platform revenue.
    try:
        commission_month = (
            WalletTransaction.objects
            .filter(
                transaction_type=TransactionType.COMMISSION_DEBIT,
                timestamp__range=(month_start_utc, month_end_utc),
            )
            .aggregate(s=Sum('amount'))['s'] or Decimal('0')
        )
    except Exception:
        commission_month = None
    if commission_month is not None:
        tiles.append({
            'label': 'Commission this month',
            'value': f'Rs. {int(-commission_month):,}',
            'sub': 'Platform revenue',
            'tone': 'positive' if commission_month != 0 else 'primary',
            'url': commission_url_month,
        })

    try:
        commission_year = (
            WalletTransaction.objects
            .filter(
                transaction_type=TransactionType.COMMISSION_DEBIT,
                timestamp__range=(year_start_utc, year_end_utc),
            )
            .aggregate(s=Sum('amount'))['s'] or Decimal('0')
        )
    except Exception:
        commission_year = None
    if commission_year is not None:
        tiles.append({
            'label': 'Commission this year',
            'value': f'Rs. {int(-commission_year):,}',
            'sub': 'Year-to-date',
            'tone': 'positive' if commission_year != 0 else 'primary',
            'url': commission_url_year,
        })

    # Tech wallet liability — sum of positive balances across approved
    # techs. Negative balances are lockouts (the tech *owes* the
    # platform), not platform-side liability — exclude them.
    try:
        liability = (
            TechnicianProfile.objects
            .filter(status='APPROVED', current_wallet_balance__gt=0)
            .aggregate(s=Sum('current_wallet_balance'))['s'] or Decimal('0')
        )
    except Exception:
        liability = None
    if liability is not None:
        tiles.append({
            'label': 'Tech wallet liability',
            'value': f'Rs. {int(liability):,}',
            'sub': 'Total owed to technicians',
            'tone': 'attention' if liability else 'primary',
            'url': liability_url,
        })

    # Customer cash routed — total customer→tech cash through the
    # platform this month. Platform doesn't touch this money but it's
    # the headline marketplace volume figure.
    try:
        cash_routed = (
            JobBooking.objects
            .filter(cash_collected_at__range=(month_start_utc, month_end_utc))
            .aggregate(s=Sum('cash_collected_amount'))['s'] or Decimal('0')
        )
    except Exception:
        cash_routed = None
    if cash_routed is not None:
        tiles.append({
            'label': 'Customer cash routed (month)',
            'value': f'Rs. {int(cash_routed):,}',
            'sub': 'Gross marketplace volume',
            'tone': 'positive' if cash_routed else 'primary',
            'url': cash_routed_url,
        })

    return tiles

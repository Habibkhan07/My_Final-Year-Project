"""Dedicated selector for technician activity and earnings metrics.

Kept separate from dashboard_selector so each can evolve independently —
dashboard owns scheduling/availability data; metrics owns financial history.

Two queries per call:
  Q1 — Conditional aggregation on completed JobBookings this week.
       One DB round-trip covers both today and week totals.
  Q2 — WalletTransaction COMMISSION_DEBIT sum for today.
"""
from datetime import timedelta

from django.db.models import Count, Q, Sum
from django.utils import timezone

from bookings.models import JobBooking
from technicians.models import TechnicianProfile
from wallet.models import TransactionType, WalletTransaction


def get_technician_metrics(technician: TechnicianProfile) -> dict:
    """Return a metrics dict for the technician covering today and this ISO week.

    'This week' is Monday 00:00 → now (local server time via django.utils.timezone).
    Commission amounts are stored as negative values in the ledger; this function
    returns them as a positive figure so the UI can display 'Rs. 600 deducted'.
    """
    now = timezone.now()
    today = now.date()
    week_start = (now - timedelta(days=now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    ).date()

    # Q1: One conditional aggregation covers today + week in a single query.
    agg = JobBooking.objects.filter(
        technician=technician,
        status=JobBooking.STATUS_COMPLETED,
        scheduled_start__date__gte=week_start,
    ).aggregate(
        jobs_completed_this_week=Count('id'),
        cash_collected_this_week=Sum('price_amount'),
        jobs_completed_today=Count('id', filter=Q(scheduled_start__date=today)),
        cash_collected_today=Sum('price_amount', filter=Q(scheduled_start__date=today)),
    )

    # Q2: Platform commission deducted from the technician's wallet today.
    commission_agg = WalletTransaction.objects.filter(
        technician=technician,
        transaction_type=TransactionType.COMMISSION_DEBIT,
        timestamp__date=today,
    ).aggregate(total=Sum('amount'))

    return {
        'jobs_completed_today':      agg['jobs_completed_today'] or 0,
        'cash_collected_today':      float(agg['cash_collected_today'] or 0),
        'commission_deducted_today': float(abs(commission_agg['total'] or 0)),
        'jobs_completed_this_week':  agg['jobs_completed_this_week'] or 0,
        'cash_collected_this_week':  float(agg['cash_collected_this_week'] or 0),
    }

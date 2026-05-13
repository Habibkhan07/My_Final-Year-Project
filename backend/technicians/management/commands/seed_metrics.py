"""Seed historical COMPLETED bookings so the Metrics screen has data to chart.

Run:

    python manage.py seed_metrics

What it does
------------
1. Ensures the standard fixture (tech + customer + catalog) is present by
   calling ``seed_test_fixtures`` — same identities ``dev_panel`` uses, so
   the Chrome session already logged in as tech +923001111111 sees the new
   rows immediately on /technician/metrics.
2. Wipes any prior ``[seed_metrics]``-tagged bookings (re-runs are
   deterministic; no compounding cruft).
3. Inserts COMPLETED ``JobBooking`` rows across four time windows so all
   four bar-chart periods render non-zero bars:

       Today          → 3 bookings  (Rs 2 000 / 3 500 / 1 500)
       Last 6 days    → 1–2 bookings/day, Rs 1 500–4 000
       Days 7–29 ago  → ~1 booking every 3 days
       Prior 11 months of current year → 2–4 bookings/month

Identifier: every row carries ``price_context='[seed_metrics] …'`` so a
re-run can find and delete them with a single filter.

This command is dev-only. It will be removed in the end-of-UI cleanup pass.
"""
from __future__ import annotations

import random
from datetime import date, datetime, time, timedelta
from decimal import Decimal

from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.utils import timezone

from bookings.models import JobBooking
from catalog.models import Service
from technicians.models import TechnicianProfile


SEED_TAG = '[seed_metrics]'
TECH_PHONE = '+923001111111'

# Bound randomness so re-runs produce the same numbers — useful when
# comparing the bar chart before/after a frontend tweak.
_RNG = random.Random(20260513)


class Command(BaseCommand):
    help = 'Seed historical COMPLETED bookings so the Metrics tab has chart data.'

    def handle(self, *args, **opts):
        tech = self._ensure_tech()
        self._service = self._resolve_service()
        deleted = self._wipe_prior_seed(tech)
        if deleted:
            self.stdout.write(self.style.WARNING(f'  removed {deleted} prior [seed_metrics] row(s)'))

        created_today = self._seed_today(tech)
        created_last_6 = self._seed_last_6_days(tech)
        created_month = self._seed_days_7_to_29(tech)
        created_year = self._seed_prior_11_months(tech)

        total = created_today + created_last_6 + created_month + created_year
        self._print_summary(tech, total, created_today, created_last_6, created_month, created_year)

    # ---------------- fixture bootstrap ----------------

    def _ensure_tech(self) -> TechnicianProfile:
        """Return the seeded tech profile, bootstrapping fixtures if missing.

        The seed_test_fixtures command stores the phone in ``User.username``
        (it's the unifier across the auth + customer + tech rows), so that's
        what we look up by here.
        """
        try:
            return TechnicianProfile.objects.select_related('user').get(
                user__username=TECH_PHONE,
            )
        except TechnicianProfile.DoesNotExist:
            self.stdout.write('  No fixture tech found — running seed_test_fixtures first...')
            call_command('seed_test_fixtures', '--count=1', verbosity=0)
            return TechnicianProfile.objects.select_related('user').get(
                user__username=TECH_PHONE,
            )

    def _resolve_service(self) -> Service:
        """Pick the AC Repair service seed_test_fixtures created (or any first)."""
        svc = Service.objects.filter(name='AC Repair').first() or Service.objects.first()
        if svc is None:
            raise RuntimeError(
                'No catalog Service rows exist — seed_test_fixtures should have created one.'
            )
        return svc

    def _wipe_prior_seed(self, tech: TechnicianProfile) -> int:
        deleted, _ = JobBooking.objects.filter(
            technician=tech,
            price_context__startswith=SEED_TAG,
        ).delete()
        return deleted

    # ---------------- per-window seeders ----------------

    def _seed_today(self, tech: TechnicianProfile) -> int:
        today = timezone.localdate()
        prices = (Decimal('2000.00'), Decimal('3500.00'), Decimal('1500.00'))
        for i, price in enumerate(prices):
            self._create_completed(tech, today, price, slot=f'today-{i + 1}', hour=10 + i * 2)
        return len(prices)

    def _seed_last_6_days(self, tech: TechnicianProfile) -> int:
        today = timezone.localdate()
        n = 0
        for offset in range(1, 7):  # 1 through 6 days ago
            day = today - timedelta(days=offset)
            jobs_today = _RNG.choice([1, 1, 2])  # bias toward 1, sometimes 2
            for i in range(jobs_today):
                price = Decimal(_RNG.choice([1500, 2000, 2500, 3000, 3500, 4000]))
                self._create_completed(tech, day, price, slot=f'd-{offset}-{i + 1}', hour=10 + i * 3)
                n += 1
        return n

    def _seed_days_7_to_29(self, tech: TechnicianProfile) -> int:
        """Sparse coverage of the month-back window (~1 every 3 days)."""
        today = timezone.localdate()
        n = 0
        for offset in range(7, 30, 3):
            day = today - timedelta(days=offset)
            price = Decimal(_RNG.choice([1500, 2000, 2500, 3000, 4000, 5000]))
            self._create_completed(tech, day, price, slot=f'm-{offset}', hour=12)
            n += 1
        return n

    def _seed_prior_11_months(self, tech: TechnicianProfile) -> int:
        """For each month of current year before this month, drop 2–4 bookings."""
        today = timezone.localdate()
        n = 0
        for month_idx in range(1, today.month):
            jobs = _RNG.randint(2, 4)
            for i in range(jobs):
                # Pick a day inside that month — clamp to 28 to dodge Feb edge.
                day_of_month = _RNG.randint(1, 28)
                day = date(today.year, month_idx, day_of_month)
                price = Decimal(_RNG.choice([1500, 2000, 2500, 3000, 3500, 4000, 4500, 5500]))
                self._create_completed(tech, day, price, slot=f'y-{month_idx:02d}-{i + 1}', hour=10 + i * 2)
                n += 1
        return n

    # ---------------- row factory ----------------

    def _create_completed(
        self,
        tech: TechnicianProfile,
        on_day: date,
        price: Decimal,
        *,
        slot: str,
        hour: int,
    ) -> JobBooking:
        """Create one COMPLETED booking with a deterministic mid-day timestamp.

        The mid-day anchor (10:00–18:00 local) keeps the row safely inside
        ``scheduled_start.date()`` regardless of TZ skew, so the selector's
        ``TruncDate`` buckets land in the bar we intended.
        """
        local_dt = datetime.combine(on_day, time(hour=hour, minute=0))
        tz_aware = timezone.make_aware(local_dt, timezone.get_current_timezone())
        # SECURITY: writes only target the fixture tech; no user-input fields.
        return JobBooking.objects.create(
            technician=tech,
            customer=self._fixture_customer(),
            address=None,
            service=self._service,
            sub_service=None,
            scheduled_start=tz_aware,
            scheduled_end=tz_aware + timedelta(hours=1),
            status=JobBooking.STATUS_COMPLETED,
            price_amount=price,
            price_context=f'{SEED_TAG} {slot}',
            accepted_at=tz_aware,
            en_route_started_at=tz_aware,
            arrived_at=tz_aware,
            inspection_started_at=tz_aware,
            quote_first_submitted_at=tz_aware,
            work_started_at=tz_aware,
            completed_at=tz_aware + timedelta(hours=1),
            cash_collected_amount=price,
            cash_collected_at=tz_aware + timedelta(hours=1),
        )

    def _fixture_customer(self):
        """Resolve the seeded fixture customer once per command run."""
        if not hasattr(self, '_cust_cache'):
            from django.contrib.auth import get_user_model

            User = get_user_model()
            self._cust_cache = User.objects.get(username='+923002222222')
        return self._cust_cache

    # ---------------- summary ----------------

    def _print_summary(self, tech, total, today_n, last6_n, month_n, year_n):
        bar = '=' * 64
        s = self.style.SUCCESS
        self.stdout.write('')
        self.stdout.write(s(bar))
        self.stdout.write(s('  METRICS TEST DATA SEEDED'))
        self.stdout.write(s(bar))
        self.stdout.write(f'  Tech            : {TECH_PHONE} (id={tech.id})')
        self.stdout.write(f'  Today           : {today_n} bookings')
        self.stdout.write(f'  Last 6 days     : {last6_n} bookings')
        self.stdout.write(f'  Days 7–29 ago   : {month_n} bookings')
        self.stdout.write(f'  Prior 11 months : {year_n} bookings')
        self.stdout.write(s(f'  Total seeded    : {total} COMPLETED rows'))
        self.stdout.write('')
        self.stdout.write('  In the app: Bottom nav → Metrics. Toggle Day / Week / Month / Year.')
        self.stdout.write('  Re-run this command any time to reset the seed.')
        self.stdout.write(s(bar))
        self.stdout.write('')

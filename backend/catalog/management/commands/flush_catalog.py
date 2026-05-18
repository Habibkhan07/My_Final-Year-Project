"""
Destructive reset of the catalog + everything that references it.

Wipes Service, SubService, Promotion, and all rows that hold PROTECT FKs
into the catalog (BookingItem, QuoteLineItem) so a fresh `seed_demo` run
can re-populate from scratch without IntegrityError.

Cascade map (verified against models, 2026-05-18):
  JobBooking.delete()
    → Quote          (CASCADE)         → QuoteLineItem (CASCADE → SubService PROTECT cleared)
    → BookingItem    (CASCADE → SubService PROTECT cleared)
  Promotion.delete() (target_service is SET_NULL; safe standalone)
  Service.delete()
    → SubService                  (CASCADE)
    → TechnicianSkill             (CASCADE via SubService)
    → TechnicianServicePerformance(CASCADE)
    → TechnicianServiceLicense    (CASCADE)

Run:  python manage.py flush_catalog
Then: python manage.py seed_demo
"""
from django.core.management.base import BaseCommand
from django.db import transaction

from bookings.models import JobBooking
from catalog.models import Service, SubService
from marketing.models import Promotion


class Command(BaseCommand):
    help = 'Hard-wipes catalog + all dependent rows. Run before `seed_demo` for a clean reset.'

    @transaction.atomic
    def handle(self, *args, **opts):
        self.stdout.write(self.style.MIGRATE_HEADING('Flushing catalog + dependents...'))

        # 1. Bookings first — cascades Quote, QuoteLineItem, BookingItem
        #    which hold the PROTECT FKs into SubService.
        n_bookings = JobBooking.objects.count()
        JobBooking.objects.all().delete()

        # 2. Promotions — target_service is SET_NULL but we want a clean slate.
        n_promos = Promotion.objects.count()
        Promotion.objects.all().delete()

        # 3. Catalog — cascades SubService and all technician_* bridge rows.
        n_subs = SubService.objects.count()
        n_svcs = Service.objects.count()
        Service.objects.all().delete()

        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(self.style.SUCCESS('  CATALOG FLUSH COMPLETE'))
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(f'  JobBookings deleted   : {n_bookings}')
        self.stdout.write(f'  Promotions deleted    : {n_promos}')
        self.stdout.write(f'  SubServices deleted   : {n_subs}')
        self.stdout.write(f'  Services deleted      : {n_svcs}')
        self.stdout.write('')
        self.stdout.write('  Next step: python manage.py seed_demo')
        self.stdout.write(self.style.SUCCESS('=' * 60))

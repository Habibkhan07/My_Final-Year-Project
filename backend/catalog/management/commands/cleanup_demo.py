"""
Soft-deletes legacy dev seed data so thesis screenshots show only the
Pakistani demo set produced by `seed_demo`.

Default run hides:
  - Service "General Maintenance" (no icon, would render first with fallback)
  - SubService "General Plumbing Repair" (legacy labor gig)
  - 9 technician profiles created by the old `seed_test_data.py`
    (TechA_Veteran .. TechH_Boundary plus "Test Technician")

Reversible:  python manage.py cleanup_demo --restore
"""
from django.core.management.base import BaseCommand
from django.db import transaction

from catalog.models import Service, SubService
from technicians.models import TechnicianProfile


LEGACY_SERVICE_NAMES = ['General Maintenance']
LEGACY_GIG_NAMES = ['General Plumbing Repair']
LEGACY_TECH_USERNAMES = [
    'techa_veteran', 'techb_rookie', 'techc_close', 'techd_plumber',
    'teche_zeroreviews', 'techf_suspended', 'techg_ghost', 'techh_boundary',
    'test_technician',
    '+923001234567',  # Real OTP-flow account "Test Technician" — hide for thesis screenshots
]


class Command(BaseCommand):
    help = 'Soft-hides legacy dev seed data (TechA_Veteran etc) so thesis screenshots are clean.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--restore', action='store_true',
            help='Re-enable previously hidden rows (sets flags back to active/featured).',
        )

    @transaction.atomic
    def handle(self, *args, **opts):
        target = opts['restore']  # True = restore visible, False = hide
        verb = 'Restoring' if target else 'Hiding'

        n_svc = Service.objects.filter(
            name__in=LEGACY_SERVICE_NAMES,
        ).update(is_active=target)

        n_gig = SubService.objects.filter(
            name__in=LEGACY_GIG_NAMES,
        ).update(is_featured=target)

        n_tech = TechnicianProfile.objects.filter(
            user__username__in=LEGACY_TECH_USERNAMES,
        ).update(is_active=target)

        self.stdout.write(self.style.MIGRATE_HEADING(f'{verb} legacy seed data...'))
        self.stdout.write(f'  Services hidden       : {n_svc}')
        self.stdout.write(f'  Gigs unfeatured       : {n_gig}')
        self.stdout.write(f'  Technicians hidden    : {n_tech}')
        if not target and (n_svc + n_gig + n_tech) == 0:
            self.stdout.write(self.style.WARNING('  Nothing matched — already cleaned, or DB has different names.'))
        self.stdout.write(self.style.SUCCESS('Done.'))

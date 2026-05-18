"""Seed a technician into a specific online-toggle scenario.

Drives the four states the new `POST /api/technicians/me/online/`
endpoint differentiates so you can exercise each one from the phone
without poking the DB by hand.

Run
---

    python manage.py seed_online_toggle --scenario unlocked
    python manage.py seed_online_toggle --scenario locked
    python manage.py seed_online_toggle --scenario suspended
    python manage.py seed_online_toggle --scenario pending

What it does
------------

Each scenario reuses the standard fixture's tech identity
(`+923001111111`) so the OTP login flow on the phone is unchanged
(DEBUG=True → OTP code is fixed to **123456**). After the command:

  * The tech is logged in via phone OTP on the device.
  * The dashboard top bar shows the OFFLINE pill.
  * Tapping ONLINE exercises the endpoint and lands on the expected
    success or refusal path.

Scenarios
---------

  unlocked    balance = +500, is_active=True,  status=APPROVED, is_online=False
              → tap ONLINE → 200, pill flips to ONLINE, server log shows POST.

  locked      balance = -100, is_active=True,  status=APPROVED, is_online=False
              → tap ONLINE → 403 wallet_lockout, snackbar reads
                "Top up your wallet to go online", pill stays OFFLINE.

  suspended   balance = +500, is_active=False, status=APPROVED, is_online=False
              → tap ONLINE → 403 permission_denied, snackbar reads
                "Status update failed. Please try again.", pill stays OFFLINE.

  pending     balance = +500, is_active=True,  status=PENDING,  is_online=False
              → tap ONLINE → 403 permission_denied. In practice the
                router gates PENDING techs to the pending screen so the
                dashboard isn't reached; this scenario exists for the
                backend test surface, not a typical UI flow.

Idempotent: re-running the same scenario zeroes any prior
`seed_online_toggle:` ledger rows, then replays one adjustment row to
land on the target balance. Switching scenarios is a one-liner.
"""
from __future__ import annotations

import io
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from django.db import transaction
from PIL import Image

from accounts.models import UserProfile
from technicians.models import TechnicianProfile
from wallet.models import TransactionType, WalletTransaction
from wallet.services.ledger import record_transaction

User = get_user_model()

TECH_PHONE = '+923001111111'
OTP_DEV_CODE = '123456'

SCENARIOS = {
    'unlocked': {
        'target_balance': Decimal('500.00'),
        'is_active': True,
        'status': 'APPROVED',
        'is_online': False,
        'expected_outcome': 'tap ONLINE → 200, pill flips to ONLINE',
    },
    'locked': {
        'target_balance': Decimal('-100.00'),
        'is_active': True,
        'status': 'APPROVED',
        'is_online': False,
        'expected_outcome': (
            'tap ONLINE → 403 wallet_lockout, snackbar: '
            '"Top up your wallet to go online"'
        ),
    },
    'suspended': {
        'target_balance': Decimal('500.00'),
        'is_active': False,
        'status': 'APPROVED',
        'is_online': False,
        'expected_outcome': (
            'tap ONLINE → 403 permission_denied (admin-suspended)'
        ),
    },
    'pending': {
        'target_balance': Decimal('500.00'),
        'is_active': True,
        'status': 'PENDING',
        'is_online': False,
        'expected_outcome': (
            'tap ONLINE → 403 permission_denied (status not APPROVED). '
            'NOTE: router normally routes PENDING techs away from the '
            'dashboard — this scenario is for backend testing only.'
        ),
    },
}

# Reference key — every adjustment row written by this command carries
# this prefix so a re-run can wipe + replay deterministically without
# touching unrelated seeded rows.
LEDGER_KEY_PREFIX = 'seed_online_toggle:'


class Command(BaseCommand):
    help = 'Seed the standard test tech into one of four online-toggle scenarios.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--scenario',
            type=str,
            required=True,
            choices=sorted(SCENARIOS.keys()),
            help='Which online-toggle state to land the tech in.',
        )

    @transaction.atomic
    def handle(self, *args, **options):
        scenario = options['scenario']
        spec = SCENARIOS[scenario]

        # 1. Ensure the tech identity exists. Self-contained — does
        # NOT call seed_test_fixtures (which can fail on dev DBs that
        # have stale duplicate CustomerAddress rows). Only touches the
        # rows this command needs: User, UserProfile, TechnicianProfile.
        self.stdout.write('-> Ensuring tech identity...')
        tech = self._ensure_tech()

        # 2. Wipe any prior seed_online_toggle ledger rows so re-runs
        # are deterministic. We do NOT touch other ledger rows on this
        # tech — production-shape balances from seed_wallet or real
        # bookings stay intact.
        prior_rows = WalletTransaction.objects.filter(
            technician=tech,
            transaction_reference_number__startswith=LEDGER_KEY_PREFIX,
        )
        rolled_back = Decimal('0')
        for row in prior_rows:
            rolled_back += row.amount
        prior_count = prior_rows.count()
        prior_rows.delete()

        # 3. Snap the denormalized balance back to where it was BEFORE
        # any prior seed runs, so the upcoming adjustment lands on a
        # known starting point. Bypasses the ledger because we want a
        # known-clean state — the next step writes the forensic row.
        tech.current_wallet_balance = tech.current_wallet_balance - rolled_back
        tech.save(update_fields=['current_wallet_balance'])

        # 4. Compute the delta needed to reach the target balance, then
        # write ONE adjustment row via the ledger so the audit
        # invariant (MAX(balance_after) == current_wallet_balance) is
        # preserved.
        delta = spec['target_balance'] - tech.current_wallet_balance
        if delta != Decimal('0'):
            record_transaction(
                technician=tech,
                transaction_type=TransactionType.ADJUSTMENT,
                amount=delta,
                transaction_reference_number=(
                    f'{LEDGER_KEY_PREFIX}{scenario}'
                ),
                is_manual_adjustment=True,
                memo=(
                    f'seed_online_toggle scenario={scenario} '
                    f'target_balance={spec["target_balance"]}'
                ),
            )
            # ledger may have auto-offlined if we crossed into negative.
            # Re-fetch so the column writes below operate on the latest.
            tech.refresh_from_db()

        # 5. Set the scenario-specific gating columns. We do this AFTER
        # the ledger write because record_transaction's auto-offline
        # rule might have flipped is_online itself — our scenario
        # spec is the source of truth here.
        tech.is_active = spec['is_active']
        tech.status = spec['status']
        tech.is_online = spec['is_online']
        # REJECTED carries an invariant (reason required); we never
        # land on REJECTED here so the field stays untouched.
        tech.save(update_fields=['is_active', 'status', 'is_online'])

        # 6. Report.
        self.stdout.write(self.style.SUCCESS('\n=== READY ==='))
        self.stdout.write(
            f'  Scenario          : {self.style.WARNING(scenario)}'
        )
        self.stdout.write(f'  Phone             : {TECH_PHONE}')
        self.stdout.write(
            f'  OTP (DEBUG fixed) : {self.style.WARNING(OTP_DEV_CODE)}'
        )
        self.stdout.write(f'  Wallet balance    : Rs. {tech.current_wallet_balance}')
        self.stdout.write(f'  is_active         : {tech.is_active}')
        self.stdout.write(f'  status            : {tech.status}')
        self.stdout.write(f'  is_online         : {tech.is_online}')
        if prior_count:
            self.stdout.write(
                f'  (rolled back {prior_count} prior seed_online_toggle rows)'
            )
        self.stdout.write(f"\n  Expected on tap   : {spec['expected_outcome']}")
        self.stdout.write(
            '\nLog in on the phone with the number above, OTP 123456, '
            'open the tech dashboard, and tap the OFFLINE pill.'
        )

    def _ensure_tech(self) -> TechnicianProfile:
        """Get-or-create User + UserProfile + TechnicianProfile for the
        standard test phone. Idempotent across runs."""
        user, created_user = User.objects.get_or_create(
            username=TECH_PHONE,
            defaults={'first_name': 'Test', 'last_name': 'Technician'},
        )
        if created_user:
            user.set_password('password123')
            user.save()

        UserProfile.objects.get_or_create(
            user=user,
            defaults={'phone': TECH_PHONE, 'is_technician': True},
        )

        tech, created_tech = TechnicianProfile.objects.get_or_create(
            user=user,
            defaults={
                # Demo-journey location: Lahore Gulberg II, ~1.5 km north
                # of the customer's Liberty Market pin seeded by
                # `seed_test_fixtures`. Both seeders run during
                # `demo_journey.sh` (this one first via `get_or_create`),
                # so the coords MUST agree or the tech ends up in the
                # wrong city for the demo. Keep these two files in lockstep:
                #   - technicians/.../seed_online_toggle.py  (this file)
                #   - bookings/.../seed_test_fixtures.py     (TECH_BASE_LAT/LNG)
                'city': 'LHR',
                'cnic_number': '35202-1111111-1',
                'status': 'APPROVED',
                'base_latitude': 31.5230,
                'base_longitude': 74.3478,
                'is_onboarding_complete': True,
                'is_active': True,
                'rating_average': Decimal('4.80'),
                'review_count': 50,
                'max_travel_radius_km': 10,
            },
        )
        if created_tech:
            # Required ImageField columns — tiny placeholder JPEG.
            placeholder = ContentFile(_tiny_jpeg(), name='placeholder.jpg')
            tech.profile_picture.save(
                'tech_pp.jpg', placeholder, save=False,
            )
            tech.cnic_front_image.save(
                'tech_cnic.jpg', placeholder, save=False,
            )
            tech.save()

        # Re-fetch under select_for_update so the upcoming ledger
        # write + column patches operate under the same row lock
        # the production setOnline endpoint uses.
        return TechnicianProfile.objects.select_for_update().get(pk=tech.pk)


def _tiny_jpeg() -> bytes:
    """1x1 placeholder JPEG bytes (mirrors seed_test_fixtures._tiny_jpeg)."""
    img = Image.new('RGB', (1, 1), color='white')
    buf = io.BytesIO()
    img.save(buf, format='JPEG')
    return buf.getvalue()

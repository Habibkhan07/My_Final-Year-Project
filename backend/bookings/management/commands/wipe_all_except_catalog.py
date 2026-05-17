"""Reset everything except the catalog (Service / SubService).

Wipes ALL user data, addresses, bookings, wallet ledger, technician
profiles, customer profiles, tokens, and non-superuser users so the
next ``seed_test_fixtures`` run produces a truly fresh fixture state.

Why this command exists separately from ``wipe_bookings``:
``wipe_bookings`` only drops JobBooking rows + their direct dependents.
User accounts and CustomerAddress rows survive — and ``seed_test_fixtures``
uses ``get_or_create(...defaults=...)``, which silently keeps any
existing first_name/last_name/address on already-created rows. The net
effect: a user who edited their profile to "Hamayon Khan" from
"Test Customer" via the app keeps that name forever, and a customer who
added a Muslim-Town home address through the in-app picker keeps that
address forever — even though seed_test_fixtures "wrote" Gulberg coords.
This command nukes the surviving rows so the next seed truly starts from
zero.

The catalog app is preserved so seed_test_fixtures doesn't need to
rebuild Service / SubService rows on each run.

User preservation rules:
  * Default: every ``is_superuser=True`` row is preserved so /admin
    stays reachable.
  * ``--keep-username NAME [NAME ...]``: preserve ONLY these usernames
    (overrides the default — useful when you want exactly one admin
    surviving the wipe instead of every superuser).
  * ``--all-users``: nuke everything including admins. Overrides both
    of the above.

Usage:
  python manage.py wipe_all_except_catalog                          # preserves all superusers
  python manage.py wipe_all_except_catalog --keep-username hamayon  # preserves only `hamayon`
  python manage.py wipe_all_except_catalog --all-users              # nukes everything

Deletion order matters because the wallet ledger uses PROTECT FKs
everywhere — see inline comments at each step.
"""
from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.db import transaction
from rest_framework.authtoken.models import Token

from accounts.models import UserProfile
from chatbot.models import Attachment as ChatAttachment
from chatbot.models import Conversation, DailyLlmCallQuota, Message
from customers.models import CustomerAddress, CustomerProfile
from disputes.models import RefundIntent
from realtime.models.devices import FCMDevice
from technicians.models import (
    Review,
    TechnicianProfile,
    TechnicianSchedule,
    TechnicianServiceLicense,
    TechnicianServicePerformance,
    TechnicianSkill,
    TemporaryMedia,
)
from wallet.models import (
    RefundDeduction,
    TechnicianBankAccount,
    TechnicianJazzCashAccount,
    WalletTopup,
    WalletTransaction,
    WithdrawalFulfilment,
    WithdrawalRequest,
)


class Command(BaseCommand):
    help = (
        'Wipe ALL data except the catalog app (Service / SubService). '
        'Preserves superusers by default; pass --all-users to drop them too.'
    )

    def add_arguments(self, parser):
        parser.add_argument(
            '--all-users',
            action='store_true',
            help='Also delete superusers (default: preserve for /admin access).',
        )
        parser.add_argument(
            '--keep-username',
            nargs='+',
            default=None,
            metavar='USERNAME',
            help=(
                'Preserve ONLY these usernames (overrides the default '
                '"preserve all superusers" rule). Repeat or space-separate '
                'to keep multiple. Ignored if --all-users is set.'
            ),
        )

    @transaction.atomic
    def handle(self, *args, **opts):
        User = get_user_model()
        wipe_all = opts['all_users']
        keep_usernames = opts['keep_username']

        # 1. Bookings + direct dependents (BookingItem PROTECTs Quote;
        #    JobCommission PROTECTs JobBooking). The booking cascade also
        #    clears Quote, QuoteLineItem, SupportTicket, Attachment,
        #    EventLog rows that reference the booking.
        call_command('wipe_bookings', verbosity=0)

        # 2. Wallet ledger — every FK is PROTECT. The subtype rows
        #    (WalletTopup, RefundDeduction) hold PROTECT OneToOne FKs back
        #    to WalletTransaction, so subtypes go FIRST, then transactions.
        #    Withdrawals → topups → refund deductions → bank accounts →
        #    transactions.
        WithdrawalFulfilment.objects.all().delete()
        WithdrawalRequest.objects.all().delete()
        WalletTopup.objects.all().delete()
        RefundDeduction.objects.all().delete()
        TechnicianBankAccount.objects.all().delete()
        TechnicianJazzCashAccount.objects.all().delete()
        # JobCommission was already cleared by wipe_bookings. Now the
        # WalletTransaction table is free of incoming PROTECT FKs.
        WalletTransaction.objects.all().delete()

        # 3. Chatbot. Attachment FKs to Message + Conversation are CASCADE,
        #    but explicit ordering keeps the SQL predictable.
        ChatAttachment.objects.all().delete()
        Message.objects.all().delete()
        Conversation.objects.all().delete()
        DailyLlmCallQuota.objects.all().delete()

        # 4. Disputes. RefundIntent.ticket FK CASCADEs from SupportTicket,
        #    which was already cleared by wipe_bookings — but defensively
        #    catch any orphan rows.
        RefundIntent.objects.all().delete()

        # 5. Technician sub-rows then profile. All sub-row FKs to
        #    TechnicianProfile are CASCADE, so TechnicianProfile.delete()
        #    would also clear them — but the wallet rows above already
        #    cleared the PROTECT FKs into TechnicianProfile, so deleting
        #    the profile itself is now safe.
        TechnicianSkill.objects.all().delete()
        TechnicianServiceLicense.objects.all().delete()
        TechnicianServicePerformance.objects.all().delete()
        TechnicianSchedule.objects.all().delete()
        Review.objects.all().delete()
        TemporaryMedia.objects.all().delete()
        TechnicianProfile.objects.all().delete()

        # 6. Customer rows. CASCADE from User, but explicit so the wipe is
        #    visible in --verbosity logs.
        CustomerAddress.objects.all().delete()
        CustomerProfile.objects.all().delete()

        # 7. accounts.UserProfile (CASCADE on User).
        UserProfile.objects.all().delete()

        # 8. FCM device tokens (CASCADE on User).
        FCMDevice.objects.all().delete()

        # 9. DRF auth tokens.
        Token.objects.all().delete()

        # 10. Users. Final step — every FK that could PROTECT against the
        #     User delete has been cleared above.
        user_qs = User.objects.all()
        if wipe_all:
            preserved_label = 'all users including superusers wiped'
        elif keep_usernames:
            # Explicit allow-list overrides the default superuser rule.
            user_qs = user_qs.exclude(username__in=keep_usernames)
            preserved_label = (
                f'preserved usernames: {", ".join(sorted(keep_usernames))}'
            )
        else:
            user_qs = user_qs.exclude(is_superuser=True)
            preserved_label = 'all superusers preserved'
        user_count, _ = user_qs.delete()

        msg = (
            f'Wiped non-catalog data. {user_count} User row(s) deleted; '
            f'{preserved_label}.'
        )
        self.stdout.write(self.style.SUCCESS(msg))

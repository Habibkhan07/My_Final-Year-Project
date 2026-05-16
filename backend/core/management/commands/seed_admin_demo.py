"""Populate the admin with end-to-end fixture data.

Run with ``python manage.py seed_admin_demo``. Idempotent — uses
``get_or_create`` on usernames so re-runs only top up missing rows.

What it creates (when missing):
  * 2 customers + saved addresses
  * 3 technicians: one PENDING (so Approve/Reject buttons light up),
    one APPROVED & online, one REJECTED (with a rejection reason)
  * Catalog: 2 services + a couple of sub-services (only if catalog is
    empty — existing rows are left alone)
  * 1 active Promotion
  * 3 bookings: one CONFIRMED upcoming, one COMPLETED with cash, one
    DISPUTED with both photo evidence and a chatbot-style chat_log
  * 1 PENDING_REVIEW withdrawal (so the wallet finance flow has a row)
  * Sample wallet transactions (commission + topup) on the approved tech
  * Sample EventLog entries on the dashboard's recent-events feed
"""
from __future__ import annotations

import io
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

User = get_user_model()


def _make_image_bytes(label: str, color: tuple[int, int, int]) -> bytes:
    """Generate a labelled placeholder PNG without Pillow dependencies.

    Falls back to a tiny solid-color PNG via Pillow if available;
    otherwise emits a minimal valid PNG header so admin form
    validation passes. Keeps the seed runnable on hosts without
    image libs.
    """
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        # 1x1 transparent PNG bytes.
        return bytes.fromhex(
            '89504e470d0a1a0a0000000d49484452000000010000000108060000001f'
            '15c4890000000d49444154789c63f80f00010101003ef8a0900000000049'
            '454e44ae426082'
        )

    img = Image.new('RGB', (320, 200), color)
    drawer = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:
        font = None
    drawer.text((16, 80), label, fill=(255, 255, 255), font=font)
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return buf.getvalue()


def _image_file(name: str, label: str, color: tuple[int, int, int]) -> ContentFile:
    return ContentFile(_make_image_bytes(label, color), name=name)


class Command(BaseCommand):
    help = 'Seed the admin with end-to-end fixture data for evaluating the operations console.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--wipe-disputes',
            action='store_true',
            help='Delete existing demo disputes and recreate them.',
        )

    @transaction.atomic
    def handle(self, *args, **opts):
        self.stdout.write(self.style.HTTP_INFO('Seeding admin demo data…'))
        catalog = self._seed_catalog()
        promotion = self._seed_promotion(catalog['service_ac'])
        customers = self._seed_customers()
        technicians = self._seed_technicians(catalog)
        bookings = self._seed_bookings(
            customers, technicians, catalog,
        )
        self._seed_disputes(bookings, customers, technicians, opts['wipe_disputes'])
        self._seed_withdrawal(technicians['approved'])
        self._seed_wallet_transactions(technicians['approved'])
        self._seed_events(customers, technicians)
        self._seed_role_users()
        self.stdout.write(self.style.SUCCESS(
            '\nFixture data ready. Log into /admin/ as a superuser:\n'
            '  * People → Technicians: 1 PENDING (Approve / Reject buttons live)\n'
            '  * Operations → Support Tickets: 1 OPEN dispute with photo evidence\n'
            '  * Operations → Withdrawal Requests: 1 PENDING_REVIEW\n'
            '  * Catalog → Promotions: 1 active campaign on AC Service\n'
            '  * Dashboard KPIs reflect the new rows.\n'
            '\nRole-based staff accounts (separation-of-duties demo):\n'
            '  * supervisor / supervisor123  — Operations + Catalog + People\n'
            '  * finance    / finance123     — adds Withdrawals + IBANs + unredacted chat_log\n'
            '  * engineer   / engineer123    — adds Refund intents + Conversations\n'
        ))

    # ---- staff role users --------------------------------------------------

    def _seed_role_users(self) -> None:
        """Create three non-superuser staff accounts wired to role groups.

        Each user is ``is_staff=True`` (admin login allowed) and
        ``is_superuser=False`` (permission checks actually apply). Group
        memberships are additive: finance and engineer also belong to
        ``supervisor`` so they inherit the operations-level views on top
        of their role-specific surfaces.
        """
        from django.contrib.auth.models import Group

        User = get_user_model()

        def _ensure_staff(username: str, password: str, *, first: str,
                          group_names: list[str]) -> None:
            user, created = User.objects.get_or_create(
                username=username,
                defaults={
                    'first_name': first,
                    'is_staff': True,
                    'is_active': True,
                    'is_superuser': False,
                },
            )
            if created or not user.has_usable_password():
                user.set_password(password)
            # Normalize flags on every run — a re-run shouldn't
            # silently leave is_staff=False if someone toggled it.
            user.is_staff = True
            user.is_active = True
            user.is_superuser = False
            user.first_name = user.first_name or first
            user.save()

            current = set(user.groups.values_list('name', flat=True))
            desired = set(group_names)
            if current != desired:
                user.groups.set(Group.objects.filter(name__in=group_names))

        _ensure_staff(
            'supervisor', 'supervisor123', first='Supervisor',
            group_names=['supervisor'],
        )
        _ensure_staff(
            'finance', 'finance123', first='Finance',
            group_names=['supervisor', 'finance_admin'],
        )
        _ensure_staff(
            'engineer', 'engineer123', first='Engineer',
            group_names=['supervisor', 'engineer'],
        )

    # ---- catalog -----------------------------------------------------------

    def _seed_catalog(self) -> dict:
        from catalog.models import Service, SubService

        svc_ac, _ = Service.objects.get_or_create(
            name='AC Service',
            defaults={
                'icon_name': 'ac_repair',
                'display_order': 10,
                'is_active': True,
                'base_inspection_fee': Decimal('500.00'),
            },
        )
        svc_plumb, _ = Service.objects.get_or_create(
            name='Plumbing',
            defaults={
                'icon_name': 'plumbing',
                'display_order': 20,
                'is_active': True,
                'base_inspection_fee': Decimal('500.00'),
            },
        )

        sub_ac_wash, _ = SubService.objects.get_or_create(
            service=svc_ac,
            name='AC General Wash',
            defaults={
                'base_price': Decimal('1500.00'),
                'is_fixed_price': True,
                'is_featured': True,
                'icon_name': 'ac_repair',
                'search_tags': ['ac', 'cleaning', 'wash', 'service'],
                'estimated_duration_minutes': 90,
            },
        )
        sub_pipe, _ = SubService.objects.get_or_create(
            service=svc_plumb,
            name='Pipe Leak Repair',
            defaults={
                'base_price': Decimal('800.00'),
                'max_price': Decimal('2000.00'),
                'is_fixed_price': False,
                'is_featured': False,
                'icon_name': 'pipe_leak',
                'search_tags': ['pani', 'leak', 'pipe', 'drip'],
                'estimated_duration_minutes': 60,
            },
        )
        return {
            'service_ac': svc_ac,
            'service_plumb': svc_plumb,
            'sub_ac_wash': sub_ac_wash,
            'sub_pipe': sub_pipe,
        }

    def _seed_promotion(self, service_ac):
        from marketing.models import Promotion

        promo, created = Promotion.objects.get_or_create(
            name='Eid AC Special',
            defaults={
                'description': 'Get 20% OFF the total bill for AC Service!',
                'discount_type': Promotion.DiscountType.PERCENTAGE,
                'discount_value': Decimal('20'),
                'target_service': service_ac,
                'funded_by': Promotion.FundingSource.PLATFORM,
                'valid_from': timezone.now() - timezone.timedelta(days=1),
                'valid_until': timezone.now() + timezone.timedelta(days=7),
                'is_active': True,
                'is_featured_on_home': True,
            },
        )
        if created and not promo.image:
            promo.image.save(
                'eid_ac.png',
                _image_file('eid_ac.png', 'EID AC 20% OFF', (220, 38, 38)),
                save=True,
            )
        return promo

    # ---- customers ---------------------------------------------------------

    def _seed_customers(self) -> dict:
        from accounts.models import UserProfile
        from customers.models import CustomerAddress, CustomerProfile

        def _make(username: str, phone: str, full: str) -> CustomerProfile:
            user, _ = User.objects.get_or_create(
                username=phone,
                defaults={
                    'first_name': full.split()[0],
                    'last_name': full.split()[-1] if ' ' in full else '',
                },
            )
            UserProfile.objects.get_or_create(
                user=user, defaults={'phone': phone, 'is_technician': False},
            )
            profile, _ = CustomerProfile.objects.get_or_create(user=user)
            CustomerAddress.objects.get_or_create(
                customer=profile,
                label='Home',
                defaults={
                    'street_address': 'House 12, Gulberg III, Lahore',
                    'latitude': Decimal('31.520400'),
                    'longitude': Decimal('74.358700'),
                    'is_default': True,
                    'city': 'Lahore', 'state': 'Punjab', 'country': 'PK',
                    'locality_label': 'Gulberg, Lahore',
                },
            )
            return profile

        return {
            'sara': _make('+923211000001', '+923211000001', 'Sara Khan'),
            'ahmed': _make('+923211000002', '+923211000002', 'Ahmed Ali'),
        }

    # ---- technicians -------------------------------------------------------

    def _seed_technicians(self, catalog) -> dict:
        from accounts.models import UserProfile
        from technicians.models import (
            TechnicianProfile, TechnicianServiceLicense, TechnicianSkill,
        )

        def _make(username, phone, full, status, with_images=True, *, rejection=''):
            user, _ = User.objects.get_or_create(
                username=phone,
                defaults={
                    'first_name': full.split()[0],
                    'last_name': full.split()[-1] if ' ' in full else '',
                },
            )
            UserProfile.objects.get_or_create(
                user=user, defaults={'phone': phone, 'is_technician': True},
            )
            tech, created = TechnicianProfile.objects.get_or_create(
                user=user,
                defaults={
                    'city': 'LHR',
                    'cnic_number': f'35202-{user.pk:07d}-1',
                    'experience_years': 5,
                    'bio': f'{full.split()[0]} is a certified technician with '
                           '5 years of field experience.',
                    'status': status,
                    'rejection_reason': rejection,
                    'is_onboarding_complete': True,
                    'is_active': status != 'REJECTED',
                    'is_online': status == 'APPROVED',
                    'base_latitude': 31.5204,
                    'base_longitude': 74.3587,
                    'max_travel_radius_km': 12,
                    'work_address_label': 'Gulberg, Lahore',
                    'rating_average': Decimal('4.85') if status == 'APPROVED' else Decimal('0'),
                    'review_count': 12 if status == 'APPROVED' else 0,
                    'current_wallet_balance': Decimal('1200.00') if status == 'APPROVED' else Decimal('0'),
                },
            )
            if created and with_images:
                tech.profile_picture.save(
                    f'{phone}_profile.png',
                    _image_file(f'{phone}_profile.png', f'{full.split()[0]}', (37, 99, 235)),
                    save=False,
                )
                tech.cnic_front_image.save(
                    f'{phone}_cnic.png',
                    _image_file(f'{phone}_cnic.png', f'CNIC {tech.cnic_number}', (5, 150, 105)),
                    save=False,
                )
                tech.save()
                TechnicianSkill.objects.get_or_create(
                    technician=tech,
                    sub_service=catalog['sub_ac_wash'],
                    defaults={'years_of_experience': 4, 'labor_rate': Decimal('1500.00')},
                )
                TechnicianServiceLicense.objects.get_or_create(
                    technician=tech,
                    service=catalog['service_ac'],
                    defaults={'license_picture': None},
                )
                license = TechnicianServiceLicense.objects.filter(
                    technician=tech, service=catalog['service_ac'],
                ).first()
                if license and not license.license_picture:
                    license.license_picture.save(
                        f'{phone}_lic_ac.png',
                        _image_file(f'{phone}_lic_ac.png', 'AC License', (217, 119, 6)),
                        save=True,
                    )
            return tech

        return {
            'pending': _make(
                '+923211000010', '+923211000010', 'Hassan Ahmed', 'PENDING',
            ),
            'approved': _make(
                '+923211000011', '+923211000011', 'Imran Malik', 'APPROVED',
            ),
            'rejected': _make(
                '+923211000012', '+923211000012', 'Bilal Tariq', 'REJECTED',
                rejection='CNIC image was illegible — please reupload.',
            ),
        }

    # ---- bookings ----------------------------------------------------------

    def _seed_bookings(self, customers, technicians, catalog):
        from bookings.models import JobBooking
        from customers.models import CustomerAddress

        tech = technicians['approved']
        addr_sara = CustomerAddress.objects.filter(customer=customers['sara']).first()
        addr_ahmed = CustomerAddress.objects.filter(customer=customers['ahmed']).first()
        now = timezone.now()

        confirmed, _ = JobBooking.objects.get_or_create(
            customer=customers['sara'].user,
            technician=tech,
            service=catalog['service_ac'],
            sub_service=catalog['sub_ac_wash'],
            scheduled_start=now + timezone.timedelta(hours=4),
            defaults={
                'address': addr_sara,
                'scheduled_end': now + timezone.timedelta(hours=5, minutes=30),
                'status': JobBooking.STATUS_CONFIRMED,
                'price_amount': Decimal('1500.00'),
                'price_context': 'Fixed Price',
                'accepted_at': now - timezone.timedelta(minutes=10),
                'actual_address_snapshot': 'House 12, Gulberg III, Lahore',
            },
        )

        completed, _ = JobBooking.objects.get_or_create(
            customer=customers['ahmed'].user,
            technician=tech,
            service=catalog['service_plumb'],
            sub_service=catalog['sub_pipe'],
            scheduled_start=now - timezone.timedelta(days=2),
            defaults={
                'address': addr_ahmed,
                'scheduled_end': now - timezone.timedelta(days=2) + timezone.timedelta(hours=1, minutes=30),
                'status': JobBooking.STATUS_COMPLETED,
                'price_amount': Decimal('1200.00'),
                'price_context': 'Labor Fee',
                'accepted_at': now - timezone.timedelta(days=2, hours=1),
                'completed_at': now - timezone.timedelta(days=2) + timezone.timedelta(hours=2),
                'cash_collected_amount': Decimal('1700.00'),
                'cash_collected_at': now - timezone.timedelta(days=2) + timezone.timedelta(hours=2),
                'inspection_fee': Decimal('500.00'),
                'base_services_total': Decimal('1200.00'),
                'final_cash_to_collect': Decimal('1700.00'),
                'actual_address_snapshot': 'F-7 Markaz, Islamabad',
            },
        )

        disputed, _ = JobBooking.objects.get_or_create(
            customer=customers['sara'].user,
            technician=tech,
            service=catalog['service_ac'],
            sub_service=catalog['sub_ac_wash'],
            scheduled_start=now - timezone.timedelta(days=5),
            defaults={
                'address': addr_sara,
                'scheduled_end': now - timezone.timedelta(days=5) + timezone.timedelta(hours=1),
                'status': JobBooking.STATUS_DISPUTED,
                'price_amount': Decimal('1500.00'),
                'price_context': 'Fixed Price',
                'accepted_at': now - timezone.timedelta(days=5, hours=1),
                'completed_at': now - timezone.timedelta(days=5) + timezone.timedelta(hours=1, minutes=30),
                'cash_collected_amount': Decimal('1500.00'),
                'cash_collected_at': now - timezone.timedelta(days=5) + timezone.timedelta(hours=1, minutes=30),
                'inspection_fee': Decimal('500.00'),
                'base_services_total': Decimal('1500.00'),
                'final_cash_to_collect': Decimal('1500.00'),
                'dispute_opened_at': now - timezone.timedelta(days=4),
                'actual_address_snapshot': 'House 12, Gulberg III, Lahore',
            },
        )

        return {'confirmed': confirmed, 'completed': completed, 'disputed': disputed}

    # ---- disputes ----------------------------------------------------------

    def _seed_disputes(self, bookings, customers, technicians, wipe: bool):
        from bookings.models import SupportTicket, TicketEvidence

        if wipe:
            SupportTicket.objects.filter(booking=bookings['disputed']).delete()

        # FORM-intake ticket with photo evidence
        form_ticket, created = SupportTicket.objects.get_or_create(
            booking=bookings['disputed'],
            opened_by=customers['sara'].user,
            dispute_intake_method=SupportTicket.INTAKE_FORM,
            defaults={
                'initial_reason': (
                    'The AC stopped cooling the day after the service. '
                    'The technician left some screws missing on the front '
                    'panel and the airflow is uneven. I want a redo or a '
                    'partial refund.'
                ),
                'status': SupportTicket.STATUS_OPEN,
            },
        )
        if created:
            for i, label in enumerate(['Front panel — missing screws', 'AC unit overview']):
                ev = TicketEvidence(
                    ticket=form_ticket,
                    uploaded_by=customers['sara'].user,
                    caption=label,
                )
                ev.image.save(
                    f'dispute_{form_ticket.pk}_{i}.png',
                    _image_file(
                        f'evidence_{i}.png',
                        f'EVIDENCE {i+1}\n{label}',
                        (220, 38, 38) if i == 0 else (37, 99, 235),
                    ),
                    save=True,
                )

        # CHATBOT-intake ticket on the same booking, with chat_log
        from chatbot.models import Attachment, Conversation, Message
        conv, conv_created = Conversation.objects.get_or_create(
            user=customers['sara'].user,
            persona_key='dispute',
            defaults={
                'context': {'booking_id': bookings['disputed'].pk},
                'state': {
                    'phase': 'CLOSED',
                    'captured_fields': {
                        'issue_summary': 'AC stopped cooling next day',
                        'amount_paid': '1500',
                        'date_of_failure': '2026-05-11',
                        'contacted_technician': 'yes — no response',
                    },
                },
                'turn_count': 6,
                'is_closed': True,
                'output_refs': {},
                'closed_at': timezone.now() - timezone.timedelta(days=4),
            },
        )
        if conv_created:
            sample_dialogue = [
                ('BOT',  'Hi — sorry to hear the AC service on May 11 didn\'t go well. Could you tell me what happened?'),
                ('USER', 'AC stopped cooling the next day. Some screws were missing too.'),
                ('BOT',  'How much did you pay in total?'),
                ('USER', 'Rs 1500. I called the technician but he didn\'t respond.'),
                ('BOT',  'Got it. Let\'s collect some photos next.'),
                ('USER', 'OK uploading photos now.'),
            ]
            for role, text in sample_dialogue:
                Message.objects.create(
                    conversation=conv, role=role, text=text, phase='UNDERSTAND',
                )
            att = Attachment(
                conversation=conv,
                mime_type='image/png',
                size_bytes=12345,
            )
            att._skip_strip = True
            att.file.save(
                f'chat_{conv.pk}_0.png',
                _image_file('chat_0.png', 'CHAT PHOTO 1', (16, 185, 129)),
                save=True,
            )

        chatbot_ticket, ct_created = SupportTicket.objects.get_or_create(
            booking=bookings['disputed'],
            opened_by=customers['sara'].user,
            dispute_intake_method=SupportTicket.INTAKE_CHATBOT,
            defaults={
                'initial_reason': 'AC stopped cooling next day; technician unreachable.',
                'status': SupportTicket.STATUS_OPEN,
                'chat_log': {
                    'conversation_id': conv.pk,
                    'ai_summary': (
                        'Customer reports the AC unit stopped cooling the day '
                        'after a Rs. 1,500 service visit. Photos show missing '
                        'screws on the front panel. Customer was unable to '
                        'reach the technician for a follow-up. Requests a '
                        'redo or partial refund.'
                    ),
                    'ai_summary_lang': 'en',
                    'captured_fields': {
                        'issue_summary': 'AC stopped cooling next day',
                        'amount_paid': '1500',
                        'date_of_failure': '2026-05-11',
                        'contacted_technician': 'yes — no response',
                    },
                    'needs_review': True,
                    'needs_review_reason': 'amount_paid value extracted from short answer; verify.',
                    'messages': [
                        {'role': m.role, 'text': m.text}
                        for m in conv.messages.all()
                    ],
                    'attachments': [
                        a.file.name for a in conv.attachments.all()
                    ],
                },
            },
        )
        if ct_created:
            conv.output_refs = {'support_ticket_id': chatbot_ticket.pk}
            conv.save(update_fields=['output_refs'])

        # ----------------------------------------------------------------
        # Historical RESOLVED tickets — populate the v2 dispute fields so
        # the changelist shows a realistic mix of outcomes (outcome pill +
        # tech share column) without requiring someone to click through
        # the Resolve form first. We DO NOT write the wallet ledger here —
        # that side-effect belongs to the orchestrator, and seed code
        # must not bypass it. The ticket rows are display-only history.
        # ----------------------------------------------------------------
        SupportTicket.objects.get_or_create(
            booking=bookings['completed'],
            opened_by=customers['ahmed'].user,
            dispute_intake_method=SupportTicket.INTAKE_FORM,
            defaults={
                'initial_reason': (
                    'Plumbing leak under sink was patched but started '
                    'leaking again two days later. Need re-fix or refund.'
                ),
                'status': SupportTicket.STATUS_RESOLVED,
                'resolution_outcome': SupportTicket.OUTCOME_ACCEPT_REFUND,
                'tech_penalty_percentage': 50,
                'external_refund_reference': 'JC-RFND-20260514-DEMO01',
                'customer_notification_message': (
                    'Refund of Rs. 750 sent to your JazzCash account. '
                    'Half deducted from technician wallet as penalty for '
                    'incomplete fix. Apologies for the inconvenience.'
                ),
                'resolution_notes': (
                    'Photos confirmed leak recurred. Tech admitted partial '
                    'patch (used wrong sealant). 50/50 split: customer '
                    'gets half refund, tech eats half. Tech notified.'
                ),
                'resolved_at': timezone.now() - timezone.timedelta(days=2),
            },
        )

    # ---- wallet ------------------------------------------------------------

    def _seed_withdrawal(self, tech):
        from wallet.models import (
            TechnicianJazzCashAccount, WithdrawalRequest, WithdrawalStatus,
        )

        jc, _ = TechnicianJazzCashAccount.objects.get_or_create(
            technician=tech,
            mobile_number='+923211000011',
            defaults={'account_title': tech.user.get_full_name(), 'is_active': True},
        )
        WithdrawalRequest.objects.get_or_create(
            technician=tech,
            amount=Decimal('800.00'),
            status=WithdrawalStatus.PENDING_REVIEW,
            defaults={'payout_jazzcash_account': jc},
        )

    def _seed_wallet_transactions(self, tech):
        from wallet.models import TransactionType, WalletTransaction

        # Skip if any ledger row already exists — don't double-write idempotently.
        if WalletTransaction.objects.filter(technician=tech).exists():
            return
        WalletTransaction.objects.create(
            technician=tech,
            transaction_type=TransactionType.TOPUP_CREDIT,
            amount=Decimal('2000.00'),
            balance_after=Decimal('2000.00'),
            memo='Initial JazzCash top-up',
        )
        WalletTransaction.objects.create(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-300.00'),
            balance_after=Decimal('1700.00'),
            memo='Platform commission — Booking #demo',
            transaction_reference_number='demo:commission:1',
        )
        WalletTransaction.objects.create(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-500.00'),
            balance_after=Decimal('1200.00'),
            memo='Platform commission — Booking #demo2',
            transaction_reference_number='demo:commission:2',
        )
        tech.current_wallet_balance = Decimal('1200.00')
        tech.save(update_fields=['current_wallet_balance'])

    def _seed_events(self, customers, technicians):
        from realtime.models import EventLog

        if EventLog.objects.count() >= 6:
            return
        samples = [
            ('job_new_request', technicians['approved'].user, EventLog.TARGET_TECHNICIAN, True),
            ('job_accepted', customers['sara'].user, EventLog.TARGET_CUSTOMER, False),
            ('quote_generated', customers['sara'].user, EventLog.TARGET_CUSTOMER, True),
            ('quote_approved', technicians['approved'].user, EventLog.TARGET_TECHNICIAN, True),
            ('payment_received', customers['ahmed'].user, EventLog.TARGET_CUSTOMER, False),
            ('dispute_opened', technicians['approved'].user, EventLog.TARGET_TECHNICIAN, True),
        ]
        for event_type, user, target, is_critical in samples:
            EventLog.objects.create(
                user=user,
                event_type=event_type,
                target_role=target,
                payload={'demo': True, 'event_type': event_type},
                is_critical=is_critical,
            )

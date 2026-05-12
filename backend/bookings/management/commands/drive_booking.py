"""
Drive a booking through any orchestrator state from the terminal.

Each subcommand calls the matching service function in
``bookings.services.orchestrator`` (or ``job_request_action``) so events
broadcast over the WebSocket and the customer's Chrome client updates
without a refresh. Direct ``booking.save(status=...)`` is intentionally NOT
used — it would skip the audit stamps, finance hooks, and event broadcasts
the realtime UI depends on.

Usage:
    python manage.py drive_booking <booking_id> <action> [flags]

Actions (paired with the runbook in booking_orchestrator_sprint/):

    confirm                AWAITING  → CONFIRMED          (tech accepts)
    reject                 AWAITING  → REJECTED           (tech declines)
    depart                 CONFIRMED → EN_ROUTE
    arrive                 EN_ROUTE  → ARRIVED
    start_inspection       ARRIVED   → INSPECTING
    quote [--upsell]       INSPECTING → QUOTED            (or upsell on IN_PROGRESS)
        --items "sub_id:price[:qty],..."   default: one line at booking.price_amount
    approve_quote          QUOTED    → IN_PROGRESS
    revise_quote           QUOTED    → INSPECTING
    decline_quote          QUOTED    → COMPLETED_INSPECTION_ONLY
    complete_cash          IN_PROGRESS → COMPLETED
        --amount X         override booking.final_cash_to_collect
    cancel --as customer|tech
    no_show --actor tech|customer [--force]
        --force bypasses the 15-minute wait via the orchestrator's _clock seam
    dispute --as customer|tech
    reschedule [--in-hours N]   default: now + 2h, +1h slot

Examples:

    python manage.py drive_booking 42 confirm
    python manage.py drive_booking 42 depart
    python manage.py drive_booking 42 arrive
    python manage.py drive_booking 42 start_inspection
    python manage.py drive_booking 42 quote
    python manage.py drive_booking 42 approve_quote
    python manage.py drive_booking 42 complete_cash
    python manage.py drive_booking 43 no_show --actor tech --force
"""

from __future__ import annotations

from datetime import timedelta
from decimal import Decimal, InvalidOperation
from typing import Optional

from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from bookings.exceptions import BookingValidationError
from bookings.models import JobBooking, Quote
from bookings.services import orchestrator
from bookings.services.job_request_action import (
    accept_job_booking,
    decline_job_booking,
)
from catalog.models import SubService


ACTIONS = [
    'confirm', 'reject',
    'depart', 'arrive', 'start_inspection',
    'quote', 'approve_quote', 'revise_quote', 'decline_quote',
    'complete_cash',
    'cancel', 'no_show', 'dispute', 'reschedule',
]


# Linear happy-path forward order. The demo script (and the dev) often races
# the customer-side Chrome UI: a person tapping "Approve" in the browser
# advances the booking before the CLI's matching `drive_booking` step runs,
# leaving the CLI with no SUBMITTED quote / wrong status / etc.
#
# For each forward action below, if the booking is already at-or-past the
# post-state, we no-op with a friendly message instead of erroring. The
# branchy actions (revise / decline / cancel / no_show / dispute / reschedule)
# are NOT idempotent — they remain strict so real misuse still surfaces.
FORWARD_ORDER = [
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
    JobBooking.STATUS_IN_PROGRESS,
    JobBooking.STATUS_COMPLETED,
]

# Maps each forward action to the post-state that proves it's "already done".
# Used purely for idempotency; the actual transition logic lives in the
# orchestrator service functions.
FORWARD_POST_STATE = {
    'confirm': JobBooking.STATUS_CONFIRMED,
    'depart': JobBooking.STATUS_EN_ROUTE,
    'arrive': JobBooking.STATUS_ARRIVED,
    'start_inspection': JobBooking.STATUS_INSPECTING,
    'approve_quote': JobBooking.STATUS_IN_PROGRESS,
    'complete_cash': JobBooking.STATUS_COMPLETED,
}


class Command(BaseCommand):
    help = 'Drive a booking through any orchestrator state. See module docstring.'

    def add_arguments(self, parser):
        parser.add_argument('booking_id', type=int)
        parser.add_argument('action', choices=ACTIONS)
        parser.add_argument('--as', dest='as_role', choices=['customer', 'tech'])
        parser.add_argument('--actor', choices=['tech', 'customer'],
                            help='no_show: who reported the other party absent')
        parser.add_argument('--force', action='store_true',
                            help='no_show: bypass the 15-minute wait (test seam)')
        parser.add_argument('--items', default=None,
                            help='quote: line items as "sub_id:price[:qty],..."')
        parser.add_argument('--upsell', action='store_true',
                            help='quote: submit as a mid-job upsell on IN_PROGRESS')
        parser.add_argument('--quote-id', type=int, default=None,
                            help='approve/revise/decline: target quote id (default: latest SUBMITTED)')
        parser.add_argument('--reason', default='Test reason from drive_booking',
                            help='revise/decline/dispute: reason text')
        parser.add_argument('--amount', default=None,
                            help='complete_cash: override booking.final_cash_to_collect')
        parser.add_argument('--in-hours', type=int, default=2,
                            help='reschedule: hours from now for the new start (default 2)')

    def handle(self, *args, **opts):
        booking = self._load_booking(opts['booking_id'])
        action = opts['action']
        before = booking.status

        # Idempotency on the forward happy-path. If the Chrome UI (or a prior
        # run) already advanced past the action's post-state, skip cleanly so
        # the demo can keep walking instead of dying on a stale precondition.
        if self._already_at_or_past(action, booking):
            target = FORWARD_POST_STATE[action]
            self.stdout.write('')
            self.stdout.write(self.style.WARNING(
                f'  ⤳ {action}: booking #{booking.id} is already at {booking.status} '
                f'(post-state {target}); skipping.'
            ))
            self.stdout.write('')
            return

        try:
            self._dispatch(action, booking, opts)
        except BookingValidationError as e:
            # Surface the exact same envelope a view would emit so users
            # can debug "why didn't this transition" with the same vocabulary.
            raise CommandError(f'{e.code}: {e.message}') from e

        booking.refresh_from_db()
        self._print_result(action, before, booking)

    # ------------------------------------------------------------------
    # idempotency
    # ------------------------------------------------------------------

    def _already_at_or_past(self, action: str, booking: JobBooking) -> bool:
        """True when `action` is a forward step the booking has already taken.

        The check is intentionally narrow:
          * Only the forward actions in ``FORWARD_POST_STATE`` are eligible.
            ``quote`` is NOT in that map because a fresh quote (rev N+1) is
            always a legitimate ask, and the upsell path adds another quote
            on an already-IN_PROGRESS booking.
          * Branchy actions (cancel / revise / decline / no_show / dispute /
            reschedule / reject) are NEVER skipped — these are deliberate
            choices the human is making, not racing the UI.
        """
        if action not in FORWARD_POST_STATE:
            return False
        target = FORWARD_POST_STATE[action]
        try:
            current_idx = FORWARD_ORDER.index(booking.status)
            target_idx = FORWARD_ORDER.index(target)
        except ValueError:
            # Booking is in a terminal / off-path state (CANCELLED, REJECTED,
            # NO_SHOW, DISPUTED, COMPLETED_INSPECTION_ONLY). Let the service
            # function raise its real domain error.
            return False
        return current_idx >= target_idx

    # ------------------------------------------------------------------
    # dispatch
    # ------------------------------------------------------------------

    def _dispatch(self, action: str, booking: JobBooking, opts: dict) -> None:
        tech_user = booking.technician.user
        customer_user = booking.customer

        if action == 'confirm':
            accept_job_booking(booking_id=booking.id, technician_user=tech_user)

        elif action == 'reject':
            decline_job_booking(booking_id=booking.id, technician_user=tech_user)

        elif action == 'depart':
            orchestrator.en_route(booking_id=booking.id, technician_user=tech_user)

        elif action == 'arrive':
            orchestrator.arrived(booking_id=booking.id, technician_user=tech_user)

        elif action == 'start_inspection':
            orchestrator.start_inspection(booking_id=booking.id, technician_user=tech_user)

        elif action == 'quote':
            line_items = self._build_line_items(booking, opts['items'])
            quote = orchestrator.submit_quote(
                booking_id=booking.id,
                technician_user=tech_user,
                line_items=line_items,
                is_upsell=opts['upsell'],
            )
            self.stdout.write(self.style.SUCCESS(
                f'  Quote #{quote.id} submitted (rev {quote.revision_number}, '
                f'total Rs.{quote.total_amount}, upsell={quote.is_upsell})'
            ))

        elif action == 'approve_quote':
            quote_id = self._resolve_quote_id(booking, opts['quote_id'])
            orchestrator.approve_quote(
                booking_id=booking.id,
                customer_user=customer_user,
                quote_id=quote_id,
            )

        elif action == 'revise_quote':
            quote_id = self._resolve_quote_id(booking, opts['quote_id'])
            orchestrator.request_revision(
                booking_id=booking.id,
                customer_user=customer_user,
                quote_id=quote_id,
                reason=opts['reason'],
            )

        elif action == 'decline_quote':
            quote_id = self._resolve_quote_id(booking, opts['quote_id'])
            orchestrator.decline_quote(
                booking_id=booking.id,
                customer_user=customer_user,
                quote_id=quote_id,
                reason=opts['reason'],
            )

        elif action == 'complete_cash':
            amount = self._resolve_cash_amount(booking, opts['amount'])
            orchestrator.mark_complete_with_cash(
                booking_id=booking.id,
                technician_user=tech_user,
                cash_amount=amount,
            )

        elif action == 'cancel':
            role = opts['as_role'] or 'customer'
            if role == 'customer':
                orchestrator.cancel_by_customer(
                    booking_id=booking.id, customer_user=customer_user,
                )
            else:
                orchestrator.cancel_by_tech(
                    booking_id=booking.id, technician_user=tech_user,
                )

        elif action == 'no_show':
            actor = opts['actor']
            if not actor:
                raise CommandError('no_show requires --actor tech|customer')
            actor_user = tech_user if actor == 'tech' else customer_user
            clock = self._build_force_clock(booking, actor) if opts['force'] else None
            orchestrator.mark_no_show(
                booking_id=booking.id,
                actor_user=actor_user,
                actor_role=actor,
                _clock=clock,
            )

        elif action == 'dispute':
            role = opts['as_role'] or 'customer'
            opener = customer_user if role == 'customer' else tech_user
            ticket = orchestrator.open_dispute(
                booking_id=booking.id,
                opener_user=opener,
                initial_reason=opts['reason'],
            )
            self.stdout.write(self.style.SUCCESS(
                f'  Ticket #{ticket.id} opened ({ticket.status})'
            ))

        elif action == 'reschedule':
            new_start = timezone.now() + timedelta(hours=opts['in_hours'])
            new_end = new_start + timedelta(hours=1)
            child = orchestrator.reschedule(
                original_booking_id=booking.id,
                customer_user=customer_user,
                new_scheduled_start=new_start,
                new_scheduled_end=new_end,
            )
            self.stdout.write(self.style.SUCCESS(
                f'  New child booking #{child.id} (status={child.status}) '
                f'scheduled at {new_start.isoformat()}'
            ))

        else:
            raise CommandError(f'Unhandled action: {action}')

    # ------------------------------------------------------------------
    # helpers
    # ------------------------------------------------------------------

    def _load_booking(self, booking_id: int) -> JobBooking:
        try:
            return JobBooking.objects.select_related(
                'technician__user', 'customer', 'sub_service', 'service',
            ).get(id=booking_id)
        except JobBooking.DoesNotExist:
            raise CommandError(f'No booking with id={booking_id}')

    def _build_line_items(self, booking: JobBooking, items_arg: Optional[str]) -> list[dict]:
        if items_arg:
            out = []
            for chunk in items_arg.split(','):
                parts = chunk.split(':')
                if len(parts) < 2:
                    raise CommandError(f'Bad --items chunk "{chunk}"; expected "sub_id:price[:qty]"')
                sub_id = int(parts[0])
                price = Decimal(parts[1])
                qty = int(parts[2]) if len(parts) > 2 else 1
                out.append({'sub_service_id': sub_id, 'priced_at': price, 'quantity': qty})
            return out

        # Default: the booking's sub_service at base_price PLUS, when the
        # catalog has one available, a labor-priced companion line.
        #
        # Real AC repairs in this market are almost always mixed (parts
        # at catalog price + tech's diagnostic labor) — and importantly,
        # this is what surfaces the "Negotiate price" button on the
        # customer's QUOTED screen. Backend `_customer_quoted` omits the
        # `/request-revision/` action when every line item is a
        # fixed-price catalog sub-service (nothing to negotiate within),
        # so a pure-fixed default would hide the button and make the
        # demo's negotiation affordance invisible. The seeder
        # (`seed_test_fixtures._ensure_catalog`) plants the labor row
        # ("Diagnostic & Labor") used here.
        #
        # Pass `--items` explicitly to override and demo the all-fixed
        # case (no Negotiate button — by design).
        if booking.sub_service is None:
            raise CommandError(
                'Booking has no sub_service; pass --items "sub_id:price[:qty],..." explicitly.'
            )
        items = [{
            'sub_service_id': booking.sub_service.id,
            'priced_at': booking.sub_service.base_price,
            'quantity': 1,
        }]
        labor_companion = (
            SubService.objects
            .filter(service=booking.service, is_fixed_price=False)
            .order_by('id')
            .first()
        )
        if labor_companion is not None and labor_companion.id != booking.sub_service_id:
            items.append({
                'sub_service_id': labor_companion.id,
                'priced_at': labor_companion.base_price,
                'quantity': 1,
            })
        return items

    def _resolve_quote_id(self, booking: JobBooking, override: Optional[int]) -> int:
        if override is not None:
            return override
        latest = (
            Quote.objects.filter(booking=booking, status=Quote.STATUS_SUBMITTED)
            .order_by('-revision_number').first()
        )
        if latest is None:
            raise CommandError(
                f'No SUBMITTED quote on booking {booking.id}. '
                f'Run `quote` first or pass --quote-id <id>.'
            )
        return latest.id

    def _resolve_cash_amount(self, booking: JobBooking, override: Optional[str]) -> Decimal:
        if override is not None:
            try:
                return Decimal(override)
            except InvalidOperation as e:
                raise CommandError(f'Bad --amount "{override}": {e}')
        if booking.final_cash_to_collect is None:
            raise CommandError(
                'booking.final_cash_to_collect is None — approve_quote first or pass --amount.'
            )
        return booking.final_cash_to_collect

    def _build_force_clock(self, booking: JobBooking, actor: str):
        # The orchestrator anchors the 15-min wait on arrived_at (tech path)
        # or scheduled_start (customer path). We return a clock that's 16
        # minutes past the relevant anchor so the wait check passes.
        if actor == 'tech':
            anchor = booking.arrived_at
            if anchor is None:
                raise CommandError(
                    'no_show --actor tech --force needs the booking to have arrived_at set; '
                    'run `arrive` first.'
                )
        else:
            anchor = booking.scheduled_start
        forced_now = anchor + timedelta(seconds=16 * 60)
        return lambda: forced_now

    # ------------------------------------------------------------------
    # output
    # ------------------------------------------------------------------

    def _print_result(self, action: str, before: str, booking: JobBooking) -> None:
        s = self.style.SUCCESS
        self.stdout.write('')
        self.stdout.write(s(f'  ✓ {action}'))
        self.stdout.write(f'    booking #{booking.id}: {before} → {booking.status}')
        if booking.final_cash_to_collect is not None:
            self.stdout.write(f'    final_cash_to_collect: Rs.{booking.final_cash_to_collect}')
        if booking.cash_collected_amount is not None:
            self.stdout.write(f'    cash_collected: Rs.{booking.cash_collected_amount}')
        self.stdout.write('')

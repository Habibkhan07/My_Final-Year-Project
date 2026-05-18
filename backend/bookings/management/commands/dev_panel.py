"""Interactive demo panel — drive a booking end-to-end with single keys.

This is the dev-tool wrapper a human runs in *one* terminal instead of
juggling ``seed_test_fixtures`` / ``drive_booking`` / ``fake_tech_gps``
across three. Each menu key fans out to the same service-layer code
those scripts call, so the realtime broadcast paths are identical to
production. Nothing new is implemented here — this is glue + ergonomics.

Run:

    python manage.py dev_panel

First boot auto-seeds the demo customer (+923002222222) + tech
(+923001111111) + catalog + a fresh AWAITING booking via
``seed_test_fixtures``. Subsequent boots reuse those fixtures and
pick the most recent non-terminal booking between them.

This file is dev-only. It will be removed (along with the dashboard tap
wire and the START_AS dart-define) in the end-of-UI cleanup pass tracked
by the ``project_ui_cleanup_planned`` memory.
"""
from __future__ import annotations

import os
import signal
import subprocess
import sys
from pathlib import Path
from typing import Optional

from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.utils import timezone
from rest_framework.authtoken.models import Token

from bookings.exceptions import BookingValidationError
from bookings.models import JobBooking, Quote
from bookings.services import orchestrator
from bookings.services.job_request_action import (
    accept_job_booking,
    decline_job_booking,
)
from catalog.models import SubService

# Same phones the fixture seeder hard-codes — keep in lockstep with
# bookings/management/commands/seed_test_fixtures.py so the menu can
# look up its actors without re-parsing the seeder's stdout.
CUSTOMER_PHONE = '+923002222222'
TECH_PHONE = '+923001111111'

# Status set that means "this booking is still in flight" — i.e. a valid
# pick for the menu to reuse instead of seeding a fresh one.
_LIVE_STATUSES = {
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
    JobBooking.STATUS_IN_PROGRESS,
}

# Forward-step post-states. If the booking is already at or past the
# post-state of a forward action, the menu no-ops with a friendly note
# (the customer or tech may have advanced it through the UI in parallel).
_FORWARD_POST_STATE = {
    'confirm': JobBooking.STATUS_CONFIRMED,
    'depart': JobBooking.STATUS_EN_ROUTE,
    'arrive': JobBooking.STATUS_ARRIVED,
    'start_inspection': JobBooking.STATUS_INSPECTING,
    'approve_quote': JobBooking.STATUS_IN_PROGRESS,
    'complete_cash': JobBooking.STATUS_COMPLETED,
}

# Production-side event-emission map. dev_panel uses this to decide whether
# (and where) to mirror the transition for the actor's Chrome tab — see
# `_mirror_event` below.
#
# Two production patterns exist today:
#   * Orchestrator transitions (``orchestrator._broadcast_both``) emit to
#     BOTH roles in one call — the actor's tab is already covered by the
#     production event, so dev_panel must NOT mirror (would double-push the
#     counterparty's FCM tray when their app is backgrounded).
#   * ``accept_job_booking`` emits ``job_accepted`` to the customer only
#     — the tech's tab gets no production WS frame, so dev_panel mirrors
#     to the tech (and only the tech) to refresh that side.
#
# When adding a new action, register it in `_ACTION_EVENT_TYPE` AND in
# `_MIRROR_TARGET_ROLE`. Omitting the second entry means the mirror is
# skipped (the safe default — matches the orchestrator-broadcasts-both
# pattern that covers everything except the accept flow today).
#
# Values MUST match ``realtime.constants.event_types.EventType.value`` so
# the frontend's ``bookingOrchestratorEventsNotifier`` recognises and
# refreshes on them.
_ACTION_EVENT_TYPE = {
    'confirm': 'job_accepted',
    'depart': 'tech_en_route',
    'arrive': 'tech_arrived',
    'start_inspection': 'inspection_started',
    'quote': 'quote_generated',
    'approve_quote': 'quote_approved',
    'complete_cash': 'job_completed',
}

# Mirror only for events the production service does NOT already fan out
# to both roles. Currently only `job_accepted` (production: customer only,
# mirror: tech). Every other entry in `_ACTION_EVENT_TYPE` is omitted
# because production already broadcasts to both — mirroring would
# duplicate the push.
_MIRROR_TARGET_ROLE: dict[str, str] = {
    'job_accepted': 'technician',
}
_FORWARD_ORDER = [
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
    JobBooking.STATUS_IN_PROGRESS,
    JobBooking.STATUS_COMPLETED,
]


class Command(BaseCommand):
    help = 'Single-terminal demo panel. See module docstring.'

    def handle(self, *args, **opts):
        try:
            self._main_loop()
        except (KeyboardInterrupt, EOFError):
            self.stdout.write('')
            self.stdout.write(self.style.WARNING('Interrupted; cleaning up.'))
        finally:
            self._stop_gps_sim(silent=True)

    # ------------------------------------------------------------------
    # main loop
    # ------------------------------------------------------------------

    _gps_proc: Optional[subprocess.Popen] = None
    _booking_id: Optional[int] = None
    _tech_token: Optional[str] = None
    _customer_token: Optional[str] = None

    def _main_loop(self) -> None:
        self._bootstrap()
        while True:
            self._render_header()
            choice = self._prompt()
            if choice in {'q', 'quit', 'exit'}:
                return
            self._dispatch(choice)

    # ------------------------------------------------------------------
    # bootstrap — ensure fixtures + a live booking exist
    # ------------------------------------------------------------------

    def _bootstrap(self) -> None:
        from accounts.models import UserProfile

        # Always run the seeder — it's idempotent (get_or_create everywhere)
        # except for the booking creation which spawns one fresh AWAITING per
        # invocation. We sidestep that by only running it when there's no
        # existing live booking between the two fixture users.
        cust_profile = UserProfile.objects.filter(phone=CUSTOMER_PHONE).first()
        tech_profile = UserProfile.objects.filter(phone=TECH_PHONE).first()
        need_seed = cust_profile is None or tech_profile is None

        live = None
        if not need_seed:
            live = self._pick_live_booking(cust_profile.user)

        if need_seed or live is None:
            self.stdout.write(self.style.NOTICE('Seeding fixtures (idempotent)...'))
            call_command('seed_test_fixtures', verbosity=0)
            cust_profile = UserProfile.objects.get(phone=CUSTOMER_PHONE)
            live = self._pick_live_booking(cust_profile.user)

        if live is None:
            self.stderr.write(self.style.ERROR(
                'Seeded fixtures but no live booking found. Aborting.'
            ))
            sys.exit(1)

        self._booking_id = live.id
        self._tech_token = Token.objects.get(user=live.technician.user).key
        self._customer_token = Token.objects.get(user=live.customer).key

    def _pick_live_booking(self, customer_user) -> Optional[JobBooking]:
        return (
            JobBooking.objects
            .filter(customer=customer_user, status__in=_LIVE_STATUSES)
            .select_related('technician__user', 'customer', 'service', 'sub_service', 'address')
            .order_by('-id')
            .first()
        )

    # ------------------------------------------------------------------
    # rendering
    # ------------------------------------------------------------------

    def _render_header(self) -> None:
        b = self._load()
        bar = '═' * 63
        gps_state = self._gps_state_str()
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(bar))
        self.stdout.write(self.style.SUCCESS(
            f'  DEMO SESSION  •  booking #{b.id}  •  status: {b.status}'
        ))
        self.stdout.write(
            f'  customer {CUSTOMER_PHONE}   tech {TECH_PHONE}   OTP: 123456'
        )
        self.stdout.write(f'  GPS sim : {gps_state}')
        self.stdout.write(self.style.SUCCESS(bar))
        self.stdout.write('  [1] New demo booking          (adds another AWAITING)')
        self.stdout.write('  [2] Confirm                   → CONFIRMED')
        self.stdout.write('  [3] Depart                    → EN_ROUTE')
        self.stdout.write('  [4] Simulate GPS to door      (background)')
        self.stdout.write('  [4s] Stop GPS sim')
        self.stdout.write('  [5] Arrive (manual)           → ARRIVED')
        self.stdout.write('  [6] Start inspection          → INSPECTING')
        self.stdout.write('  [7] Submit demo quote         → QUOTED')
        self.stdout.write('  [8] Approve quote             → IN_PROGRESS')
        self.stdout.write('  [9] Complete (cash)           → COMPLETED')
        self.stdout.write('  [c] Cancel as customer        [t] Cancel as tech')
        self.stdout.write('  [w] WIPE all bookings + reseed (nuclear reset)')
        self.stdout.write('  [r] Refresh                   [q] Quit')

    def _prompt(self) -> str:
        try:
            return input('  pick: ').strip().lower()
        except EOFError:
            return 'q'

    # ------------------------------------------------------------------
    # dispatch
    # ------------------------------------------------------------------

    def _dispatch(self, choice: str) -> None:
        try:
            if choice == '1':
                self._new_booking()
            elif choice == '2':
                self._run('confirm', self._action_confirm)
            elif choice == '3':
                self._run('depart', self._action_depart)
            elif choice == '4':
                self._start_gps_sim()
            elif choice == '4s':
                self._stop_gps_sim()
            elif choice == '5':
                self._run('arrive', self._action_arrive)
            elif choice == '6':
                self._run('start_inspection', self._action_start_inspection)
            elif choice == '7':
                self._run('quote', self._action_submit_quote)
            elif choice == '8':
                self._run('approve_quote', self._action_approve_quote)
            elif choice == '9':
                self._run('complete_cash', self._action_complete_cash)
            elif choice == 'c':
                self._action_cancel_customer()
            elif choice == 't':
                self._action_cancel_tech()
            elif choice == 'w':
                self._action_wipe_and_reseed()
            elif choice == 'r':
                pass  # header re-renders next loop tick
            elif choice == '':
                pass
            else:
                self._warn(f'unknown key {choice!r}')
        except BookingValidationError as e:
            self._warn(f'{e.code}: {e.message}')

    def _run(self, action_name: str, fn) -> None:
        """Wraps a forward action with idempotency + before/after status print."""
        b = self._load()
        before = b.status
        target = _FORWARD_POST_STATE.get(action_name)
        if target is not None and self._already_at_or_past(b.status, target):
            self._warn(
                f'{action_name}: already at {b.status} (post-state {target}); skipped.'
            )
            return
        fn(b)
        b.refresh_from_db()
        self._mirror_event(b, _ACTION_EVENT_TYPE.get(action_name))
        self._ok(f'{action_name}: {before} → {b.status}')

    def _mirror_event(self, b: JobBooking, event_type_value: Optional[str]) -> None:
        """Refresh the actor's Chrome tab for events production doesn't already
        fan out to both roles.

        Background: production emits orchestrator transitions to BOTH roles via
        ``orchestrator._broadcast_both``. The single exception is
        ``accept_job_booking`` which emits ``job_accepted`` to the customer
        only — the tech's tab gets no production WS frame, so we fire one
        here.

        Previously this method iterated over both roles unconditionally. The
        "harmless" duplicate WS frame it produced for the counterparty was
        actually NOT harmless: it triggered a second FCM tray push when the
        recipient's app was backgrounded.

        Skip-by-default invariant: an event missing from
        ``_MIRROR_TARGET_ROLE`` produces NO mirror call. Adding a future
        single-role production emit means adding an entry to that map.
        """
        if event_type_value is None:
            return
        target_role = _MIRROR_TARGET_ROLE.get(event_type_value)
        if target_role is None:
            # Orchestrator already covers both roles for this event.
            return

        target_user = (
            b.technician.user if target_role == 'technician' else b.customer
        )

        # Lazy import — keeps Django bootstrap fast for command discovery.
        from realtime.events.services import EventDispatchService
        try:
            EventDispatchService.broadcast_event(
                user=target_user,
                target_role=target_role,
                event_type=event_type_value,
                payload={'job_id': b.id, 'status': b.status},
                expires_in_seconds=None,
            )
        except Exception as exc:  # noqa: BLE001 — dev tool, surface and continue
            self._warn(f'mirror to {target_role} failed: {exc}')

    @staticmethod
    def _already_at_or_past(current: str, target: str) -> bool:
        try:
            return _FORWARD_ORDER.index(current) >= _FORWARD_ORDER.index(target)
        except ValueError:
            # Terminal / off-path state — let the service raise its real error.
            return False

    # ------------------------------------------------------------------
    # actions — each is the exact same service call drive_booking uses
    # ------------------------------------------------------------------

    def _action_confirm(self, b: JobBooking) -> None:
        accept_job_booking(booking_id=b.id, technician_user=b.technician.user)

    def _action_depart(self, b: JobBooking) -> None:
        orchestrator.en_route(booking_id=b.id, technician_user=b.technician.user)
        # Auto-start the GPS simulator on departure: on web/desktop the
        # frontend's flutter_foreground_task is a no-op, so without this
        # the customer's LiveTrackingMap sits forever on "Waiting for
        # technician's location…". The simulator POSTs frames as if it
        # were the Android tech app — same auth path, same endpoint.
        # No-op if the sim is already running (idempotent).
        if self._gps_proc is None or self._gps_proc.poll() is not None:
            self._start_gps_sim()

    def _action_arrive(self, b: JobBooking) -> None:
        orchestrator.arrived(booking_id=b.id, technician_user=b.technician.user)

    def _action_start_inspection(self, b: JobBooking) -> None:
        orchestrator.start_inspection(
            booking_id=b.id, technician_user=b.technician.user,
        )

    def _action_submit_quote(self, b: JobBooking) -> None:
        # Default quote: booking's sub_service at base_price, plus a labor
        # companion if the catalog has one. Same shape as `drive_booking`'s
        # default — surfaces the customer's "Negotiate price" button.
        if b.sub_service is None:
            raise BookingValidationError(
                code='dev_panel_no_sub_service',
                message='Booking has no sub_service; cannot build a default quote.',
            )
        items = [{
            'sub_service_id': b.sub_service.id,
            'priced_at': b.sub_service.base_price,
            'quantity': 1,
        }]
        labor = (
            SubService.objects
            .filter(service=b.service, is_fixed_price=False)
            .order_by('id')
            .first()
        )
        if labor is not None and labor.id != b.sub_service_id:
            items.append({
                'sub_service_id': labor.id,
                'priced_at': labor.base_price,
                'quantity': 1,
            })
        quote = orchestrator.submit_quote(
            booking_id=b.id,
            technician_user=b.technician.user,
            line_items=items,
            is_upsell=False,
        )
        self._ok(
            f'  quote #{quote.id} submitted (rev {quote.revision_number}, '
            f'total Rs.{quote.total_amount})'
        )

    def _action_approve_quote(self, b: JobBooking) -> None:
        latest = (
            Quote.objects.filter(booking=b, status=Quote.STATUS_SUBMITTED)
            .order_by('-revision_number').first()
        )
        if latest is None:
            raise BookingValidationError(
                code='dev_panel_no_submitted_quote',
                message='No SUBMITTED quote — press [7] first.',
            )
        orchestrator.approve_quote(
            booking_id=b.id,
            customer_user=b.customer,
            quote_id=latest.id,
        )

    def _action_complete_cash(self, b: JobBooking) -> None:
        amount = b.final_cash_to_collect
        if amount is None:
            raise BookingValidationError(
                code='dev_panel_no_cash_amount',
                message='booking.final_cash_to_collect is None — approve a quote first.',
            )
        orchestrator.mark_complete_with_cash(
            booking_id=b.id,
            technician_user=b.technician.user,
            cash_amount=amount,
        )

    def _action_cancel_customer(self) -> None:
        b = self._load()
        before = b.status
        orchestrator.cancel_by_customer(
            booking_id=b.id, customer_user=b.customer,
        )
        b.refresh_from_db()
        self._stop_gps_sim(silent=True)
        self._mirror_event(b, 'booking_cancelled')
        self._ok(f'cancel (customer): {before} → {b.status}')

    def _action_cancel_tech(self) -> None:
        b = self._load()
        before = b.status
        orchestrator.cancel_by_tech(
            booking_id=b.id, technician_user=b.technician.user,
        )
        b.refresh_from_db()
        self._stop_gps_sim(silent=True)
        self._mirror_event(b, 'booking_cancelled')
        self._ok(f'cancel (tech): {before} → {b.status}')

    # ------------------------------------------------------------------
    # new booking
    # ------------------------------------------------------------------

    def _action_wipe_and_reseed(self) -> None:
        """Delete every booking in the DB, then seed one fresh AWAITING.

        Reuses ``wipe_bookings`` which knows the protected-FK delete
        order (BookingItem before JobBooking cascade). After the wipe,
        ``seed_test_fixtures`` plants a single AWAITING booking so the
        menu has something to walk through immediately.

        Both Chrome tabs will see the deletion reflected on their next
        refresh; bookings list realtime is event-driven, so refreshing
        the bookings list tab manually after a wipe is fastest.
        """
        from accounts.models import UserProfile

        self._stop_gps_sim(silent=True)
        self._ok('wiping all bookings...')
        call_command('wipe_bookings', verbosity=0)
        # Seed picks up that there are no bookings and creates one.
        call_command('seed_test_fixtures', verbosity=0)

        customer = UserProfile.objects.get(phone=CUSTOMER_PHONE).user
        new = self._pick_live_booking(customer)
        if new is None:
            self._warn('wipe ran but reseed produced no live booking.')
            return
        self._booking_id = new.id
        self._ok(
            f'reset complete. fresh booking #{new.id} ({new.status}). '
            f'Pull-to-refresh the customer bookings tab to clear stale rows.'
        )

    def _new_booking(self) -> None:
        self._stop_gps_sim(silent=True)
        # Reuse the seeder's booking creation rather than re-implementing
        # validation. It always appends a fresh AWAITING booking.
        from accounts.models import UserProfile

        call_command('seed_test_fixtures', verbosity=0)
        customer = UserProfile.objects.get(phone=CUSTOMER_PHONE).user
        new = self._pick_live_booking(customer)
        if new is None:
            self._warn('seed_test_fixtures ran but no live booking surfaced.')
            return
        self._booking_id = new.id
        self._ok(f'new booking #{new.id} ({new.status})')

    # ------------------------------------------------------------------
    # GPS simulator — wraps scripts/fake_tech_gps.py
    # ------------------------------------------------------------------

    def _start_gps_sim(self) -> None:
        if self._gps_proc is not None and self._gps_proc.poll() is None:
            self._warn(f'GPS sim already running (pid {self._gps_proc.pid}).')
            return
        b = self._load()
        if b.status not in {
            JobBooking.STATUS_CONFIRMED,
            JobBooking.STATUS_EN_ROUTE,
            JobBooking.STATUS_ARRIVED,
        }:
            # Outside this window the backend either ignores the frame (auto-
            # transition only fires on CONFIRMED/EN_ROUTE) or it's a no-op
            # against the customer UX. Better to refuse than confuse.
            self._warn(
                f'GPS sim needs CONFIRMED / EN_ROUTE / ARRIVED — current is {b.status}.'
            )
            return

        script = Path(__file__).resolve().parents[3] / 'scripts' / 'fake_tech_gps.py'
        if not script.exists():
            self._warn(f'fake_tech_gps.py not found at {script}.')
            return

        # Customer address coords drive the destination; tech base coords
        # drive the start. Both came in via the seeder so they always exist
        # on the loaded booking.
        if b.address is None:
            self._warn('booking has no address — cannot simulate GPS toward it.')
            return
        dest = f'{b.address.latitude},{b.address.longitude}'
        tech_lat = b.technician.base_latitude
        tech_lng = b.technician.base_longitude
        start = (
            f'{tech_lat},{tech_lng}'
            if tech_lat is not None and tech_lng is not None
            else dest
        )

        cmd = [
            sys.executable, str(script),
            '--booking-id', str(b.id),
            '--token', self._tech_token,
            '--start', start,
            '--dest', dest,
            '--mode', 'steady',
        ]
        # Redirect stdout to a log file so the menu prompt isn't polluted
        # by 1-frame-per-5s status spam. The user can `tail -f` it if they
        # want to see frames — see banner below.
        logs_dir = Path(__file__).resolve().parents[3] / 'logs'
        logs_dir.mkdir(exist_ok=True)
        log_path = logs_dir / f'fake_tech_gps_{b.id}.log'
        log_fh = open(log_path, 'a', buffering=1)
        log_fh.write(f'\n--- start {timezone.now().isoformat()} ---\n')
        # Use start_new_session so SIGINT to the menu doesn't kill the sim
        # before we get a chance to terminate it cleanly in our own finally.
        self._gps_proc = subprocess.Popen(
            cmd, stdout=log_fh, stderr=subprocess.STDOUT, start_new_session=True,
        )
        self._ok(
            f'GPS sim started (pid {self._gps_proc.pid}). '
            f'tail -f {log_path} for frames.'
        )

    def _stop_gps_sim(self, *, silent: bool = False) -> None:
        proc = self._gps_proc
        if proc is None or proc.poll() is not None:
            self._gps_proc = None
            if not silent:
                self._warn('GPS sim was not running.')
            return
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            proc.wait(timeout=2)
        except (ProcessLookupError, subprocess.TimeoutExpired):
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except ProcessLookupError:
                pass
        self._gps_proc = None
        if not silent:
            self._ok('GPS sim stopped.')

    def _gps_state_str(self) -> str:
        if self._gps_proc is None or self._gps_proc.poll() is not None:
            return 'idle'
        return f'running (pid {self._gps_proc.pid})'

    # ------------------------------------------------------------------
    # helpers
    # ------------------------------------------------------------------

    def _load(self) -> JobBooking:
        return JobBooking.objects.select_related(
            'technician__user', 'customer', 'service', 'sub_service', 'address',
        ).get(id=self._booking_id)

    def _ok(self, msg: str) -> None:
        self.stdout.write(self.style.SUCCESS(f'  ✓ {msg}'))

    def _warn(self, msg: str) -> None:
        self.stdout.write(self.style.WARNING(f'  ! {msg}'))


# SECURITY: dev-only command, gated by `python manage.py` access (which
# requires the same Django settings/DB the prod app uses). Every action
# routes through the existing orchestrator services, so the same
# permission + scoping checks (tech can only act on their own bookings,
# customer can only cancel their own, etc.) that protect the HTTP API
# protect this menu. The seeded fixtures use known-public test phones
# (+923002222222 / +923001111111) so no real-user identity is exposed.

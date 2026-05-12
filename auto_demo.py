#!/usr/bin/env python3
"""
auto_demo.py — one-terminal customer-side state walk for Chrome testing.

Run this in one terminal; `flutter run -d chrome` in another. The script:
  1. Starts Django runserver (background, logs to /tmp/fyp_demo/backend.log)
  2. Seeds fixtures + a fresh AWAITING booking
  3. Waits for you to log into Chrome (+923002222222 / OTP 123456)
  4. Walks the booking through every customer-visible orchestrator state
     with --delay seconds between transitions
  5. Streams fake tech GPS during EN_ROUTE / ARRIVED so the live map moves
  6. Cleans up backend + GPS on Ctrl+C

Usage:
  python auto_demo.py                # default 12s between transitions
  python auto_demo.py --delay 20     # slower (good for screenshots)
  python auto_demo.py --manual       # press Enter to advance each step
  python auto_demo.py --decline      # walk inspect-only path
                                     # (decline quote → COMPLETED_INSPECTION_ONLY)
  python auto_demo.py --no-walk      # seed + start backend, you drive manually
                                     # via `manage.py drive_booking <id> <action>`
  python auto_demo.py --reset        # flush every JobBooking before seeding —
                                     # prevents stale half-walked bookings from
                                     # previous runs leaking into Past / Upcoming
"""
from __future__ import annotations

import argparse
import os
import re
import signal
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent
BACKEND_DIR = REPO_ROOT / 'backend'
VENV_PY = BACKEND_DIR / 'venv' / 'bin' / 'python'
LOG_DIR = Path(os.environ.get('LOG_DIR', '/tmp/fyp_demo'))


def die(msg: str) -> None:
    print(f'\n✗ {msg}', file=sys.stderr)
    sys.exit(1)


def step(msg: str) -> None:
    print()
    print(f'── {msg} ───────────────────')


def countdown(seconds: int, label: str) -> None:
    for i in range(seconds, 0, -1):
        print(f'\r  ⏳ {label} — {i:2d}s ', end='', flush=True)
        time.sleep(1)
    print('\r' + ' ' * 78 + '\r', end='')


def wait_for_user(label: str, manual: bool, delay: int) -> None:
    if manual:
        input(f'  → press Enter to {label}… ')
    else:
        countdown(delay, label)


def run_manage(args: list[str], check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(
        [str(VENV_PY), 'manage.py', *args],
        cwd=BACKEND_DIR,
        capture_output=True,
        text=True,
        check=check,
    )


def parse_seed_output(out: str) -> tuple[int, str]:
    booking = re.search(r'booking_id\s*=\s*(\d+)', out)
    token = re.search(r'Tech token\s*:\s*([A-Fa-f0-9]+)', out)
    if not booking or not token:
        die(f'could not parse booking_id / tech token from seed output:\n{out}')
    return int(booking.group(1)), token.group(1)


def wait_for_backend(timeout_s: int = 30) -> None:
    print('  waiting for backend to be reachable…')
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        try:
            with urllib.request.urlopen('http://localhost:8000/admin/login/', timeout=1) as r:
                if r.status == 200:
                    print('  ✓ backend up')
                    return
        except Exception:
            pass
        time.sleep(0.5)
    die(f"backend didn't come up in {timeout_s}s; check {LOG_DIR}/backend.log")


def main() -> int:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument('--delay', type=int, default=12,
                   help='seconds between state transitions (default 12)')
    p.add_argument('--manual', action='store_true',
                   help='press Enter between transitions instead of timing')
    p.add_argument('--decline', action='store_true',
                   help='walk inspect-only path (decline quote at QUOTED)')
    p.add_argument('--no-walk', action='store_true',
                   help='seed + start backend, skip the auto state walk')
    p.add_argument('--login-wait', type=int, default=30,
                   help='seconds to wait for Chrome login before walking (default 30)')
    p.add_argument('--reset', action='store_true',
                   help='flush every JobBooking row before seeding so each run '
                        'starts on a clean slate (no stale half-walked bookings)')
    args = p.parse_args()

    if not VENV_PY.exists():
        die(f'venv python not found at {VENV_PY}\n'
            f'  create it: cd backend && python3 -m venv venv && ./venv/bin/pip install -r requirements.txt')

    LOG_DIR.mkdir(parents=True, exist_ok=True)

    state = {'server': None, 'gps': None, 'cleaned': False}

    def cleanup(*_):
        if state['cleaned']:
            return
        state['cleaned'] = True
        print('\n── shutting down ─────────────────────────────')
        for label, proc in (('fake GPS', state['gps']), ('backend', state['server'])):
            if proc is None or proc.poll() is not None:
                continue
            proc.terminate()
            try:
                proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                proc.kill()
            print(f'  ✓ stopped {label}')
        print('  ✓ done')

    def on_signal(sig, frame):
        cleanup()
        sys.exit(0)

    signal.signal(signal.SIGINT, on_signal)
    signal.signal(signal.SIGTERM, on_signal)

    try:
        step('1/4 applying migrations')
        run_manage(['migrate', '--no-input'])
        print('  ✓ migrations applied')

        if args.reset:
            step('1.5/4 flushing previous bookings (--reset)')
            # Delete every JobBooking + dependents via the `wipe_bookings`
            # management command. We can't use a shell -c one-liner here
            # because `BookingItem.sourced_quote` is on_delete=PROTECT and
            # naively deleting JobBooking → Quote → BookingItem aborts.
            # The command knows the right deletion order.
            r = run_manage(['wipe_bookings'], check=False)
            if r.returncode != 0:
                print(r.stdout, end='')
                print(r.stderr, end='', file=sys.stderr)
                die('wipe_bookings failed — see stderr above')
            try:
                deleted = int((r.stdout or '0').strip().splitlines()[-1])
            except (ValueError, IndexError):
                deleted = 0
            print(f'  ✓ flushed {deleted} JobBooking row(s)')
        else:
            # No --reset: warn the operator if there are non-terminal
            # bookings hanging around. They'll appear in the Upcoming
            # tab and look like the current run's booking — leads to the
            # exact confusion the --reset flag was added to prevent.
            r = run_manage([
                'shell', '-c',
                'from bookings.models import JobBooking; '
                'terminal = {"COMPLETED","COMPLETED_INSPECTION_ONLY","CANCELLED",'
                '"REJECTED","NO_SHOW","DISPUTED"}; '
                'print(JobBooking.objects.exclude(status__in=terminal).count())',
            ], check=False)
            try:
                stale = int((r.stdout or '0').strip().splitlines()[-1])
            except (ValueError, IndexError):
                stale = 0
            if stale > 0:
                print()
                print(f'  ⚠ {stale} non-terminal booking(s) already in DB '
                      f'from previous runs.')
                print('    They appear in the Upcoming tab and may look like')
                print('    this run\'s booking. Use --reset to flush them.')

        step('2/4 starting Django runserver')
        backend_log = open(LOG_DIR / 'backend.log', 'w')
        state['server'] = subprocess.Popen(
            [str(VENV_PY), 'manage.py', 'runserver', '0.0.0.0:8000'],
            cwd=BACKEND_DIR, stdout=backend_log, stderr=subprocess.STDOUT,
        )
        print(f'  PID={state["server"].pid}  logs={LOG_DIR}/backend.log')
        wait_for_backend()

        step('3/4 seeding fixtures + 1 fresh booking')
        seed_out = run_manage(['seed_test_fixtures', '--count', '1']).stdout
        print(seed_out)
        booking_id, tech_token = parse_seed_output(seed_out)

        # Big visual banner — the booking id is the load-bearing thing
        # the operator must read. Previous demo runs leave older bookings
        # in non-terminal states; viewing those gives a stale UI that
        # looks like the demo is broken. Print the id huge and twice.
        booking_banner = f'BOOKING #{booking_id}'
        print()
        print('╔' + '═' * 66 + '╗')
        print('║' + ' ' * 66 + '║')
        print('║' + booking_banner.center(66) + '║')
        print('║' + '↑ THIS RUN DRIVES THIS ID — open exactly this one ↑'.center(66) + '║')
        print('║' + ' ' * 66 + '║')
        print('║  1. In another terminal, start Chrome:' + ' ' * 27 + '║')
        print('║       cd frontend && flutter run -d chrome \\' + ' ' * 21 + '║')
        print('║           --dart-define=MAP_PROVIDER=osm' + ' ' * 25 + '║')
        print('║' + ' ' * 66 + '║')
        print('║  2. Log in:' + ' ' * 54 + '║')
        print('║       Phone : +923002222222' + ' ' * 38 + '║')
        print('║       OTP   : 123456' + ' ' * 45 + '║')
        print('║' + ' ' * 66 + '║')
        print(f'║  3. Open BOOKING #{booking_id} (NOT any older one in the list).'.ljust(67) + '║')
        print('╚' + '═' * 66 + '╝')
        print()

        if args.no_walk:
            print('  --no-walk set; backend is running, drive manually with:')
            print(f'    {VENV_PY} manage.py drive_booking {booking_id} <action>')
            print(f'    {VENV_PY} scripts/fake_tech_gps.py --booking-id {booking_id} --token {tech_token}')
            print('  Ctrl+C to shut everything down.')
            state['server'].wait()
            return 0

        if args.manual:
            input('  → press Enter when Chrome is on the booking detail screen… ')
        else:
            countdown(args.login_wait, f'log in and open booking #{booking_id}')

        def drive(label: str, *cmd_args: str) -> None:
            step(label)
            r = run_manage(['drive_booking', str(booking_id), *cmd_args], check=False)
            sys.stdout.write(r.stdout)
            if r.returncode != 0:
                sys.stderr.write(r.stderr)
                die(f'drive_booking failed at "{label}"')

        drive('AWAITING → CONFIRMED', 'confirm')
        wait_for_user('watching CONFIRMED stub', args.manual, args.delay)

        drive('CONFIRMED → EN_ROUTE', 'depart')
        countdown(3, 'starting GPS broadcaster')

        step(f'starting fake_tech_gps for booking #{booking_id}')
        gps_log = open(LOG_DIR / 'gps.log', 'w')
        state['gps'] = subprocess.Popen(
            [str(VENV_PY), 'scripts/fake_tech_gps.py',
             '--booking-id', str(booking_id),
             '--token', tech_token,
             '--mode', 'steady'],
            cwd=BACKEND_DIR, stdout=gps_log, stderr=subprocess.STDOUT,
        )
        print(f'  PID={state["gps"].pid}  logs={LOG_DIR}/gps.log')
        wait_for_user('tech driving — map should be moving', args.manual, args.delay)

        drive('EN_ROUTE → ARRIVED', 'arrive')
        # The InDrive-style meeting flow surfaces a "I'm coming out" CTA
        # on the customer side. Encourage the operator to tap it before
        # we advance — that's what flips the tech's amber strip to green.
        wait_for_user(
            "tech at the address — tap 'I'm coming out' on Chrome",
            args.manual,
            args.delay,
        )

        step('stopping fake_tech_gps')
        if state['gps'] and state['gps'].poll() is None:
            state['gps'].terminate()
            state['gps'].wait(timeout=3)
        print('  ✓ stopped')
        state['gps'] = None

        drive('ARRIVED → INSPECTING', 'start_inspection')
        wait_for_user('inspection screen', args.manual, args.delay)

        drive('INSPECTING → QUOTED', 'quote')
        wait_for_user('review the quote card', args.manual, args.delay)

        if args.decline:
            drive('QUOTED → COMPLETED_INSPECTION_ONLY', 'decline_quote')
        else:
            drive('QUOTED → IN_PROGRESS', 'approve_quote')
            wait_for_user('work in progress', args.manual, args.delay)
            drive('IN_PROGRESS → COMPLETED', 'complete_cash')

        print()
        print('╔' + '═' * 66 + '╗')
        print(f'║  ✓ DEMO COMPLETE  (booking #{booking_id})'.ljust(67) + '║')
        print('║  Backend is still running. Press Ctrl+C to stop everything.   ║')
        print('║  To replay: re-run this script (it mints a fresh booking).    ║')
        print('╚' + '═' * 66 + '╝')

        state['server'].wait()
    finally:
        cleanup()
    return 0


if __name__ == '__main__':
    sys.exit(main())

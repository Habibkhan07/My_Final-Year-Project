#!/usr/bin/env python3
"""
Fake the technician's foreground GPS broadcaster from a laptop terminal.

POSTs frames to the same endpoint the real Android service uses:
  POST <base>/api/bookings/<booking_id>/tech-location/

The customer's Chrome client receives `tech_gps` stream frames over the
WebSocket and updates the LiveTrackingMap exactly as if a real device
were broadcasting. The backend's auto-transition geofence flips
CONFIRMED→EN_ROUTE→ARRIVED when frames cross the configured radii, so
running this against a CONFIRMED booking will progress it without any
extra `drive_booking` calls.

Usage:
  python scripts/fake_tech_gps.py \\
      --booking-id 42 \\
      --token <tech_drf_token> \\
      [--start 31.5230,74.3478] \\
      [--dest 31.5097,74.3478] \\
      [--speed 1.0] \\
      [--interval 5] \\
      [--mode steady|jitter|stop_60s|drop_then_recover]

Modes:
  steady              Post every <interval>s with smooth linear interpolation
                      from --start toward --dest at <speed>×.
  jitter              Steady + ±5m random noise per frame (tests marker
                      tween smoothing).
  stop_60s            Post for 30s, freeze for 60s, then resume — exercises
                      the customer's 60s "tech offline" orange banner and
                      its recovery on the next frame.
  drop_then_recover   Post for 20s, freeze for 90s (deeper than the
                      offline threshold), then resume.

Defaults match the seeder's tech-base / customer-address coords (Gulberg
III, Lahore), so `python scripts/fake_tech_gps.py --booking-id N --token T`
works out of the box after `python manage.py seed_test_fixtures`.

Stop with Ctrl+C; the script exits cleanly.
"""

from __future__ import annotations

import argparse
import math
import random
import sys
import time
from dataclasses import dataclass

import requests


# Defaults match seed_test_fixtures.py — tech base ~1.5 km north of the
# customer address in Gulberg III, Lahore. Walking these at speed=1.0 lands
# the tech at the destination in ~5 minutes.
DEFAULT_BASE_URL = 'http://localhost:8000'
DEFAULT_START = '31.5230,74.3478'
DEFAULT_DEST = '31.5097,74.3478'

# Real Android service posts every ~5 seconds (Geolocator distanceFilter=10).
# Backend per-booking throttle is 4 seconds — staying at 5s avoids 429s.
DEFAULT_INTERVAL = 5.0

# Per-frame movement: at speed=1.0 we advance the equivalent of 30 m per
# frame (≈ 21 km/h sustained), which mirrors a motorbike on city streets.
METERS_PER_STEP_AT_SPEED_1 = 30.0

# Earth radius for haversine; metres.
EARTH_RADIUS_M = 6_371_000.0


@dataclass
class Position:
    lat: float
    lng: float


def parse_latlng(spec: str) -> Position:
    try:
        lat_s, lng_s = spec.split(',')
        return Position(float(lat_s), float(lng_s))
    except Exception as e:
        raise argparse.ArgumentTypeError(f'expected "lat,lng", got {spec!r}: {e}')


def haversine_m(a: Position, b: Position) -> float:
    """Distance in metres between two coords."""
    phi1 = math.radians(a.lat)
    phi2 = math.radians(b.lat)
    dphi = math.radians(b.lat - a.lat)
    dlam = math.radians(b.lng - a.lng)
    h = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return 2 * EARTH_RADIUS_M * math.asin(math.sqrt(h))


def initial_bearing_deg(a: Position, b: Position) -> float:
    """Bearing in degrees [0, 360) from a to b."""
    phi1 = math.radians(a.lat)
    phi2 = math.radians(b.lat)
    dlam = math.radians(b.lng - a.lng)
    y = math.sin(dlam) * math.cos(phi2)
    x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(dlam)
    return (math.degrees(math.atan2(y, x)) + 360.0) % 360.0


def step_toward(here: Position, dest: Position, meters: float) -> Position:
    """Move `meters` along the great-circle path toward dest. If we'd overshoot, snap to dest."""
    remaining = haversine_m(here, dest)
    if remaining <= meters:
        return dest
    # Linear interpolation in lat/lng — accurate enough for sub-km moves.
    fraction = meters / remaining
    return Position(
        lat=here.lat + (dest.lat - here.lat) * fraction,
        lng=here.lng + (dest.lng - here.lng) * fraction,
    )


def jitter(p: Position, meters: float = 5.0) -> Position:
    """Return a copy of p with up to ±meters random noise (lat ~ 1°≈111km)."""
    deg = meters / 111_000.0
    return Position(
        lat=p.lat + random.uniform(-deg, deg),
        lng=p.lng + random.uniform(-deg, deg),
    )


def post_frame(
    *,
    session: requests.Session,
    base_url: str,
    booking_id: int,
    token: str,
    pos: Position,
    heading: float,
    accuracy_m: float = 8.0,
    timeout_s: float = 5.0,
) -> tuple[int, str]:
    url = f'{base_url}/api/bookings/{booking_id}/tech-location/'
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }
    body = {
        'lat': pos.lat,
        'lng': pos.lng,
        'accuracy_meters': accuracy_m,
        'heading': heading,
    }
    try:
        r = session.post(url, json=body, headers=headers, timeout=timeout_s)
        return r.status_code, r.text[:160]
    except requests.RequestException as e:
        return 0, f'(network) {e}'


def _print_frame(idx: int, pos: Position, status: int, body_snippet: str, mode_label: str) -> None:
    if status >= 200 and status < 300:
        marker = '✓'
    elif status == 429:
        marker = '~'  # throttled — expected occasionally
    else:
        marker = '✗'
    sys.stdout.write(
        f'{marker} #{idx:03d}  ({pos.lat:.6f}, {pos.lng:.6f})  '
        f'HTTP {status}  {mode_label}\n'
    )
    sys.stdout.flush()
    if status >= 400 and body_snippet:
        sys.stdout.write(f'    └─ {body_snippet}\n')


# ---------------------------------------------------------------------------
# mode runners — return (active, sleep_seconds) per loop iteration
# ---------------------------------------------------------------------------


def make_mode_handler(mode: str, interval: float):
    """Return a function(elapsed_s) → (should_post: bool, label: str).

    Lets each mode shape the post cadence without fragmenting the main loop.
    """
    if mode == 'steady':
        return lambda elapsed: (True, 'steady')

    if mode == 'jitter':
        return lambda elapsed: (True, 'jitter')

    if mode == 'stop_60s':
        # 30s posting, 60s freeze, then steady forever.
        def fn(elapsed):
            if elapsed < 30:
                return True, 'stop_60s/active'
            if elapsed < 90:
                return False, 'stop_60s/frozen'
            return True, 'stop_60s/recovered'
        return fn

    if mode == 'drop_then_recover':
        # 20s active, 90s frozen, then resume.
        def fn(elapsed):
            if elapsed < 20:
                return True, 'drop/active'
            if elapsed < 110:
                return False, 'drop/frozen'
            return True, 'drop/recovered'
        return fn

    raise ValueError(f'unknown mode {mode!r}')


def main() -> int:
    p = argparse.ArgumentParser(
        description='Fake the technician GPS broadcaster against a local backend.',
    )
    p.add_argument('--booking-id', type=int, required=True)
    p.add_argument('--token', required=True, help='Tech DRF token (Authorization: Token <token>)')
    p.add_argument('--base-url', default=DEFAULT_BASE_URL)
    p.add_argument('--start', type=parse_latlng,
                   default=parse_latlng(DEFAULT_START),
                   help=f'start lat,lng (default {DEFAULT_START})')
    p.add_argument('--dest', type=parse_latlng,
                   default=parse_latlng(DEFAULT_DEST),
                   help=f'destination lat,lng (default {DEFAULT_DEST})')
    p.add_argument('--speed', type=float, default=1.0,
                   help='speed multiplier; 1.0 ≈ 21 km/h (default 1.0)')
    p.add_argument('--interval', type=float, default=DEFAULT_INTERVAL,
                   help=f'seconds between frames (default {DEFAULT_INTERVAL})')
    p.add_argument('--mode', default='steady',
                   choices=['steady', 'jitter', 'stop_60s', 'drop_then_recover'])
    p.add_argument('--max-frames', type=int, default=None,
                   help='stop after N frames (default: run until interrupted)')
    args = p.parse_args()

    pos: Position = args.start
    dest: Position = args.dest
    step_m = METERS_PER_STEP_AT_SPEED_1 * args.speed
    handler = make_mode_handler(args.mode, args.interval)
    total_distance = haversine_m(pos, dest)

    print(
        f'[fake_tech_gps] booking={args.booking_id} '
        f'mode={args.mode} interval={args.interval}s '
        f'start=({pos.lat:.6f},{pos.lng:.6f}) '
        f'dest=({dest.lat:.6f},{dest.lng:.6f}) '
        f'distance={total_distance:.0f}m'
    )

    session = requests.Session()
    started_at = time.time()
    frame_idx = 0

    try:
        while True:
            elapsed = time.time() - started_at
            should_post, label = handler(elapsed)

            if should_post:
                # Step toward destination first, then optionally jitter.
                pos = step_toward(pos, dest, step_m)
                emit_pos = jitter(pos) if args.mode == 'jitter' else pos
                heading = initial_bearing_deg(emit_pos, dest) if pos != dest else 0.0
                status, body = post_frame(
                    session=session,
                    base_url=args.base_url,
                    booking_id=args.booking_id,
                    token=args.token,
                    pos=emit_pos,
                    heading=heading,
                )
                frame_idx += 1
                _print_frame(frame_idx, emit_pos, status, body, label)
            else:
                sys.stdout.write(f'…  ({label}) skipping post at t+{int(elapsed)}s\n')
                sys.stdout.flush()

            if args.max_frames and frame_idx >= args.max_frames:
                print(f'[fake_tech_gps] reached --max-frames={args.max_frames}; exiting.')
                return 0

            time.sleep(args.interval)

    except KeyboardInterrupt:
        print('\n[fake_tech_gps] interrupted; exiting.')
        return 0


if __name__ == '__main__':
    raise SystemExit(main())

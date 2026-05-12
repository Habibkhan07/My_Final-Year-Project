"""
Dev helper — fires a fake `job_new_request` event to the test
technician via WebSocket + FCM. Useful for manually verifying that
push notifications round-trip backend → Google FCM → device tray.

Usage (from `backend/` with venv active):
    python manage.py shell < dev_send_push.py

Background the app on your phone FIRST (press Home, don't force-kill),
then run this command. A system-tray notification should appear within
~2 seconds.

If you want to test as a different user, change PHONE below.
"""
from datetime import datetime, timedelta, timezone

from accounts.models import UserProfile
from realtime.events.services.event_dispatch_service import EventDispatchService

PHONE = '+923001234567'

profile = UserProfile.objects.get(phone=PHONE)
tech = profile.user

# Payload shape MUST match BOOKINGS_API.md §1.2 — every key is a hard
# requirement of `JobNewRequestPayloadModel.fromJson` on the Flutter side.
# A missing field throws inside the mapper, the queue stays empty, and the
# pushed screen auto-pops (flag #11).
scheduled_start = datetime.now(timezone.utc) + timedelta(hours=1)

envelope = EventDispatchService.broadcast_event(
    user=tech,
    target_role='technician',
    event_type='job_new_request',
    payload={
        'job_id': 999,
        'service_name': 'AC Repair',
        'booking_type': 'FIXED_GIG',
        'scheduled_start_iso': scheduled_start.isoformat().replace('+00:00', 'Z'),
        'payout': '1500',
        'payout_context': 'Fixed-price gig — full payout',
        'expires_in_seconds': 900,
    },
)

print('=' * 60)
print(f"Dispatched event {envelope['id']}")
print(f"  To user:   {tech.username} (phone={profile.phone})")
print(f"  Event:     job_new_request")
print(f"  Payload:   job_id=999, service=AC Repair, payout=1500")
print('=' * 60)
print('A system-tray notification should appear on the device shortly.')

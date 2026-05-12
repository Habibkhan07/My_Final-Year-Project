"""Demo / test helper: wipe every booking and related rows.

Used by ``auto_demo.py --reset`` to ensure each demo run starts on a
clean slate without stale half-walked bookings polluting the
Past / Upcoming tabs.

Deletion order matters because ``BookingItem.sourced_quote`` is
``on_delete=PROTECT``. A naive ``JobBooking.objects.all().delete()``
cascades into Quote, hits the protected FK on BookingItem, and aborts.
We delete BookingItem first (the only protected back-reference into
Quote), then JobBooking cascades cleanly to everything else
(Quote / QuoteLineItem / SupportTicket / Attachment / EventLog rows
that have ``on_delete=CASCADE``).

NOT registered as a default workflow — only callers are the demo
script and any operator running it explicitly via manage.py.
"""
from django.core.management.base import BaseCommand
from django.db import transaction

from bookings.models import BookingItem, JobBooking


class Command(BaseCommand):
    help = "Delete every JobBooking row (cascading related models)."

    @transaction.atomic
    def handle(self, *args, **opts):
        # 1. BookingItem first: its `sourced_quote` FK is PROTECT, so
        #    cascade-deleting JobBooking → Quote would otherwise abort.
        item_count, _ = BookingItem.objects.all().delete()
        # 2. JobBooking — cascades to Quote, QuoteLineItem, SupportTicket,
        #    Attachment, and EventLog rows that reference the booking.
        booking_aggregate, by_label = JobBooking.objects.all().delete()
        booking_count = by_label.get("bookings.JobBooking", 0)
        # Total = bookings + items + every cascaded sibling row.
        total = item_count + booking_aggregate
        self.stdout.write(
            f"deleted {booking_count} JobBooking row(s) "
            f"(+{total - booking_count} related rows cascaded / explicit)"
        )
        # Emit a machine-parseable last line so callers can pluck the
        # count via `splitlines()[-1]`.
        self.stdout.write(str(booking_count))

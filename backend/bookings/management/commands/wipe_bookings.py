"""Demo / test helper: wipe every booking and related rows.

Used by ``auto_demo.py --reset`` to ensure each demo run starts on a
clean slate without stale half-walked bookings polluting the
Past / Upcoming tabs.

Deletion order matters because two FKs block a naive cascade:

  * ``BookingItem.sourced_quote`` → Quote (PROTECT). JobBooking deletion
    cascades into Quote, which would then refuse because BookingItem
    still references it. We delete BookingItem first.

  * ``JobCommission.booking`` → JobBooking (PROTECT). A booking that
    reached COMPLETED has a 1:1 JobCommission row keyed off it for
    idempotency / forensic audit. We delete JobCommission rows next
    so the JobBooking cascade can proceed.

The matching WalletTransaction rows (COMMISSION_DEBIT) are
intentionally LEFT IN PLACE — wiping bookings should not retroactively
mutate ledger balances. The transactions become soft-orphans (no
JobCommission subtype row pointing at them); they still appear in
wallet history with type COMMISSION_DEBIT and the same balance_after.
That's the right trade-off for a dev wipe: ledger truth is preserved
even when narrative truth (which booking, which customer) is gone.

NOT registered as a default workflow — only callers are the demo
script and any operator running it explicitly via manage.py.
"""
from django.core.management.base import BaseCommand
from django.db import transaction

from bookings.models import BookingItem, JobBooking
from wallet.models import JobCommission


class Command(BaseCommand):
    help = "Delete every JobBooking row (cascading related models)."

    @transaction.atomic
    def handle(self, *args, **opts):
        # 1. BookingItem first: its `sourced_quote` FK is PROTECT, so
        #    cascade-deleting JobBooking → Quote would otherwise abort.
        item_count, _ = BookingItem.objects.all().delete()
        # 2. JobCommission next: PROTECT FK to JobBooking blocks the
        #    booking cascade for any booking that reached COMPLETED.
        #    Wallet ledger rows (WalletTransaction) are left intact —
        #    see module docstring for why.
        commission_count, _ = JobCommission.objects.all().delete()
        # 3. JobBooking — cascades to Quote, QuoteLineItem, SupportTicket,
        #    Attachment, and EventLog rows that reference the booking.
        booking_aggregate, by_label = JobBooking.objects.all().delete()
        booking_count = by_label.get("bookings.JobBooking", 0)
        # Total = bookings + items + commissions + every cascaded sibling row.
        total = item_count + commission_count + booking_aggregate
        self.stdout.write(
            f"deleted {booking_count} JobBooking row(s) "
            f"(+{total - booking_count} related rows cascaded / explicit)"
        )
        # Emit a machine-parseable last line so callers can pluck the
        # count via `splitlines()[-1]`.
        self.stdout.write(str(booking_count))

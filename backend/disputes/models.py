"""Refund payout intent — bank PII for an approved dispute resolution.

The dispute ticket itself is ``bookings.SupportTicket`` (created with
``dispute_intake_method=INTAKE_CHATBOT`` by the dispute persona's
``on_close``). All AI-derived metadata (summary, captured fields,
needs-review flag) lives in ``SupportTicket.chat_log`` JSON — a seam the
bookings author already designed for chatbot intake.

This app exists for one reason: ``RefundIntent`` holds the customer's
bank account details for refund payouts, and that PII deserves its own
admin permission boundary (the ``finance_admin`` group, created by the
0002 data migration). A staff member with ``view_supportticket`` does
NOT automatically get to see IBANs — they need ``view_refundintent``,
which only ``finance_admin`` has.
"""
from __future__ import annotations

from django.db import models


class RefundIntent(models.Model):
    """Bank payout details for an approved refund.

    OneToOne with ``SupportTicket`` — a ticket has at most one refund
    intent (created when the chatbot reaches the PAYOUT phase). If the
    admin later resolves with ``OUTCOME_REFUND_CUSTOMER``, finance
    operations transfers funds to these details out-of-band.
    """

    ticket = models.OneToOneField(
        "bookings.SupportTicket",
        on_delete=models.CASCADE,
        related_name="refund_intent",
    )
    bank_name = models.CharField(max_length=64)
    account_title = models.CharField(max_length=128)
    iban = models.CharField(max_length=34)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        # SECURITY: never expose bank fields in __str__. Admin list views
        # and Sentry breadcrumbs render this string — a chatty repr would
        # leak PII straight into observability tooling.
        return f"<RefundIntent for ticket #{self.ticket_id}>"

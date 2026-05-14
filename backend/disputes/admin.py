"""Django admin registration for ``RefundIntent``.

PII boundary: this admin entry is permission-gated to staff users in
the ``finance_admin`` group (created by the 0002 data migration).
Regular admin staff can triage tickets via ``bookings.admin.SupportTicketAdmin``
but cannot see customer bank details — that requires explicit
``disputes.view_refundintent`` permission, which only ``finance_admin``
members have.

Permissions deliberately restrict ALL writes:
  - has_add_permission     → False (only the chatbot service creates rows)
  - has_change_permission  → False (PII is write-once; customer re-files
                             a new dispute if details were wrong)
  - has_delete_permission  → False (audit retention; rows must survive
                             ticket resolution for finance reconciliation)

The list view deliberately HIDES the IBAN — IBAN is only shown on the
detail page, so a screenshot of the queue can be shared without leaking
account numbers. Detail page is where finance ops copy the IBAN for
out-of-band payout.
"""
from __future__ import annotations

from django.contrib import admin

from disputes.models import RefundIntent


_FINANCE_ADMIN_GROUP = "finance_admin"


def _is_finance_admin(user) -> bool:
    """True for superusers OR staff in the finance_admin group."""
    if not user.is_active or not user.is_staff:
        return False
    if user.is_superuser:
        return True
    return user.groups.filter(name=_FINANCE_ADMIN_GROUP).exists()


@admin.register(RefundIntent)
class RefundIntentAdmin(admin.ModelAdmin):
    """Read-only admin for bank-payout intents.

    IBAN is excluded from the list view (PII minimization in queue
    screenshots) but shown on the detail page where finance copies it
    for out-of-band payout.
    """

    list_display = ("id", "ticket_id_link", "bank_name", "account_title", "created_at")
    list_filter = ("bank_name", "created_at")
    search_fields = ("ticket__id", "account_title")
    readonly_fields = ("ticket", "bank_name", "account_title", "iban", "created_at")
    ordering = ("-created_at",)

    # ---- visibility/permissions -----------------------------------------

    def has_module_permission(self, request):
        # Controls whether the "Refund intents" entry appears in the
        # admin index AT ALL — staff outside finance_admin don't even
        # see it listed.
        return _is_finance_admin(request.user)

    def has_view_permission(self, request, obj=None):
        return _is_finance_admin(request.user)

    def has_add_permission(self, request):
        return False  # chatbot.personas.dispute.outputs creates rows

    def has_change_permission(self, request, obj=None):
        return False  # write-once; customer re-files for corrections

    def has_delete_permission(self, request, obj=None):
        return False  # audit retention

    # ---- list-view helpers ----------------------------------------------

    @admin.display(description="Ticket")
    def ticket_id_link(self, obj):
        from django.urls import reverse
        from django.utils.html import format_html

        # Link to the bookings admin SupportTicket change page so finance
        # can navigate ticket → refund intent in one click.
        try:
            url = reverse("admin:bookings_supportticket_change", args=[obj.ticket_id])
        except Exception:
            return f"#{obj.ticket_id}"
        return format_html('<a href="{}">#{}</a>', url, obj.ticket_id)

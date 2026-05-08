"""Django Admin registrations for the booking orchestrator models.

``BookingAttachment`` is intentionally NOT registered this sprint — its
schema is reserved for the future chatbot-intake feature; exposing the
upload UI now would imply a write surface the orchestrator doesn't yet
support. See sprint meta §11 and ``flag.md::ai-chatbot-deferred``.

``TechReliabilityIncident`` is registered as an immutable audit log: every
field is read-only and add/delete are disabled. The orchestrator is the
only writer; admin views the rows but never mutates them. The future
"reliability score" sprint will compose UI on top of this dataset; until
then it's the admin's only window into tech-cancel and tech-no-show events.

The dispute-resolve custom action (Session 2) is exposed as a per-row
"Resolve" link in ``SupportTicketAdmin``. The link routes to
``resolve_view``, which renders a small form and POSTs into
``orchestrator.admin_resolve_dispute``. No dedicated REST endpoint —
the resolution flow is admin-only and lives entirely inside Django Admin.
"""

from django.contrib import admin, messages
from django.shortcuts import redirect, render
from django.urls import path
from django.utils.html import format_html

from bookings.exceptions import BookingValidationError
from bookings.models import JobBooking
from bookings.services import orchestrator

from .models import (
    BookingItem,
    Quote,
    QuoteLineItem,
    SupportTicket,
    TechReliabilityIncident,
    TicketEvidence,
    # BookingAttachment intentionally not registered (sprint §1 decision 9).
)


class QuoteLineItemInline(admin.TabularInline):
    """Quote line items are immutable audit data — admin views them, never edits.

    ``QuoteLineItem.save`` recomputes ``line_total`` from quantity * priced_at
    on every write; making the row read-only here removes any ability for
    an admin to inadvertently desync the snapshot from the tech-submitted price.
    """
    model = QuoteLineItem
    extra = 0
    readonly_fields = ['sub_service', 'quantity', 'priced_at', 'line_total']
    can_delete = False


@admin.register(Quote)
class QuoteAdmin(admin.ModelAdmin):
    list_display = ['id', 'booking', 'revision_number', 'status', 'is_upsell', 'total_amount', 'created_at']
    list_filter = ['status', 'is_upsell']
    search_fields = ['booking__id']
    inlines = [QuoteLineItemInline]
    readonly_fields = [
        'booking', 'revision_number', 'total_amount', 'is_upsell',
        'created_at', 'submitted_at', 'decided_at',
    ]


@admin.register(BookingItem)
class BookingItemAdmin(admin.ModelAdmin):
    """Final accepted line items — finance-sprint reconciliation source.

    Read-only across the board; the orchestrator's approve_quote path is
    the only writer.
    """
    list_display = ['id', 'booking', 'sub_service', 'quantity', 'price_charged', 'line_total']
    list_filter = ['sub_service']
    search_fields = ['booking__id']
    readonly_fields = [
        'booking', 'sub_service', 'quantity', 'price_charged', 'line_total',
        'sourced_quote', 'created_at',
    ]


class TicketEvidenceInline(admin.TabularInline):
    model = TicketEvidence
    extra = 0
    readonly_fields = ['uploaded_by', 'image', 'caption', 'uploaded_at']
    can_delete = False


@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    """Dispute tickets + the per-row "Resolve" custom action.

    The resolve link only renders for OPEN tickets. POSTing the form
    invokes ``orchestrator.admin_resolve_dispute`` which:
        * flips the booking to the chosen final_status (CANCELLED /
          COMPLETED / COMPLETED_INSPECTION_ONLY) and stamps audit
          columns (cycle-2 phase 6),
        * marks the ticket RESOLVED and stamps ``resolved_by`` (cycle-2
          phase 6),
        * broadcasts ``DISPUTE_RESOLVED`` to both parties.
    Money flow (refunds, penalties) is the finance sprint's job.
    """
    list_display = [
        'id', 'booking', 'opened_by', 'status',
        'resolution_outcome', 'opened_at', 'resolve_link',
    ]
    list_filter = ['status', 'resolution_outcome', 'dispute_intake_method']
    search_fields = ['booking__id', 'opened_by__username']
    readonly_fields = [
        'booking', 'opened_by', 'dispute_intake_method', 'initial_reason',
        'chat_log', 'opened_at', 'resolved_by', 'resolved_at',
    ]
    inlines = [TicketEvidenceInline]

    def get_urls(self):
        """Inject the per-ticket resolve URL alongside the default admin URLs."""
        urls = super().get_urls()
        custom = [
            path(
                '<int:ticket_id>/resolve/',
                self.admin_site.admin_view(self.resolve_view),
                name='supportticket-resolve',
            ),
        ]
        return custom + urls

    def resolve_link(self, obj):
        """Render a Resolve link for OPEN tickets, status string for resolved."""
        if obj.status == SupportTicket.STATUS_OPEN:
            return format_html('<a href="{}/resolve/">Resolve</a>', obj.id)
        return f'Resolved ({obj.resolution_outcome})'
    resolve_link.short_description = 'Resolve'

    def resolve_view(self, request, ticket_id: int):
        """GET renders the form; POST calls the orchestrator.

        On orchestrator success: flash success message and redirect back
        to the ticket's change page.
        On ``BookingValidationError``: flash the envelope message and
        re-render the form so the admin can correct the input.
        """
        try:
            ticket = SupportTicket.objects.get(id=ticket_id)
        except SupportTicket.DoesNotExist:
            self.message_user(request, 'Ticket not found.', messages.ERROR)
            return redirect('admin:bookings_supportticket_changelist')

        if request.method == 'POST':
            outcome = request.POST.get('outcome', '')
            notes = request.POST.get('notes', '')
            final_status = request.POST.get('final_status', '')
            try:
                orchestrator.admin_resolve_dispute(
                    ticket_id=ticket.id,
                    admin_user=request.user,
                    outcome=outcome,
                    notes=notes,
                    final_status=final_status,
                )
                self.message_user(
                    request,
                    f'Ticket #{ticket.id} resolved.',
                    messages.SUCCESS,
                )
                return redirect(
                    f'../../{ticket_id}/change/'
                )
            except BookingValidationError as exc:
                self.message_user(
                    request,
                    f'Failed: {exc.message}',
                    messages.ERROR,
                )

        return render(
            request,
            'admin/bookings/supportticket/resolve.html',
            {
                'ticket': ticket,
                'outcomes': [
                    (SupportTicket.OUTCOME_REFUND_CUSTOMER, 'Refund customer'),
                    (SupportTicket.OUTCOME_PENALIZE_TECH, 'Penalize tech'),
                    (SupportTicket.OUTCOME_DISMISS, 'Dismiss'),
                ],
                'final_statuses': [
                    (JobBooking.STATUS_COMPLETED, 'Completed'),
                    (JobBooking.STATUS_COMPLETED_INSPECTION_ONLY, 'Completed (inspection only)'),
                    (JobBooking.STATUS_CANCELLED, 'Cancelled'),
                ],
            },
        )


@admin.register(TechReliabilityIncident)
class TechReliabilityIncidentAdmin(admin.ModelAdmin):
    """Append-only audit log of tech reliability events.

    Audit P0-08: Django Admin's ``readonly_fields`` does not accept the
    string ``'__all__'`` (no special case — it would be looked up as a
    literal field name and silently fail). Override ``get_readonly_fields``
    to return every field; pair with ``has_add_permission=False`` and
    ``has_delete_permission=False`` so the admin surface is strictly
    view-only.
    """
    list_display = ['id', 'technician', 'booking', 'incident_type', 'phase', 'created_at']
    list_filter = ['incident_type']
    search_fields = ['technician__user__username', 'booking__id']

    def get_readonly_fields(self, request, obj=None):
        return [f.name for f in self.model._meta.fields]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

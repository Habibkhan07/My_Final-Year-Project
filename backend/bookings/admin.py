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

The dispute-resolve admin action (custom button → orchestrator.admin_resolve_dispute)
is wired in session 2.
"""

from django.contrib import admin

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
    """Dispute tickets. The resolve-dispute custom action button (which
    invokes ``orchestrator.admin_resolve_dispute``) is wired in session 2.
    Until then, admins can view tickets and their evidence; resolution
    happens through a future admin action or manual ORM call.
    """
    list_display = ['id', 'booking', 'opened_by', 'status', 'resolution_outcome', 'opened_at']
    list_filter = ['status', 'resolution_outcome', 'dispute_intake_method']
    search_fields = ['booking__id', 'opened_by__username']
    readonly_fields = [
        'booking', 'opened_by', 'dispute_intake_method', 'initial_reason',
        'chat_log', 'opened_at',
    ]
    inlines = [TicketEvidenceInline]


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

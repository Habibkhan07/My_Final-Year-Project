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
from django.db.models import Count, Q
from django.shortcuts import redirect, render
from django.urls import path, reverse
from django.utils.html import format_html
from django.utils.safestring import mark_safe

from bookings.exceptions import BookingValidationError
from bookings.models import JobBooking
from bookings.services import orchestrator
from core.common.admin_permissions import EngineerOnlyAdminMixin
from core.common.admin_ui import lightbox_thumb, money_rs, pill

from .models import (
    BookingItem,
    Quote,
    QuoteLineItem,
    SupportTicket,
    TechReliabilityIncident,
    TicketEvidence,
    # BookingAttachment intentionally not registered (sprint §1 decision 9).
)


# --- PII redaction for chat_log -----------------------------------------

import re as _re

# Pakistani IBAN format: PK + 2 check digits + 16-30 alphanumeric.
_IBAN_RE = _re.compile(r'\bPK\d{2}[A-Z0-9]{11,30}\b', _re.IGNORECASE)
# E.164 / local Pakistan mobile (10–15 digits with optional + and dashes/spaces).
_PHONE_RE = _re.compile(r'\b(?:\+?\d{1,3}[-.\s]?)?\d{3,5}[-.\s]?\d{4,8}\b')
# Pakistani CNIC: 5-7-1 grouped digits.
_CNIC_RE = _re.compile(r'\b\d{5}-?\d{7}-?\d\b')

_REDACTED_KEYS = {'iban', 'account_number', 'account_no', 'account_title', 'bank_account'}


def _redact_text(s: str) -> str:
    if not isinstance(s, str):
        return s
    s = _IBAN_RE.sub('[redacted IBAN]', s)
    s = _CNIC_RE.sub('[redacted CNIC]', s)
    s = _PHONE_RE.sub('[redacted phone]', s)
    return s


def _redact_chat_log(value):
    """Recursively scrub PII from a chat_log JSON value."""
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            if k.lower() in _REDACTED_KEYS:
                out[k] = '[redacted]'
            else:
                out[k] = _redact_chat_log(v)
        return out
    if isinstance(value, list):
        return [_redact_chat_log(v) for v in value]
    if isinstance(value, str):
        return _redact_text(value)
    return value


# Status → tone mapping. Mirrors the customer-side canonical table in
# CUSTOMER_BOOKINGS_API.md §1.7 — divergence here is a bug.
_STATUS_TONES: dict[str, str] = {
    JobBooking.STATUS_AWAITING_TECH_ACCEPT: 'warning',
    JobBooking.STATUS_CONFIRMED: 'positive',
    JobBooking.STATUS_EN_ROUTE: 'info',
    JobBooking.STATUS_ARRIVED: 'info',
    JobBooking.STATUS_INSPECTING: 'info',
    JobBooking.STATUS_QUOTED: 'warning',
    JobBooking.STATUS_IN_PROGRESS: 'info',
    JobBooking.STATUS_COMPLETED: 'positive',
    JobBooking.STATUS_COMPLETED_INSPECTION_ONLY: 'neutral',
    JobBooking.STATUS_CANCELLED: 'neutral',
    JobBooking.STATUS_REJECTED: 'negative',
    JobBooking.STATUS_NO_SHOW: 'negative',
    JobBooking.STATUS_DISPUTED: 'negative',
    JobBooking.STATUS_PENDING: 'neutral',
}


class QuoteInline(admin.TabularInline):
    """Quotes attached to a booking — read-only audit view."""
    model = Quote
    extra = 0
    can_delete = False
    fields = ('revision_number', 'status', 'is_upsell', 'total_amount', 'submitted_at', 'decided_at')
    readonly_fields = fields
    show_change_link = True
    ordering = ('revision_number',)


class BookingItemInline(admin.TabularInline):
    """Accepted line items snapshot — the immutable cash-collected receipt."""
    model = BookingItem
    extra = 0
    can_delete = False
    fields = ('sub_service', 'quantity', 'price_charged', 'line_total', 'sourced_quote', 'created_at')
    readonly_fields = fields


class TicketInline(admin.TabularInline):
    """Disputes opened against a booking — link out to resolve."""
    model = SupportTicket
    extra = 0
    can_delete = False
    fields = ('id', 'opened_by', 'dispute_intake_method', 'status', 'resolution_outcome', 'opened_at')
    readonly_fields = fields
    show_change_link = True


@admin.register(JobBooking)
class JobBookingAdmin(admin.ModelAdmin):
    """Master view of every booking in the system.

    The single highest-traffic admin page in the app: supervisor uses
    this to spot-check live bookings, audit edge-case status flows, and
    confirm that orchestrator transitions actually stamped the right
    columns. Therefore:

    * Read-mostly. Status, timestamps, and pricing are stamped by the
      orchestrator under select_for_update — admin SHOULD NOT write
      directly. Every business-relevant column is read-only; the change
      form is for inspection, not mutation.
    * Inline quote + item + ticket trios make the booking detail self-
      contained — no hunting through three other tabs.
    * Filters cover the way an admin actually slices a queue: status
      tone, service category, recency.
    """

    list_display = (
        'status_pill',
        'service_label',
        'customer_link',
        'technician_link',
        'scheduled_start',
        'price_label',
        'cash_label',
        'tickets_badge',
    )
    list_filter = ('status', 'service')
    search_fields = (
        'id',
        'customer__username',
        'customer__first_name',
        'customer__last_name',
        'technician__user__username',
        'technician__user__first_name',
        'technician__user__last_name',
        'technician__cnic_number',
        'service__name',
        'sub_service__name',
    )
    date_hierarchy = 'scheduled_start'
    ordering = ('-scheduled_start',)
    list_per_page = 30
    list_select_related = (
        'customer',
        'technician',
        'technician__user',
        'service',
        'sub_service',
        'address',
    )
    raw_id_fields = ('customer', 'technician', 'address', 'parent_booking')
    inlines = [QuoteInline, BookingItemInline, TicketInline]
    save_on_top = True

    # SECURITY: status / pricing / phase / schedule / catalog columns are
    # mutated only via the orchestrator under ``select_for_update``. Admin
    # must never bypass that — every business-meaningful field is therefore
    # read-only on the change form. Mutation surfaces (resolve dispute,
    # cancel, etc.) live in dedicated admin actions or orchestrator API
    # endpoints, never the default save button.
    readonly_fields = (
        # Status / catalog intent (orchestrator-owned)
        'status',
        'service',
        'sub_service',
        'promotion',
        'price_context',
        'cash_collection_method',
        # Schedule (only reschedule transitions move these)
        'scheduled_start',
        'scheduled_end',
        'address',
        # Timestamps
        'created_at',
        'accepted_at',
        'en_route_started_at',
        'arrived_at',
        'customer_acknowledged_arrival_at',
        'inspection_started_at',
        'quote_first_submitted_at',
        'work_started_at',
        'completed_at',
        'cash_collected_at',
        'cancelled_at',
        'cancelled_by',
        'cancel_reason',
        'no_show_at',
        'no_show_actor',
        'dispute_opened_at',
        # Pricing (orchestrator-stamped)
        'price_amount',
        'final_cash_to_collect',
        'cash_collected_amount',
        'inspection_fee',
        'base_services_total',
        'discount_applied',
        'promo_code_snapshot',
        'promo_discount_snapshot',
        'actual_address_snapshot',
        'parent_booking',
        # Counterparties (changing these mid-flight would corrupt state)
        'customer',
        'technician',
    )

    fieldsets = (
        ('Parties', {
            'fields': ('customer', 'technician', 'address'),
        }),
        ('Catalog intent', {
            'fields': ('service', 'sub_service', 'promotion'),
        }),
        ('Schedule', {
            'fields': ('scheduled_start', 'scheduled_end', 'status', 'created_at'),
        }),
        ('Phase timestamps', {
            'classes': ('collapse',),
            'fields': (
                'accepted_at',
                'en_route_started_at',
                'arrived_at',
                'customer_acknowledged_arrival_at',
                'inspection_started_at',
                'quote_first_submitted_at',
                'work_started_at',
                'completed_at',
            ),
        }),
        ('Pricing & cash', {
            'fields': (
                'price_amount',
                'price_context',
                'inspection_fee',
                'base_services_total',
                'discount_applied',
                'final_cash_to_collect',
                'cash_collected_amount',
                'cash_collected_at',
                'cash_collection_method',
            ),
        }),
        ('Promo snapshot', {
            'classes': ('collapse',),
            'fields': ('promo_code_snapshot', 'promo_discount_snapshot'),
        }),
        ('Address snapshot', {
            'classes': ('collapse',),
            'fields': ('actual_address_snapshot',),
        }),
        ('Termination audit', {
            'classes': ('collapse',),
            'fields': (
                'cancelled_at', 'cancelled_by', 'cancel_reason',
                'no_show_at', 'no_show_actor',
                'dispute_opened_at',
                'parent_booking',
            ),
        }),
    )

    def get_queryset(self, request):
        # Annotate OPEN-ticket count so the badge is one SQL, not N+1.
        # Resolved tickets are not "open work" and must not light up the
        # warning pill.
        return (
            super()
            .get_queryset(request)
            .annotate(
                _open_ticket_count=Count(
                    'tickets',
                    filter=Q(tickets__status=SupportTicket.STATUS_OPEN),
                ),
            )
        )

    @admin.display(description='Status', ordering='status')
    def status_pill(self, obj: JobBooking):
        tone = _STATUS_TONES.get(obj.status, 'neutral')
        return pill(obj.get_status_display(), tone)

    @admin.display(description='Service', ordering='service__name')
    def service_label(self, obj: JobBooking):
        if obj.sub_service_id:
            return format_html(
                '<div style="line-height:1.3"><div style="font-weight:600">{}</div>'
                '<div style="color:#6b7280;font-size:11px">{}</div></div>',
                obj.sub_service.name,
                obj.service.name,
            )
        return obj.service.name

    @admin.display(description='Customer', ordering='customer__username')
    def customer_link(self, obj: JobBooking):
        try:
            url = reverse('admin:auth_user_change', args=[obj.customer_id])
        except Exception:
            return obj.customer.get_full_name() or obj.customer.username
        return format_html(
            '<a href="{}">{}</a>',
            url,
            obj.customer.get_full_name() or obj.customer.username,
        )

    @admin.display(description='Technician', ordering='technician__user__username')
    def technician_link(self, obj: JobBooking):
        try:
            url = reverse('admin:technicians_technicianprofile_change', args=[obj.technician_id])
        except Exception:
            return obj.technician.user.get_full_name() or obj.technician.user.username
        return format_html(
            '<a href="{}">{}</a>',
            url,
            obj.technician.user.get_full_name() or obj.technician.user.username,
        )

    @admin.display(description='Price', ordering='price_amount')
    def price_label(self, obj: JobBooking):
        return money_rs(obj.price_amount)

    @admin.display(description='Cash')
    def cash_label(self, obj: JobBooking):
        if obj.cash_collected_amount is not None:
            return format_html(
                '<span style="color:#166534;font-weight:600">{}</span>',
                money_rs(obj.cash_collected_amount),
            )
        if obj.final_cash_to_collect is not None:
            return format_html(
                '<span style="color:#6b7280">due {}</span>',
                money_rs(obj.final_cash_to_collect),
            )
        return '—'

    @admin.display(description='Tickets')
    def tickets_badge(self, obj: JobBooking):
        count = getattr(obj, '_open_ticket_count', 0)
        if not count:
            return '—'
        label = '1 open' if count == 1 else f'{count} open'
        return pill(label, 'negative')

    def change_view(self, request, object_id, form_url='', extra_context=None):
        """Inject a Resolve action panel above the form on DISPUTED bookings.

        Surfaces the dispute-resolution flow at the top of the page so the
        admin doesn't have to scroll to the Tickets inline and click
        through. The panel routes to the most recent OPEN ticket's
        existing Resolve view (which calls
        ``orchestrator.admin_resolve_dispute``).
        """
        extra_context = dict(extra_context or {})
        try:
            booking = JobBooking.objects.get(pk=object_id)
        except JobBooking.DoesNotExist:
            booking = None

        if booking and booking.status == JobBooking.STATUS_DISPUTED:
            open_ticket = (
                SupportTicket.objects
                .filter(booking=booking, status=SupportTicket.STATUS_OPEN)
                .order_by('-opened_at')
                .first()
            )
            if open_ticket:
                extra_context['fx_action_panel'] = {
                    'title': 'This booking is disputed',
                    'sub': (f'Open ticket #{open_ticket.id} — resolve via the '
                            'dispute workflow (writes audit columns + broadcasts '
                            'DISPUTE_RESOLVED to both parties).'),
                    'resolve_url': reverse(
                        'admin:bookings_supportticket_changelist',
                    ) + f'{open_ticket.id}/resolve/',
                    'ticket_url': reverse(
                        'admin:bookings_supportticket_change', args=[open_ticket.id],
                    ),
                }
        return super().change_view(request, object_id, form_url, extra_context)

    def has_add_permission(self, request):
        # Bookings are created via the customer checkout API. Admin-side
        # creation would bypass the entire defensive-check pipeline.
        return False

    def has_delete_permission(self, request, obj=None):
        # Bookings are PROTECT-FK'd from multiple ledger surfaces — deleting
        # one would orphan commission, items, tickets, attachments.
        return False


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


# Quote standalone admin unregistered: Quotes are inline on
# JobBooking's change page (QuoteInline); no admin action operates on
# a Quote independently of its booking.
class QuoteAdmin(EngineerOnlyAdminMixin, admin.ModelAdmin):
    """Quote audit. All mutation goes through orchestrator.submit_quote.

    Admin-side add would violate ``unique_submitted_quote_per_booking_flavour``
    (partial unique index); admin-side delete would orphan
    ``BookingItem.sourced_quote`` (PROTECT FK) and break finance
    reconciliation. Both disabled.
    """
    list_display = ['id', 'booking_link', 'revision_number', 'status_pill',
                    'is_upsell', 'total_amount_label', 'created_at']
    list_filter = ['status', 'is_upsell']
    search_fields = ['booking__id', 'booking__customer__username',
                     'booking__technician__user__username']
    date_hierarchy = 'created_at'
    ordering = ('-created_at',)
    list_per_page = 40
    list_select_related = ('booking', 'booking__customer', 'booking__technician__user')
    inlines = [QuoteLineItemInline]
    readonly_fields = [
        'booking', 'revision_number', 'status', 'total_amount', 'is_upsell',
        'decision_reason', 'created_at', 'submitted_at', 'decided_at',
    ]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    @admin.display(description='Booking', ordering='booking_id')
    def booking_link(self, obj):
        url = reverse('admin:bookings_jobbooking_change', args=[obj.booking_id])
        return format_html('<a href="{}">#{}</a>', url, obj.booking_id)

    @admin.display(description='Status', ordering='status')
    def status_pill(self, obj):
        tone = {
            Quote.STATUS_DRAFT: 'neutral',
            Quote.STATUS_SUBMITTED: 'warning',
            Quote.STATUS_APPROVED: 'positive',
            Quote.STATUS_DECLINED: 'negative',
            Quote.STATUS_SUPERSEDED: 'neutral',
        }.get(obj.status, 'neutral')
        return pill(obj.get_status_display(), tone)

    @admin.display(description='Total', ordering='total_amount')
    def total_amount_label(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-weight:600">{}</span>',
            money_rs(obj.total_amount),
        )


# BookingItem standalone admin unregistered: inline on JobBooking
# (BookingItemInline) serves the only operational need.
class BookingItemAdmin(EngineerOnlyAdminMixin, admin.ModelAdmin):
    """Final accepted line items — finance-sprint reconciliation source.

    Read-only across the board; the orchestrator's approve_quote path is
    the only writer. Admin-side add would bypass the snapshot pipeline
    and desync commission reconciliation; admin-side delete would orphan
    the cumulative cash-collected total.
    """
    list_display = ['id', 'booking_link', 'sub_service', 'quantity',
                    'price_label', 'line_total_label', 'created_at']
    list_filter = ['sub_service']
    search_fields = ['booking__id']
    date_hierarchy = 'created_at'
    ordering = ('-created_at',)
    list_per_page = 50
    list_select_related = ('booking', 'sub_service')
    readonly_fields = [
        'booking', 'sub_service', 'quantity', 'price_charged', 'line_total',
        'sourced_quote', 'created_at',
    ]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    @admin.display(description='Booking', ordering='booking_id')
    def booking_link(self, obj):
        url = reverse('admin:bookings_jobbooking_change', args=[obj.booking_id])
        return format_html('<a href="{}">#{}</a>', url, obj.booking_id)

    @admin.display(description='Price', ordering='price_charged')
    def price_label(self, obj):
        return money_rs(obj.price_charged)

    @admin.display(description='Line total', ordering='line_total')
    def line_total_label(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-weight:600">{}</span>',
            money_rs(obj.line_total),
        )


class TicketEvidenceInline(admin.TabularInline):
    """Evidence photo gallery for a dispute ticket.

    The ``image`` field was previously in ``readonly_fields`` directly,
    which Django renders as the upload-path string (e.g.
    ``dispute_evidence/foo.jpg``) — supervisors couldn't see the photo
    without manually pasting the URL. ``evidence_thumb`` swaps that for
    a click-to-zoom lightbox.
    """
    model = TicketEvidence
    extra = 0
    fields = ('evidence_thumb', 'uploaded_by', 'caption', 'uploaded_at')
    readonly_fields = ('evidence_thumb', 'uploaded_by', 'caption', 'uploaded_at')
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False

    @admin.display(description='Evidence')
    def evidence_thumb(self, obj):
        return lightbox_thumb(obj.image, size=120, alt='Dispute evidence')


class _NeedsReviewFilter(admin.SimpleListFilter):
    """Triage filter: AI-flagged disputes need a closer look.

    ``chat_log.needs_review=True`` is set by the chatbot dispute persona
    when the summary-validation step trips (LLM may have hallucinated)
    OR when the UNDERSTAND turn-cap force-advanced past missing
    required fields.

    JSON field lookups go through MySQL's JSON_EXTRACT — Django's
    ``__needs_review`` shorthand isn't available for arbitrary JSON,
    so use the explicit ``chat_log__needs_review`` keyed lookup which
    Django translates correctly on MySQL 8+.
    """
    title = 'AI flagged'
    parameter_name = 'needs_review'

    def lookups(self, request, model_admin):
        return (
            ('1', 'Yes — needs review'),
            ('0', 'No — clean'),
        )

    def queryset(self, request, queryset):
        val = self.value()
        if val == '1':
            return queryset.filter(chat_log__needs_review=True)
        if val == '0':
            return queryset.exclude(chat_log__needs_review=True)
        return queryset


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
        'booking', 'opened_by', 'status',
        'outcome_pill', 'penalty_label', 'needs_review_badge',
        'opened_at', 'chatbot_link', 'resolve_link',
    ]
    list_filter = ['status', _NeedsReviewFilter]
    search_fields = [
        'booking__id', 'opened_by__username', 'external_refund_reference',
    ]
    list_select_related = ('booking', 'opened_by', 'resolved_by')
    # All write-once fields read-only. ``resolution_*`` are written by
    # ``orchestrator.admin_resolve_dispute`` via the Resolve form below;
    # admin must not edit them via the default save button. Pre-fix, the
    # admin could write resolution_notes via the change form but never
    # see them again (notes were missing from readonly_fields), which
    # broke the audit trail.
    # NOTE: ``chat_log`` is intentionally NOT in readonly_fields — it's
    # rendered via the redacted ``chat_log_render`` callable below so
    # IBANs / phone / CNIC patterns are scrubbed unless the caller is in
    # the ``finance_admin`` group. Putting the raw field in
    # readonly_fields would leak the same PII that the RefundIntent
    # admin gate is designed to protect.
    readonly_fields = [
        'booking', 'opened_by', 'dispute_intake_method', 'initial_reason',
        'chat_log_render', 'opened_at', 'resolved_by', 'resolved_at',
        'status', 'resolution_outcome', 'resolution_notes',
        'tech_penalty_percentage', 'external_refund_reference',
        'customer_notification_message',
        'ai_summary_render', 'captured_fields_render',
    ]
    fieldsets = (
        ('Ticket', {
            'fields': (
                'booking', 'opened_by', 'dispute_intake_method',
                'initial_reason', 'status', 'opened_at',
            ),
        }),
        ('Resolution', {
            'description': 'Filled by the Resolve action — not editable here. '
                           'Tech penalty applied via REFUND_DEBIT in the wallet ledger.',
            'fields': (
                'resolution_outcome', 'tech_penalty_percentage',
                'external_refund_reference', 'customer_notification_message',
                'resolution_notes', 'resolved_by', 'resolved_at',
            ),
        }),
        ('AI intake', {
            'classes': ('collapse',),
            'fields': (
                'ai_summary_render', 'captured_fields_render', 'chat_log_render',
            ),
        }),
    )
    inlines = [TicketEvidenceInline]
    # Hide the Save / Save-and-continue / Save-and-add-another submit
    # row. Every field is read-only, so submission is a no-op that
    # confuses the operator. The ticket's only write path is the
    # custom Resolve view above the form.
    save_as = False
    save_as_continue = False
    save_on_top = False

    def has_add_permission(self, request):
        # Tickets are opened via POST /api/bookings/{id}/disputes/ — admin
        # creation bypasses the DISPUTED status flip and broadcast.
        return False

    def has_change_permission(self, request, obj=None):
        # Read-only surface. Mutations come exclusively from the
        # Resolve action (custom URL). Returning False here would 403
        # the change-page itself, so we override the saved-row template
        # context via ``render_change_form`` instead.
        return True

    def has_delete_permission(self, request, obj=None):
        return False

    def render_change_form(self, request, context, add=False, change=False, form_url='', obj=None):
        """Strip the submit row buttons on the read-only ticket detail page.

        Setting these flags on the change-form context tells Django's
        ``submit_line.html`` to omit the Save / Save-and-continue /
        Save-and-add-another buttons. The change form still renders;
        only the bottom action bar disappears.
        """
        context.update({
            'show_save': False,
            'show_save_and_continue': False,
            'show_save_and_add_another': False,
            'show_delete': False,
        })
        return super().render_change_form(request, context, add, change, form_url, obj)

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

    @admin.display(description='Resolve')
    def resolve_link(self, obj):
        """Render a Resolve quick-action for OPEN tickets, status pill for resolved."""
        if obj.status == SupportTicket.STATUS_OPEN:
            return format_html(
                '<a class="fx-qbtn fx-qbtn-process" href="{}/resolve/">⚖ Resolve</a>',
                obj.id,
            )
        return pill(f'Resolved ({obj.get_resolution_outcome_display()})', 'neutral')

    @admin.display(description='Chatbot')
    def chatbot_link(self, obj):
        """Link to the live chatbot Conversation for CHATBOT-intake tickets.

        The dispute persona persists ``conversation_id`` inside
        ``SupportTicket.chat_log`` JSON. Surfacing the link here closes
        the supervisor's "show me the transcript" click-path — otherwise
        they'd have to copy the id from chat_log and paste it into the
        chatbot URL by hand.
        """
        if not obj.chat_log:
            return '—'
        conv_id = (obj.chat_log or {}).get('conversation_id')
        if not conv_id:
            return '—'
        try:
            url = reverse('admin:chatbot_conversation_change', args=[conv_id])
        except Exception:
            return f'#{conv_id}'
        return format_html(
            '<a class="fx-qbtn fx-qbtn-ghost" href="{}">View transcript</a>',
            url,
        )

    @admin.display(description='AI flagged')
    def needs_review_badge(self, obj):
        flagged = bool((obj.chat_log or {}).get('needs_review'))
        if not flagged:
            return '—'
        return pill('Needs review', 'negative')

    @admin.display(description='Outcome', ordering='resolution_outcome')
    def outcome_pill(self, obj):
        """Color-coded outcome pill for the changelist.

        Maps the new binary outcomes (and the legacy three-way set,
        retained for old rows) to a consistent visual language so the
        admin scans for "accepted" vs "rejected" at a glance.
        """
        oc = obj.resolution_outcome
        if oc == SupportTicket.OUTCOME_ACCEPT_REFUND:
            return pill('Refunded', 'positive')
        if oc == SupportTicket.OUTCOME_REJECT:
            return pill('Rejected', 'neutral')
        # Legacy mappings (read-only — never written by current code).
        if oc == SupportTicket.OUTCOME_REFUND_CUSTOMER:
            return pill('Refunded (legacy)', 'positive')
        if oc == SupportTicket.OUTCOME_PENALIZE_TECH:
            return pill('Penalized (legacy)', 'warning')
        if oc == SupportTicket.OUTCOME_DISMISS:
            return pill('Dismissed (legacy)', 'neutral')
        return '—'

    @admin.display(description='Tech share', ordering='tech_penalty_percentage')
    def penalty_label(self, obj):
        """Show penalty% for accepted refunds; em-dash otherwise.

        Only meaningful on ACCEPT_REFUND outcomes; on REJECT and
        unresolved tickets the column reads as a clean em-dash so the
        changelist doesn't lie about a charge that never happened.
        """
        if (
            obj.resolution_outcome == SupportTicket.OUTCOME_ACCEPT_REFUND
            and obj.tech_penalty_percentage is not None
        ):
            pct = obj.tech_penalty_percentage
            tone = 'negative' if pct >= 50 else ('warning' if pct > 0 else 'neutral')
            return pill(f'{pct}%', tone)
        return '—'

    @admin.display(description='AI summary')
    def ai_summary_render(self, obj):
        """The chatbot's 2-4 sentence summary, styled as a callout.

        ``chat_log.ai_summary`` (plus ``ai_summary_lang``) is produced
        by the persona at conversation close. Highlighted because it's
        the marquee proof that the AI extracted something.
        """
        log = obj.chat_log or {}
        summary = log.get('ai_summary')
        lang = log.get('ai_summary_lang')
        if not summary:
            return format_html('<em style="color:#9ca3af">{}</em>', '— no AI summary —')
        lang_pill = (
            f'<span style="display:inline-block;padding:1px 6px;background:#dbeafe;'
            f'color:#1e40af;border-radius:8px;font-size:10px;margin-left:6px;'
            f'font-weight:600">{lang}</span>'
            if lang else ''
        )
        return format_html(
            '<div style="padding:12px 14px;background:#dbeafe;border-left:4px solid '
            '#2563eb;border-radius:0 8px 8px 0;max-width:720px;line-height:1.5;'
            'color:#0f172a">'
            '<div style="font-size:11px;text-transform:uppercase;letter-spacing:0.04em;'
            'color:#1e40af;font-weight:700;margin-bottom:4px">AI-generated summary{}</div>'
            '<div>{}</div></div>',
            mark_safe(lang_pill), summary,
        )

    @admin.display(description='Captured fields (structured)')
    def captured_fields_render(self, obj):
        """Render ``chat_log.captured_fields`` as a clean key/value table.

        The persona's UNDERSTAND phase distils the user's narrative
        into a small dict (issue_summary, amount_paid, date_of_failure,
        contacted_technician, etc.). Raw JSON understates the value;
        a table demonstrates that the AI extracts structured data.

        Bank-related captured fields (``iban`` / ``account_*``) are
        REDACTED here too unless caller is finance_admin — same policy
        as ``chat_log_render``.
        """
        from core.common.admin_permissions import is_finance_admin

        fields = (obj.chat_log or {}).get('captured_fields') or {}
        if not fields:
            return format_html('<em style="color:#9ca3af">{}</em>', '— no captured fields —')

        request = getattr(self, '_request', None)
        finance = bool(request and is_finance_admin(request.user))

        rows = []
        for key, val in fields.items():
            if key.lower() in _REDACTED_KEYS and not finance:
                val_display = '[redacted]'
            else:
                val_display = _redact_text(str(val)) if not finance else str(val)
            rows.append(
                format_html(
                    '<tr><td style="padding:6px 14px 6px 0;color:#475569;'
                    'font-weight:600;text-transform:capitalize">{}</td>'
                    '<td style="padding:6px 0;font-family:ui-monospace,monospace">'
                    '{}</td></tr>',
                    key.replace('_', ' '),
                    val_display,
                )
            )
        return format_html(
            '<table style="font-size:13px;border-collapse:collapse">{}</table>',
            mark_safe(''.join(str(r) for r in rows)),
        )

    @admin.display(description='Chat log (redacted unless finance_admin)')
    def chat_log_render(self, obj):
        """Pretty-print chat_log JSON with PII redacted for non-finance staff.

        ``chat_log`` contains:
          * ``messages[].text`` — full user/bot transcript including any
            phone / CNIC / IBAN the customer typed.
          * ``captured_fields`` — including ``iban``, ``account_title``,
            ``account_*`` fields.
          * ``attachments`` — file paths.

        Finance admins (the ``finance_admin`` group + superusers) see
        the unredacted JSON because they need IBANs to process refunds.
        Everyone else sees a redacted view — IBAN-like patterns become
        ``[redacted IBAN]``, phone-like patterns become ``[redacted
        phone]``, captured bank fields are stripped from the JSON.
        """
        import copy
        import json
        import re

        if not obj.chat_log:
            return format_html('<em style="color:#9ca3af">{}</em>', '— no chat log —')

        # Defer the import to avoid circular: bookings.admin → core.common
        # → no FK back to bookings. Safe either way.
        from core.common.admin_permissions import is_finance_admin

        request = getattr(self, '_request', None)
        finance = bool(request and is_finance_admin(request.user))

        payload = copy.deepcopy(obj.chat_log)

        if not finance:
            payload = _redact_chat_log(payload)

        pretty = json.dumps(payload, indent=2, ensure_ascii=False, default=str)
        banner = '' if finance else (
            '<div style="padding:8px 12px;background:#fef3c7;border-left:4px solid '
            '#f59e0b;border-radius:0 6px 6px 0;margin-bottom:8px;font-size:12px;'
            'color:#92400e">Bank PII redacted. Finance admins see unredacted '
            'data.</div>'
        )
        return format_html(
            '{}<pre style="margin:0;font-size:12px;background:#f9fafb;'
            'padding:10px 12px;border-radius:6px;max-width:780px;'
            'white-space:pre-wrap;line-height:1.45">{}</pre>',
            mark_safe(banner), pretty,
        )

    def get_object(self, request, object_id, from_field=None):
        # Stash the request so chat_log_render can consult the caller's
        # group membership without threading it through every callable.
        self._request = request
        return super().get_object(request, object_id, from_field=from_field)

    def change_view(self, request, object_id, form_url='', extra_context=None):
        """Always route to the unified dispute review page.

        The default Django model change form renders raw JSON and a
        bag of read-only fields — useless for the operator. The
        ``resolve_view`` below is the single home page for a dispute:
        identity, evidence, transcript, AI summary, captured fields,
        and (for OPEN tickets) the resolution form.
        """
        try:
            # Validate the id exists before redirecting; if not, fall
            # through to Django's default 404 handler.
            SupportTicket.objects.only('id').get(pk=object_id)
        except (SupportTicket.DoesNotExist, ValueError):
            return super().change_view(request, object_id, form_url, extra_context)
        return redirect('admin:supportticket-resolve', ticket_id=object_id)

    def resolve_view(self, request, ticket_id: int):
        """Unified dispute review + resolution page.

        Single screen for every dispute, OPEN or RESOLVED. The page
        renders: ticket header, AI summary card (chatbot intake only),
        captured fields table, evidence photo grid, message transcript
        (chat-bubble layout), and either the resolution form (OPEN) or
        the resolution outcome read-only (RESOLVED). No bouncing to
        the chatbot admin — every piece of the dispute is here.

        POST is accepted only when the ticket is OPEN. Validation
        errors flash and re-render; success redirects to the changelist.
        """
        try:
            ticket = (
                SupportTicket.objects
                .select_related('booking__customer', 'booking__technician__user', 'opened_by', 'resolved_by')
                .get(id=ticket_id)
            )
        except SupportTicket.DoesNotExist:
            self.message_user(request, 'Ticket not found.', messages.ERROR)
            return redirect('admin:bookings_supportticket_changelist')

        is_open = ticket.status == SupportTicket.STATUS_OPEN

        if request.method == 'POST' and is_open:
            outcome = request.POST.get('outcome', '')
            notes = request.POST.get('notes', '')
            penalty_raw = request.POST.get('tech_penalty_percentage', '0') or '0'
            ext_ref = request.POST.get('external_refund_reference', '') or ''
            customer_msg = request.POST.get('customer_notification_message', '') or ''
            try:
                penalty_int = int(penalty_raw)
            except ValueError:
                penalty_int = -1
            # Derive the terminal booking status from the chosen outcome
            # here in the admin layer — the orchestrator's contract still
            # takes final_status explicitly. Mapping:
            #   ACCEPT_REFUND → CANCELLED (job undone, customer refunded)
            #   REJECT        → COMPLETED (job upheld as good)
            if outcome == SupportTicket.OUTCOME_ACCEPT_REFUND:
                derived_final_status = JobBooking.STATUS_CANCELLED
            else:
                derived_final_status = JobBooking.STATUS_COMPLETED
            try:
                orchestrator.admin_resolve_dispute(
                    ticket_id=ticket.id,
                    admin_user=request.user,
                    outcome=outcome,
                    notes=notes,
                    final_status=derived_final_status,
                    tech_penalty_percentage=penalty_int,
                    external_refund_reference=ext_ref,
                    customer_notification_message=customer_msg,
                )
                if outcome == SupportTicket.OUTCOME_ACCEPT_REFUND:
                    msg = (
                        f'Ticket #{ticket.id} resolved: refund accepted. '
                        f'Tech wallet debited {penalty_int}% of refund base.'
                    )
                else:
                    msg = f'Ticket #{ticket.id} resolved: dispute rejected.'
                self.message_user(request, msg, messages.SUCCESS)
                return redirect('admin:bookings_supportticket_changelist')
            except BookingValidationError as exc:
                self.message_user(request, f'Failed: {exc.message}', messages.ERROR)

        # ---- Pull display data once — every piece flows into the template.

        # Evidence: TicketEvidence rows (FORM intake) or chatbot
        # attachments (CHATBOT intake). Convert each to a uniform
        # (url, caption) tuple so the template stays dumb.
        evidence_photos: list[dict] = []
        if ticket.dispute_intake_method == SupportTicket.INTAKE_FORM:
            for ev in ticket.evidence.select_related('uploaded_by').all():
                if ev.image:
                    evidence_photos.append({
                        'url': ev.image.url,
                        'caption': ev.caption or 'Evidence photo',
                        'uploaded_by': (
                            ev.uploaded_by.get_full_name()
                            or ev.uploaded_by.username
                        ),
                    })
        else:
            conv_id = (ticket.chat_log or {}).get('conversation_id')
            if conv_id:
                try:
                    from chatbot.models import Attachment as _Att
                    for att in _Att.objects.filter(conversation_id=conv_id):
                        if att.file:
                            evidence_photos.append({
                                'url': att.file.url,
                                'caption': 'Chat attachment',
                                'uploaded_by': att.mime_type or 'image',
                            })
                except Exception:
                    pass

        # PII gating — finance sees unredacted; everyone else gets
        # IBAN / phone / CNIC patterns scrubbed from message text.
        from core.common.admin_permissions import is_finance_admin
        finance = is_finance_admin(request.user)

        # Chat bubbles. For CHATBOT intake we pull ``chat_log.messages``
        # (a [{role, text}, ...] array stamped at conversation close).
        # FORM intake has no chat — the template shows ``initial_reason``
        # in a prose block instead.
        chat_messages: list[dict] = []
        if ticket.chat_log:
            for m in (ticket.chat_log.get('messages') or []):
                text = m.get('text', '') or ''
                if not finance:
                    text = _redact_text(text)
                chat_messages.append({
                    'role': (m.get('role') or '').upper(),
                    'text': text,
                })

        # AI summary card (CHATBOT only).
        ai_summary = (ticket.chat_log or {}).get('ai_summary') or ''
        ai_summary_lang = (ticket.chat_log or {}).get('ai_summary_lang') or ''
        needs_review = bool((ticket.chat_log or {}).get('needs_review'))

        # Captured fields — key/value rows, IBAN keys redacted unless finance.
        captured = (ticket.chat_log or {}).get('captured_fields') or {}
        captured_rows: list[tuple[str, str]] = []
        for key, val in captured.items():
            if key.lower() in _REDACTED_KEYS and not finance:
                display = '[redacted]'
            else:
                display = str(val)
                if not finance:
                    display = _redact_text(display)
            captured_rows.append((key.replace('_', ' ').title(), display))

        # Refund base — what the percentage will multiply against.
        from decimal import Decimal
        booking = ticket.booking
        refund_base = (
            booking.cash_collected_amount if booking.cash_collected_amount is not None
            else (booking.final_cash_to_collect if booking.final_cash_to_collect is not None
                  else booking.price_amount)
        )
        if refund_base is None:
            refund_base = Decimal('0')

        return render(
            request,
            'admin/bookings/supportticket/resolve.html',
            {
                'ticket': ticket,
                'is_open': is_open,
                'booking': booking,
                'evidence_photos': evidence_photos,
                'chat_messages': chat_messages,
                'ai_summary': ai_summary,
                'ai_summary_lang': ai_summary_lang,
                'needs_review': needs_review,
                'captured_rows': captured_rows,
                'finance_admin': finance,
                'refund_base': refund_base,
                'outcomes': [
                    (SupportTicket.OUTCOME_ACCEPT_REFUND, 'Accept — refund customer'),
                    (SupportTicket.OUTCOME_REJECT, 'Reject — close, no refund'),
                ],
                'OUTCOME_ACCEPT': SupportTicket.OUTCOME_ACCEPT_REFUND,
                'OUTCOME_REJECT': SupportTicket.OUTCOME_REJECT,
            },
        )


# TechReliabilityIncident standalone admin unregistered: nothing
# currently reads this table (the planned reliability-score work has
# not landed). The model and the orchestrator's write site remain so
# the audit log keeps accumulating — when reliability scoring resumes,
# re-register the admin here.
class TechReliabilityIncidentAdmin(EngineerOnlyAdminMixin, admin.ModelAdmin):
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

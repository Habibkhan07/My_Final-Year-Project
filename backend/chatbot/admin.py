"""Django Admin for the chatbot framework.

Strictly forensic — admin reads conversations, transcripts, attachments,
and quota counters to debug user flows and confirm AI behaviour. Nothing
here mutates rows: the conversation lifecycle is owned by
``chatbot.services.conversation`` and the persona flow engines, both of
which guard invariants that admin writes would violate.

The Message inline below is the supervisor's primary read surface —
it renders the full transcript inline on the conversation page so an
entire user journey can be reviewed without page-hopping.
"""
from __future__ import annotations
# Thius is a comment 
#A lot of comment
#this comment
import json

from django.contrib import admin
from django.urls import reverse
from django.utils.html import format_html

from chatbot.models import Attachment, Conversation, DailyLlmCallQuota, Message
from core.common.admin_permissions import EngineerOnlyAdminMixin
from core.common.admin_ui import pill, thumb, truncate


# Phase tones — keyed to the dispute persona's UNDERSTAND → EVIDENCE →
# PAYOUT → CLOSED flow. Unknown phases fall back to neutral.
_PHASE_TONES: dict[str, str] = {
    'UNDERSTAND': 'info',
    'EVIDENCE': 'warning',
    'PAYOUT': 'positive',
    'CONFIRM': 'positive',
    'CLOSED': 'neutral',
}

_ROLE_TONES: dict[str, str] = {
    'USER': 'info',
    'BOT': 'positive',
    'SYSTEM': 'neutral',
}


class MessageInline(admin.TabularInline):
    """Full append-only transcript rendered inline on the conversation page."""

    model = Message
    extra = 0
    can_delete = False
    fields = ('created_at', 'role_pill', 'phase', 'text_preview', 'structured_preview')
    readonly_fields = fields
    ordering = ('created_at',)

    def has_add_permission(self, request, obj=None):
        return False

    @admin.display(description='Role')
    def role_pill(self, obj: Message):
        return pill(obj.role, _ROLE_TONES.get(obj.role, 'neutral'))

    @admin.display(description='Text')
    def text_preview(self, obj: Message):
        return format_html(
            '<div style="white-space:pre-wrap;max-width:520px">{}</div>',
            truncate(obj.text, 400),
        )

    @admin.display(description='Structured')
    def structured_preview(self, obj: Message):
        if not obj.structured:
            return '—'
        pretty = json.dumps(obj.structured, indent=2, ensure_ascii=False, default=str)
        return format_html(
            '<pre style="margin:0;font-size:11px;max-width:360px;white-space:pre-wrap">{}</pre>',
            pretty,
        )


class AttachmentInline(admin.TabularInline):
    model = Attachment
    extra = 0
    can_delete = False
    fields = ('thumbnail', 'mime_type', 'size_bytes', 'created_at')
    readonly_fields = fields

    def has_add_permission(self, request, obj=None):
        return False

    @admin.display(description='Preview')
    def thumbnail(self, obj: Attachment):
        return thumb(obj.file, size=80)


# Conversation admin remains registered — the SupportTicket "View
# transcript" deep-link points here. EngineerOnlyAdminMixin keeps it
# out of the supervisor sidebar.
@admin.register(Conversation)
class ConversationAdmin(EngineerOnlyAdminMixin, admin.ModelAdmin):
    list_display = (
        'id',
        'created_at',
        'user_link',
        'persona_pill',
        'phase_pill',
        'turn_count',
        'attachments_count',
        'closed_pill',
        'output_summary',
    )
    list_filter = ('persona_key', 'is_closed')
    search_fields = (
        'id',
        'user__username',
        'user__first_name',
        'user__last_name',
    )
    date_hierarchy = 'created_at'
    ordering = ('-created_at',)
    list_per_page = 30
    list_select_related = ('user',)
    inlines = [MessageInline, AttachmentInline]
    save_on_top = True

    readonly_fields = (
        'user', 'persona_key', 'context_pretty', 'state_pretty',
        'turn_count', 'is_closed', 'output_refs_pretty',
        'created_at', 'closed_at',
    )
    fields = (
        'user', 'persona_key',
        ('turn_count', 'is_closed'),
        ('created_at', 'closed_at'),
        'context_pretty', 'state_pretty', 'output_refs_pretty',
    )

    def get_queryset(self, request):
        # Annotate attachments_count to kill the per-row N+1.
        from django.db.models import Count
        return (
            super().get_queryset(request)
            .annotate(_attachments_count=Count('attachments'))
        )

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return True

    @admin.display(description='User', ordering='user__username')
    def user_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user_id])
        return format_html(
            '<a href="{}">{}</a>',
            url, obj.user.get_full_name() or obj.user.username,
        )

    @admin.display(description='Persona', ordering='persona_key')
    def persona_pill(self, obj):
        return pill(obj.persona_key, 'info')

    @admin.display(description='Phase')
    def phase_pill(self, obj):
        phase = (obj.state or {}).get('phase') or '—'
        return pill(phase, _PHASE_TONES.get(phase, 'neutral'))

    @admin.display(description='Files', ordering='_attachments_count')
    def attachments_count(self, obj):
        return getattr(obj, '_attachments_count', 0)

    @admin.display(description='Closed', ordering='is_closed')
    def closed_pill(self, obj):
        return pill('Closed', 'neutral') if obj.is_closed else pill('Open', 'positive')

    @admin.display(description='Output')
    def output_summary(self, obj):
        if not obj.output_refs:
            return '—'
        parts = [f'{k}=#{v}' for k, v in obj.output_refs.items()]
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-size:11px">{}</span>',
            ', '.join(parts),
        )

    @admin.display(description='Context (immutable input)')
    def context_pretty(self, obj):
        return _pretty_json(obj.context)

    @admin.display(description='State (flow runtime)')
    def state_pretty(self, obj):
        return _pretty_json(obj.state)

    @admin.display(description='Output refs')
    def output_refs_pretty(self, obj):
        return _pretty_json(obj.output_refs)


# Standalone MessageAdmin + AttachmentAdmin removed in the scope-reduction
# pass — both are already rendered inline on ConversationAdmin via
# MessageInline + AttachmentInline. A standalone browser duplicates the
# inlines without adding supervisor value; for forensic filtering by role
# or phase, the SQL shell is the right tool, not a 4th sidebar entry.


# DailyLlmCallQuota standalone admin intentionally not registered.
# Rate-limit forensics belong in metrics dashboards, not the admin
# sidebar.
class DailyLlmCallQuotaAdmin(EngineerOnlyAdminMixin, admin.ModelAdmin):
    """Per-user daily LLM budget — read-only forensic view.

    Useful when debugging "the chatbot stopped responding" complaints —
    if count == cap, the user hit the daily limit and the persona returns
    ``429 llm_quota_exceeded``.
    """

    list_display = ('id', 'date', 'user_link', 'count_label')
    list_filter = ('date',)
    search_fields = ('user__username', 'user__first_name', 'user__last_name')
    date_hierarchy = 'date'
    ordering = ('-date', '-count')
    list_per_page = 50
    list_select_related = ('user',)
    readonly_fields = ('user', 'date', 'count')

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    @admin.display(description='User', ordering='user__username')
    def user_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user_id])
        return format_html(
            '<a href="{}">{}</a>',
            url, obj.user.get_full_name() or obj.user.username,
        )

    @admin.display(description='LLM calls today', ordering='count')
    def count_label(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-weight:600">{}</span>',
            obj.count,
        )


def _pretty_json(value) -> str:
    """Render a JSON value as an indented preformatted block."""
    if not value:
        return format_html('<span style="color:#9ca3af">{}</span>', '—')
    pretty = json.dumps(value, indent=2, ensure_ascii=False, default=str)
    return format_html(
        '<pre style="margin:0;font-size:12px;background:#f9fafb;padding:8px;border-radius:4px;'
        'max-width:720px;white-space:pre-wrap">{}</pre>',
        pretty,
    )

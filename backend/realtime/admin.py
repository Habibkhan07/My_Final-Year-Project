"""Django Admin for the realtime hub.

The two tables here are the operational forensic surface of the entire
realtime pipeline:

* ``FCMDevice`` — every push-eligible device registration. Useful when
  debugging "the tech didn't get the notification" — filter by user,
  check ``is_active``, see when the token last refreshed.
* ``EventLog`` — every realtime fact the dispatcher persisted. The
  thesis claim *every realtime event is persisted for offline recovery*
  is provable directly from this view: open the table, see the rows.

Both admins are strictly read-only — the dispatch service is the only
sanctioned writer.
"""
from __future__ import annotations

import json

from django.contrib import admin
from django.urls import reverse
from django.utils.html import format_html

from core.common.admin_permissions import EngineerOnlyAdminMixin
from core.common.admin_ui import pill
from realtime.models import EventLog
from realtime.models.devices import FCMDevice


_TARGET_TONES = {
    EventLog.TARGET_CUSTOMER: 'info',
    EventLog.TARGET_TECHNICIAN: 'warning',
}


# FCMDevice standalone admin intentionally not registered. Push-token
# debugging is a shell-query task; an admin sidebar entry adds noise
# without enabling any workflow.
class FCMDeviceAdmin(EngineerOnlyAdminMixin, admin.ModelAdmin):
    list_display = (
        'id',
        'user_link',
        'device_type_pill',
        'token_preview',
        'active_pill',
        'updated_at',
        'created_at',
    )
    list_filter = ('device_type', 'is_active')
    search_fields = ('user__username', 'user__first_name', 'user__last_name', 'device_token')
    date_hierarchy = 'updated_at'
    ordering = ('-updated_at',)
    list_per_page = 50
    list_select_related = ('user',)
    readonly_fields = ('user', 'device_token', 'device_type', 'created_at', 'updated_at')

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

    @admin.display(description='Platform', ordering='device_type')
    def device_type_pill(self, obj):
        tone = 'info' if obj.device_type == FCMDevice.DEVICE_ANDROID else 'positive'
        return pill(obj.get_device_type_display(), tone)

    @admin.display(description='Token')
    def token_preview(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-size:11px;color:#6b7280">{}…</span>',
            obj.device_token[:20],
        )

    @admin.display(description='Active', ordering='is_active')
    def active_pill(self, obj):
        return pill('Active', 'positive') if obj.is_active else pill('Disabled', 'neutral')


# EventLog standalone admin intentionally not registered. The
# dashboard "Recent realtime events" feed surfaces the operational
# slice. Bulk forensic search belongs in the engineer's shell, not
# the admin sidebar.
class EventLogAdmin(EngineerOnlyAdminMixin, admin.ModelAdmin):
    """Every realtime event the dispatch hub persisted.

    The table is the operational proof of the "every event is
    persistent" guarantee — opening it for a recently-created booking
    surfaces the ``job_new_request``, ``quote_generated``,
    ``payment_received`` rows that the dispatcher wrote.
    """

    list_display = (
        'short_id',
        'created_at',
        'event_type_label',
        'target_pill',
        'user_link',
        'critical_pill',
        'ack_pill',
        'expires_at',
    )
    list_filter = ('event_type', 'is_critical')
    search_fields = (
        'event_type',
        'user__username',
        'user__first_name',
        'user__last_name',
    )
    date_hierarchy = 'created_at'
    ordering = ('-created_at',)
    list_per_page = 50
    list_select_related = ('user',)

    readonly_fields = (
        'id', 'user', 'event_type', 'target_role',
        'is_critical', 'acknowledged_at',
        'created_at', 'expires_at',
        'payload_pretty',
    )
    fields = (
        'id', 'created_at', 'expires_at',
        'event_type', 'target_role',
        'user',
        'is_critical', 'acknowledged_at',
        'payload_pretty',
    )

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return True

    def has_delete_permission(self, request, obj=None):
        return False

    @admin.display(description='ID', ordering='id')
    def short_id(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-size:11px;color:#6b7280">{}</span>',
            str(obj.id)[:8],
        )

    @admin.display(description='Event type', ordering='event_type')
    def event_type_label(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-weight:600">{}</span>',
            obj.event_type,
        )

    @admin.display(description='Audience', ordering='target_role')
    def target_pill(self, obj):
        return pill(
            obj.get_target_role_display(),
            _TARGET_TONES.get(obj.target_role, 'neutral'),
        )

    @admin.display(description='User', ordering='user__username')
    def user_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user_id])
        return format_html(
            '<a href="{}">{}</a>',
            url, obj.user.get_full_name() or obj.user.username,
        )

    @admin.display(description='Critical', ordering='is_critical')
    def critical_pill(self, obj):
        return pill('Critical', 'negative') if obj.is_critical else pill('Info', 'neutral')

    @admin.display(description='Ack', ordering='acknowledged_at')
    def ack_pill(self, obj):
        if not obj.is_critical:
            return '—'
        if obj.acknowledged_at:
            return pill('Acked', 'positive')
        return pill('Pending', 'warning')

    @admin.display(description='Payload')
    def payload_pretty(self, obj):
        if not obj.payload:
            return format_html('<em style="color:#9ca3af">{}</em>', 'empty')
        pretty = json.dumps(obj.payload, indent=2, ensure_ascii=False, default=str)
        return format_html(
            '<pre style="margin:0;font-size:12px;background:#f9fafb;padding:8px;'
            'border-radius:4px;max-width:720px;white-space:pre-wrap">{}</pre>',
            pretty,
        )

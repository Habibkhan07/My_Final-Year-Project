"""Django Admin for the marketing domain.

One model — ``Promotion`` — but it is the only thing standing between an
empty home screen and a discount-driven discovery surface. Every
promotion the supervisor demos was created here.

The admin is therefore live-edit friendly: tone-coded list cells, image
preview at both list and detail, and an inline preview of the
auto-generated ``ui_description`` so the admin sees the final string
the customer will see before saving.
"""
from __future__ import annotations

from django.contrib import admin
from django.utils import timezone
from django.utils.html import format_html

from core.common.admin_ui import money_rs, pill
from marketing.models import Promotion


_DISCOUNT_TONES = {
    Promotion.DiscountType.PERCENTAGE: 'info',
    Promotion.DiscountType.FIXED: 'positive',
}

_FUNDING_TONES = {
    Promotion.FundingSource.PLATFORM: 'info',
    Promotion.FundingSource.TECHNICIAN: 'warning',
}


@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'banner_thumb',
        'name',
        'discount_pill',
        'funded_pill',
        'target_service',
        'window_label',
        'live_pill',
        'featured_pill',
    )
    list_filter = ('is_active', 'discount_type')
    search_fields = ('name', 'description')
    list_editable = ()
    list_select_related = ('target_service',)
    list_per_page = 30
    date_hierarchy = 'valid_from'
    ordering = ('-valid_from',)
    save_on_top = True
    autocomplete_fields = ('target_service',)
    readonly_fields = ('banner_render', 'ui_description_preview', 'window_render')

    fieldsets = (
        ('Identity', {
            'fields': ('name', 'description'),
        }),
        ('Offer', {
            'fields': ('discount_type', 'discount_value', 'target_service', 'funded_by'),
        }),
        ('Banner image', {
            'fields': ('image', 'banner_render'),
        }),
        ('Customer-facing copy', {
            'description': 'The auto-generated text shown on the home '
                           'banner. Override by filling the description '
                           'field above; otherwise composed from discount + '
                           'target service.',
            'fields': ('ui_description_preview',),
        }),
        ('Schedule', {
            'fields': ('valid_from', 'valid_until', 'window_render'),
        }),
        ('Visibility', {
            'fields': ('is_active', 'is_featured_on_home'),
        }),
    )

    @admin.display(description='')
    def banner_thumb(self, obj):
        if not obj.image:
            return '—'
        return format_html(
            '<img src="{}" style="width:80px;height:48px;object-fit:cover;'
            'border-radius:6px;box-shadow:0 1px 2px rgba(0,0,0,0.1)"/>',
            obj.image.url,
        )

    @admin.display(description='Banner preview')
    def banner_render(self, obj):
        if not obj.image:
            return format_html('<em style="color:#9ca3af">{}</em>', 'No image uploaded')
        return format_html(
            '<img src="{}" style="width:320px;height:180px;object-fit:cover;'
            'border-radius:10px;box-shadow:0 2px 8px rgba(0,0,0,0.15)"/>',
            obj.image.url,
        )

    @admin.display(description='Discount', ordering='discount_value')
    def discount_pill(self, obj):
        if obj.discount_type == Promotion.DiscountType.PERCENTAGE:
            label = f'{int(obj.discount_value)}% off'
        else:
            label = f'{money_rs(obj.discount_value)} off'
        return pill(label, _DISCOUNT_TONES.get(obj.discount_type, 'neutral'))

    @admin.display(description='Funded by', ordering='funded_by')
    def funded_pill(self, obj):
        return pill(
            obj.get_funded_by_display(),
            _FUNDING_TONES.get(obj.funded_by, 'neutral'),
        )

    @admin.display(description='Window', ordering='valid_from')
    def window_label(self, obj):
        now = timezone.now()
        if obj.valid_until < now:
            tone, label = 'neutral', 'Expired'
        elif obj.valid_from > now:
            tone, label = 'warning', 'Scheduled'
        else:
            tone, label = 'positive', 'Active now'
        return format_html(
            '<div style="line-height:1.3"><div>{}</div>'
            '<div style="color:#6b7280;font-size:11px">{} → {}</div></div>',
            pill(label, tone),
            obj.valid_from.strftime('%b %d'),
            obj.valid_until.strftime('%b %d'),
        )

    @admin.display(description='Window detail')
    def window_render(self, obj):
        if not obj.valid_from or not obj.valid_until:
            return '—'
        return format_html(
            '<div style="line-height:1.5"><div><strong>From:</strong> {}</div>'
            '<div><strong>Until:</strong> {}</div></div>',
            obj.valid_from.strftime('%Y-%m-%d %H:%M %Z'),
            obj.valid_until.strftime('%Y-%m-%d %H:%M %Z'),
        )

    @admin.display(description='Live', ordering='is_active')
    def live_pill(self, obj):
        return pill('Live', 'positive') if obj.is_active else pill('Paused', 'neutral')

    @admin.display(description='On home', ordering='is_featured_on_home')
    def featured_pill(self, obj):
        return pill('Home', 'warning') if obj.is_featured_on_home else '—'

    @admin.display(description='Auto-generated banner text')
    def ui_description_preview(self, obj):
        if not obj.pk:
            return format_html('<em style="color:#9ca3af">{}</em>', 'Save first to see preview')
        return format_html(
            '<div style="padding:10px 14px;background:#fef3c7;border-left:4px solid #f59e0b;'
            'border-radius:4px;max-width:520px;font-size:13px">{}</div>',
            obj.ui_description,
        )

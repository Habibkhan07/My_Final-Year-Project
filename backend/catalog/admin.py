"""Django Admin for the catalog domain.

The catalog drives every customer's discovery flow, every booking's
pricing resolution, and the home-screen lifestyle imagery. These two
tables are therefore the single most-edited surface in the app — the
admin UX here gets the same care as a CMS.

Service → SubService is the natural inline relationship: opening AC
Service shows every gig (General Wash, Gas Refill, etc.) right there.
The SubService list also stands on its own for the supervisor who wants
to sort all fixed-price gigs by price, filter by featured-on-home, etc.
"""
from __future__ import annotations

import json

from django.contrib import admin, messages
from django.urls import reverse
from django.utils.html import format_html

from catalog.forms import ServiceAdminForm, SubServiceAdminForm
from catalog.models import Service, SubService
from core.common.admin_ui import money_rs, pill, truncate


class SubServiceInline(admin.TabularInline):
    """All gigs under a service category — inline edit."""

    model = SubService
    extra = 0
    fields = (
        'name',
        'base_price',
        'max_price',
        'is_fixed_price',
        'is_featured',
        'icon_name',
        'estimated_duration_minutes',
    )
    show_change_link = True


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    """Top-level category — e.g. AC Service, Plumbing, Electrician."""

    form = ServiceAdminForm

    list_display = (
        'id',
        'name',
        'icon_name',
        'inspection_fee_label',
        'duration_label',
        'sub_service_count',
        'active_pill',
        'display_order',
        'is_active',
    )
    list_filter = ('is_active',)
    search_fields = ('name', 'icon_name')
    list_editable = ('display_order', 'is_active')
    ordering = ('display_order', 'name')
    list_per_page = 50
    inlines = [SubServiceInline]
    actions = ('bulk_activate', 'bulk_deactivate', 'deactivate_with_cascade')
    save_on_top = True

    def save_model(self, request, obj, form, change):
        """Run model-level ``clean()`` so the whole-rupee validator fires.

        Without this, ``Model.save()`` is called directly by the standard
        admin form and ``_validate_whole_rupee`` is silently bypassed —
        paisa values persist despite the catalog policy. ``full_clean()``
        on a Service is cheap (no image fields to re-validate).
        """
        obj.full_clean()
        super().save_model(request, obj, form, change)

    @admin.action(description='Activate selected categories')
    def bulk_activate(self, request, queryset):
        n = queryset.update(is_active=True)
        self.message_user(request, f'Activated {n} categor{"ies" if n != 1 else "y"}.')

    @admin.action(description='Deactivate selected categories')
    def bulk_deactivate(self, request, queryset):
        n = queryset.update(is_active=False)
        self.message_user(request, f'Deactivated {n} categor{"ies" if n != 1 else "y"}.')

    @admin.action(description='Deactivate selected + un-feature their sub-services')
    def deactivate_with_cascade(self, request, queryset):
        """Cascade-aware: deactivating a category also un-features every
        sub-service under it. Prevents the silent-failure mode where the
        home-screen "Featured" carousel keeps showing gigs whose parent
        category is hidden.
        """
        cats = queryset.update(is_active=False)
        subs = SubService.objects.filter(service__in=queryset).update(is_featured=False)
        self.message_user(
            request,
            f'Deactivated {cats} categor{"ies" if cats != 1 else "y"} '
            f'and unfeatured {subs} sub-service(s).',
            level=messages.SUCCESS,
        )

    fieldsets = (
        ('Identity', {
            'fields': ('name', 'icon_name', 'is_active', 'display_order'),
        }),
        ('Defaults', {
            'description': 'Inspection fee falls back to per-service value; '
                           'duration drives availability slot length when no '
                           'specific sub-service is chosen.',
            'fields': ('base_inspection_fee', 'default_duration_minutes'),
        }),
    )

    def get_queryset(self, request):
        from django.db.models import Count
        return (
            super().get_queryset(request)
            .annotate(_sub_count=Count('sub_services'))
        )

    @admin.display(description='Inspection fee', ordering='base_inspection_fee')
    def inspection_fee_label(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace">{}</span>',
            money_rs(obj.base_inspection_fee),
        )

    @admin.display(description='Duration', ordering='default_duration_minutes')
    def duration_label(self, obj):
        return f'{obj.default_duration_minutes} min'

    @admin.display(description='Sub-services')
    def sub_service_count(self, obj):
        n = getattr(obj, '_sub_count', 0)
        return pill(f'{n} gigs', 'info') if n else pill('0', 'neutral')

    @admin.display(description='Active', ordering='is_active')
    def active_pill(self, obj):
        return pill('Active', 'positive') if obj.is_active else pill('Hidden', 'negative')


@admin.register(SubService)
class SubServiceAdmin(admin.ModelAdmin):
    """Individual gig — the unit that ships on home screen + search results."""

    form = SubServiceAdminForm

    list_display = (
        'id',
        'name',
        'service_link',
        'price_label',
        'flavour_pill',
        'featured_pill',
        'is_featured',
        'icon_name',
        'card_image_preview',
        'tags_short',
    )
    list_editable = ('is_featured',)
    list_filter = ('service', 'is_featured')
    search_fields = ('name', 'icon_name', 'service__name', 'search_tags')
    list_select_related = ('service',)
    list_per_page = 50
    ordering = ('service__display_order', 'service__name', 'name')
    autocomplete_fields = ('service',)
    actions = ('bulk_feature', 'bulk_unfeature', 'duplicate_selected')
    save_on_top = True

    def save_model(self, request, obj, form, change):
        """Fire model-level ``clean()`` to enforce the whole-rupee validator.

        Without this, paisa prices entered through the admin form
        persist silently (Model.save bypasses full_clean).

        Also normalises the price band for fixed-price gigs: the wire
        contract is ``base_price`` alone with ``max_price = NULL`` (see
        ``catalog.api.search.serializers``), so a stale ``max_price``
        left over after an admin re-checks ``is_fixed_price`` would
        confuse downstream code. Forced to NULL here.
        """
        if obj.is_fixed_price:
            obj.max_price = None
        obj.full_clean()
        super().save_model(request, obj, form, change)

    class Media:
        js = ('catalog/admin/subservice_pricing.js',)

    @admin.action(description='Promote selected to home screen')
    def bulk_feature(self, request, queryset):
        n = queryset.update(is_featured=True)
        self.message_user(request, f'Featured {n} gig(s) on the home screen.')

    @admin.action(description='Remove selected from home screen')
    def bulk_unfeature(self, request, queryset):
        n = queryset.update(is_featured=False)
        self.message_user(request, f'Unfeatured {n} gig(s).')

    @admin.action(description='Duplicate selected (copies — name suffixed)')
    def duplicate_selected(self, request, queryset):
        """Clone gigs for seasonal re-runs (e.g. Eid → Black Friday)."""
        cloned = 0
        for orig in queryset:
            orig.pk = None
            orig.name = f'{orig.name} (copy)'
            orig.is_featured = False
            orig.save()
            cloned += 1
        self.message_user(request, f'Cloned {cloned} gig(s).')

    fieldsets = (
        ('Identity', {
            'fields': ('service', 'name', 'icon_name'),
        }),
        ('Pricing', {
            'description': 'Fixed-price gigs use base_price only; labor gigs '
                           'use [base_price, max_price] as the technician\'s '
                           'rate band.',
            'fields': ('base_price', 'max_price', 'is_fixed_price'),
        }),
        ('Home screen', {
            'fields': ('is_featured', 'card_image_url', 'card_image_render'),
        }),
        ('Discovery & scheduling', {
            'fields': ('search_tags', 'estimated_duration_minutes'),
        }),
    )
    readonly_fields = ('card_image_render',)

    @admin.display(description='Service', ordering='service__name')
    def service_link(self, obj):
        url = reverse('admin:catalog_service_change', args=[obj.service_id])
        return format_html('<a href="{}">{}</a>', url, obj.service.name)

    @admin.display(description='Price', ordering='base_price')
    def price_label(self, obj):
        if obj.is_fixed_price:
            return format_html(
                '<span style="font-family:ui-monospace,monospace;font-weight:600">{}</span>',
                money_rs(obj.base_price),
            )
        # Labor band
        if obj.max_price is not None and obj.max_price != obj.base_price:
            return format_html(
                '<span style="font-family:ui-monospace,monospace">{} – {}</span>',
                money_rs(obj.base_price), money_rs(obj.max_price),
            )
        return format_html(
            '<span style="font-family:ui-monospace,monospace">{}</span>',
            money_rs(obj.base_price),
        )

    @admin.display(description='Type')
    def flavour_pill(self, obj):
        return pill('Fixed', 'positive') if obj.is_fixed_price else pill('Labor', 'info')

    @admin.display(description='Featured', ordering='is_featured')
    def featured_pill(self, obj):
        return pill('Home', 'warning') if obj.is_featured else '—'

    @admin.display(description='Card image')
    def card_image_preview(self, obj):
        if not obj.card_image_url:
            return '—'
        return format_html(
            '<img src="{}" style="width:64px;height:44px;object-fit:cover;'
            'border-radius:6px;box-shadow:0 1px 2px rgba(0,0,0,0.1)"/>',
            obj.card_image_url,
        )

    @admin.display(description='Card image preview')
    def card_image_render(self, obj):
        if not obj.card_image_url:
            return format_html('<em style="color:#9ca3af">{}</em>', 'No image set')
        return format_html(
            '<img src="{}" style="width:220px;height:140px;object-fit:cover;'
            'border-radius:10px;box-shadow:0 2px 6px rgba(0,0,0,0.12)"/>',
            obj.card_image_url,
        )

    @admin.display(description='Search tags')
    def tags_short(self, obj):
        if not obj.search_tags:
            return '—'
        return truncate(', '.join(obj.search_tags), 50)

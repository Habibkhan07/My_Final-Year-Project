"""Django Admin for the customer domain.

CustomerProfile is currently identity-only (OneToOne with the auth User);
the addresses are where the operationally interesting data lives — the
matchmaker pulls lat/lng from CustomerAddress for every nearby-search.
The admin therefore privileges the address view with map links, locality
context, and a default-address pill.
"""
from __future__ import annotations

from django.contrib import admin, messages
from django.db import transaction
from django.db.models import Count
from django.urls import reverse
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _

from core.common.admin_ui import pill, truncate
from customers.models import CustomerAddress, CustomerProfile


class CustomerAddressInline(admin.TabularInline):
    """Every saved address inline on the profile page."""

    model = CustomerAddress
    extra = 0
    fields = (
        'label', 'locality_label', 'city',
        'latitude', 'longitude', 'is_default', 'created_at',
    )
    readonly_fields = ('latitude', 'longitude', 'is_default', 'created_at')
    can_delete = False
    # show_change_link removed: CustomerAddress has no standalone admin
    # page. The inline IS the only view; address editing happens via
    # the Flutter picker or the Make-Default service, not from the admin.
    show_change_link = False

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'user_link',
        'phone',
        'address_count',
        'booking_count',
    )
    search_fields = (
        'user__username',
        'user__first_name',
        'user__last_name',
        'user__email',
        'user__userprofile__phone',
    )
    list_select_related = ('user', 'user__userprofile')
    list_per_page = 40
    inlines = [CustomerAddressInline]
    readonly_fields = ('user',)

    def get_queryset(self, request):
        return (
            super().get_queryset(request)
            .annotate(
                _addr_count=Count('addresses', distinct=True),
                _booking_count=Count('user__bookings', distinct=True),
            )
        )

    @admin.display(description='User', ordering='user__username')
    def user_link(self, obj):
        url = reverse('admin:auth_user_change', args=[obj.user_id])
        return format_html(
            '<a href="{}">{}</a>',
            url, obj.user.get_full_name() or obj.user.username,
        )

    @admin.display(description='Phone', ordering='user__userprofile__phone')
    def phone(self, obj):
        # UserProfile.user is OneToOneField with no related_name, so the
        # reverse accessor is the singular ``user.userprofile``. Any
        # plural ``_set`` access here would be dead code.
        from accounts.models import UserProfile
        try:
            return obj.user.userprofile.phone
        except UserProfile.DoesNotExist:
            return '—'

    @admin.display(description='Addresses', ordering='_addr_count')
    def address_count(self, obj):
        n = getattr(obj, '_addr_count', 0)
        return pill(f'{n}', 'info' if n else 'neutral')

    @admin.display(description='Bookings', ordering='_booking_count')
    def booking_count(self, obj):
        n = getattr(obj, '_booking_count', 0)
        return pill(f'{n}', 'positive' if n else 'neutral')


# CustomerAddress standalone admin intentionally not registered.
# Addresses are inline-visible on the CustomerProfile detail page;
# a global queue surface would expose PII without serving a real
# operational need.
class CustomerAddressAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'customer_link',
        'label',
        'locality_short',
        'city',
        'coords_link',
        'default_pill',
        'created_at',
    )
    list_filter = ('city', 'is_default')
    search_fields = (
        'customer__user__username',
        'customer__user__first_name',
        'customer__user__last_name',
        'label',
        'street_address',
        'city',
        'locality_label',
    )
    list_select_related = ('customer', 'customer__user')
    date_hierarchy = 'created_at'
    ordering = ('-id',)
    list_per_page = 40
    autocomplete_fields = ('customer',)

    fieldsets = (
        ('Owner', {
            'fields': ('customer', 'label'),
        }),
        ('Default flag (locked — use "Make default" action)', {
            'description': '"Exactly one default per customer" is enforced '
                           'atomically by the Make Default action — raw '
                           'checkbox edits would leave 0 or 2+ defaults.',
            'fields': ('is_default',),
        }),
        ('Coordinates (locked — set via the map picker)', {
            'description': 'Trusted source for matchmaking distance. Edit '
                           'via the Re-geocode action (uses the same '
                           'reverse-geocoder the Flutter picker uses).',
            'fields': ('latitude', 'longitude'),
        }),
        ('Geocoded locality (display only)', {
            'fields': (
                'street_address', 'locality_label',
                'neighborhood', 'suburb', 'city', 'state',
                'country', 'postal_code',
            ),
        }),
        ('Audit', {
            'classes': ('collapse',),
            'fields': ('created_at',),
        }),
    )
    # is_default, latitude, longitude locked from free edit — see Make Default
    # action below. Bare checkbox / decimal edits silently break invariants
    # (multiple defaults; lat/lng desynced from locality_label).
    readonly_fields = ('is_default', 'latitude', 'longitude', 'created_at')
    actions = ('make_default',)

    @admin.action(description=_('Make selected the default address (atomic, one per customer)'))
    def make_default(self, request, queryset):
        """Enforce "exactly one default per user" — clear siblings first.

        ``ADDRESSES_API.md`` documents the invariant. The Flutter app /
        API path serializes the clear-and-set transaction; the admin
        save flow doesn't. This action restores that contract.
        """
        flipped = 0
        with transaction.atomic():
            for addr in queryset.select_for_update():
                # Clear other defaults belonging to the same customer.
                CustomerAddress.objects.filter(
                    customer_id=addr.customer_id,
                ).exclude(pk=addr.pk).update(is_default=False)
                if not addr.is_default:
                    addr.is_default = True
                    addr.save(update_fields=['is_default'])
                flipped += 1
        self.message_user(
            request,
            _('Marked %(n)d address(es) as their customer\'s default.') % {'n': flipped},
            level=messages.SUCCESS,
        )

    @admin.display(description='Customer', ordering='customer__user__username')
    def customer_link(self, obj):
        url = reverse('admin:customers_customerprofile_change', args=[obj.customer_id])
        full = obj.customer.user.get_full_name() or obj.customer.user.username
        return format_html('<a href="{}">{}</a>', url, full)

    @admin.display(description='Locality')
    def locality_short(self, obj):
        return obj.locality_label or truncate(obj.street_address, 40)

    @admin.display(description='Coords')
    def coords_link(self, obj):
        if obj.latitude is None or obj.longitude is None:
            return '—'
        return format_html(
            '<a href="https://maps.google.com/?q={},{}" target="_blank" '
            'rel="noopener" style="font-family:ui-monospace,monospace;font-size:11px">{}, {}</a>',
            obj.latitude, obj.longitude,
            f'{obj.latitude:.4f}', f'{obj.longitude:.4f}',
        )

    @admin.display(description='Default', ordering='is_default')
    def default_pill(self, obj):
        return pill('Default', 'positive') if obj.is_default else '—'

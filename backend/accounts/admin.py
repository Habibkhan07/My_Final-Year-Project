"""Django Admin for the accounts domain.

UserProfile is the per-user identity record (phone, technician flag).
OTPRecord is exposed read-only because in DEBUG the OTP is the literal
``123456`` and the table has no PII beyond the phone — making it
viewable is the simplest way to debug "the OTP isn't arriving" without
logging into the Django shell.
"""
from __future__ import annotations

from django.contrib import admin
from django.urls import reverse
from django.utils.html import format_html

from accounts.models import OTPRecord, UserProfile
from core.common.admin_permissions import EngineerOnlyAdminMixin
from core.common.admin_ui import pill


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """Unified-user identity record.

    Per CLAUDE.md "Unified User Model": every user — customer or
    technician — lives here. The admin surface privileges identity
    discovery (find by phone / name / email) and cross-navigation to
    the role-specific profiles (CustomerProfile / TechnicianProfile).
    """

    list_display = (
        'id',
        'user_link',
        'phone',
        'role_pill',
        'has_customer_profile',
        'has_tech_profile',
        'joined',
        'last_seen',
    )
    list_filter = ('is_technician', 'user__is_active')
    search_fields = (
        'user__username',
        'user__first_name',
        'user__last_name',
        'user__email',
        'phone',
    )
    date_hierarchy = 'user__date_joined'
    ordering = ('-user__date_joined',)
    list_select_related = ('user',)
    list_per_page = 50
    autocomplete_fields = ('user',)
    # SECURITY: phone + is_technician are read-only via the standard
    # admin form. ``phone`` is the OTP / login key — bare edits skip
    # OTP re-verification and can collide with another account's
    # uniqueness. ``is_technician`` should never be flipped without
    # creating/deleting the matching TechnicianProfile (raw flip
    # leaves the unified-user invariant broken). Both are mutable
    # only via named actions on the change page.
    readonly_fields = (
        'user',
        'phone',
        'is_technician',
        'linked_profiles',
        'joined',
        'last_seen',
    )

    fieldsets = (
        ('Identity (locked — use admin actions to change phone or role)', {
            'fields': ('user', 'phone', 'is_technician'),
        }),
        ('Linked records', {
            'description': 'Cross-links to the role-specific profile rows '
                           'for this user. Both can exist simultaneously.',
            'fields': ('linked_profiles', 'joined', 'last_seen'),
        }),
    )

    @admin.display(description='User', ordering='user__username')
    def user_link(self, obj):
        try:
            url = reverse('admin:auth_user_change', args=[obj.user_id])
        except Exception:
            return obj.user.get_full_name() or obj.user.username
        return format_html(
            '<a href="{}">{}</a>',
            url, obj.user.get_full_name() or obj.user.username,
        )

    @admin.display(description='Role', ordering='is_technician')
    def role_pill(self, obj):
        return pill('Technician', 'warning') if obj.is_technician else pill('Customer', 'info')

    @admin.display(description='Customer?', boolean=True)
    def has_customer_profile(self, obj):
        return hasattr(obj.user, 'customer_profile')

    @admin.display(description='Tech?', boolean=True)
    def has_tech_profile(self, obj):
        return hasattr(obj.user, 'tech_profile')

    @admin.display(description='Joined', ordering='user__date_joined')
    def joined(self, obj):
        return obj.user.date_joined

    @admin.display(description='Last login', ordering='user__last_login')
    def last_seen(self, obj):
        return obj.user.last_login or '—'

    @admin.display(description='Linked profiles')
    def linked_profiles(self, obj):
        """Two-link block on the change page so admin can jump to the
        role-specific profile in one click."""
        parts: list[str] = []
        customer_profile = getattr(obj.user, 'customer_profile', None)
        if customer_profile is not None:
            try:
                url = reverse(
                    'admin:customers_customerprofile_change',
                    args=[customer_profile.pk],
                )
                parts.append(
                    f'<a class="fx-qbtn fx-qbtn-ghost" href="{url}" '
                    f'style="margin-right:6px">View customer profile</a>'
                )
            except Exception:
                parts.append(f'CustomerProfile #{customer_profile.pk}')
        tech_profile = getattr(obj.user, 'tech_profile', None)
        if tech_profile is not None:
            try:
                url = reverse(
                    'admin:technicians_technicianprofile_change',
                    args=[tech_profile.pk],
                )
                parts.append(
                    f'<a class="fx-qbtn fx-qbtn-ghost" href="{url}">View technician profile</a>'
                )
            except Exception:
                parts.append(f'TechnicianProfile #{tech_profile.pk}')
        if not parts:
            return format_html('<em style="color:#9ca3af">{}</em>', 'No role profiles yet')
        from django.utils.safestring import mark_safe
        return mark_safe(''.join(parts))


# OTPRecord standalone admin intentionally not registered. In
# DEBUG=True the OTP is hardcoded to 123456 so the table holds no
# operational signal; in prod, engineer-side shell queries are the
# right path for OTP forensics.
class OTPRecordAdmin(EngineerOnlyAdminMixin, admin.ModelAdmin):
    """Forensic view of OTP issuance.

    Read-only — the OTP lifecycle is owned by
    ``accounts.services.process_otp_verification``. Visible primarily as
    a dev convenience: in ``DEBUG=True`` the code is fixed to ``123456``
    and the table just confirms the row exists for the phone we tried.
    """

    list_display = (
        'id',
        'created_at',
        'phone',
        'code_masked',
        'state_pill',
        'expires_at',
    )
    list_filter = ('is_used',)
    search_fields = ('phone',)
    date_hierarchy = 'created_at'
    ordering = ('-created_at',)
    list_per_page = 50
    readonly_fields = ('phone', 'code', 'created_at', 'expires_at', 'is_used')

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return True

    def has_delete_permission(self, request, obj=None):
        return False

    @admin.display(description='Code')
    def code_masked(self, obj):
        # Reveal in DEBUG only is overkill — even in prod, an OTP that is
        # already 30s past expiry has zero value. Show the last 3 digits.
        c = obj.code or ''
        return format_html(
            '<span style="font-family:ui-monospace,monospace">•••{}</span>',
            c[-3:] if len(c) >= 3 else c,
        )

    @admin.display(description='State')
    def state_pill(self, obj):
        if obj.is_used:
            return pill('Used', 'neutral')
        if obj.is_expired:
            return pill('Expired', 'negative')
        return pill('Active', 'positive')

"""Django Admin for the technicians domain.

The supervisor approves / rejects technician applications from here. Two
custom admin actions own the lifecycle transitions:

* **Approve selected technicians** — flips ``status`` to ``APPROVED`` and
  clears any leftover ``rejection_reason`` (a previous REJECT could have
  left a reason in place if admin later changes their mind via the change
  form). Bulk-safe.
* **Reject selected technicians** — opens an intermediate page asking for a
  rejection reason, then applies it atomically across the selected rows.
  A blank reason is refused at the form layer.

Both actions run inside ``transaction.atomic()`` with ``select_for_update``
so a concurrent finalize-registration call cannot race the status flip and
land the row in an inconsistent state.
"""
from __future__ import annotations

from django import forms
from django.contrib import admin, messages
from django.db import transaction
from django.db.models import Count
from django.http import HttpResponseRedirect
from django.shortcuts import redirect, render
from django.urls import path, reverse
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _

from core.common.admin_ui import ImageGridItem, image_grid, money_rs, pill, thumb, truncate

from .models import (
    Review,
    TechnicianProfile,
    TechnicianSchedule,
    TechnicianServiceLicense,
    TechnicianServicePerformance,
    TechnicianSkill,
    TemporaryMedia,
)


_STATUS_TONES = {
    'PENDING': 'warning',
    'APPROVED': 'positive',
    'REJECTED': 'negative',
}


_DAY_LABELS = dict(TechnicianSchedule.DAY_CHOICES)


class _RejectionReasonForm(forms.Form):
    """Intermediate-page form for the bulk reject action.

    A blank ``rejection_reason`` is invalid — surfacing this at the form
    layer matches the model-level ``clean()`` check, so an admin who tries
    to reject without a reason gets a UI error instead of an opaque 500.
    """

    rejection_reason = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 4, 'cols': 60}),
        label=_('Rejection reason (visible to the technician)'),
        required=True,
        min_length=1,
        max_length=2000,
    )


class TechnicianSkillInline(admin.TabularInline):
    """Tech-owned data — admin views, never edits.

    Skills are captured during the technician onboarding flow (Flutter
    app) plus the in-app Skills CRUD endpoint. Admin-side mutation
    would corrupt the matchmaking pipeline (sub_service FK feeds the
    discovery selector). Locked fully readonly.
    """
    model = TechnicianSkill
    extra = 0
    fields = ('sub_service',)
    readonly_fields = fields
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False


class TechnicianServiceLicenseInline(admin.TabularInline):
    """License inline with a thumbnail of the uploaded photo.

    Tech-owned data — uploaded during onboarding. Admin only needs to
    *view* the license image to verify identity before approval. Locked
    fully readonly; the upload field is replaced by the lightbox
    thumbnail so admin sees the document, not an empty file input.
    """
    model = TechnicianServiceLicense
    extra = 0
    fields = ('service', 'license_thumb')
    readonly_fields = ('service', 'license_thumb')
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    @admin.display(description='License document')
    def license_thumb(self, obj):
        from core.common.admin_ui import lightbox_thumb
        return lightbox_thumb(obj.license_picture, size=80, alt='License document')


class TechnicianScheduleInline(admin.TabularInline):
    """Weekly working hours grid — Mon→Sun rows.

    Tech-owned data — the tech edits their schedule via the Flutter
    app. Admin viewing the schedule is fine (sanity-check before
    approval); admin *editing* it would silently break the matchmaker's
    availability filter. Locked fully readonly.
    """

    model = TechnicianSchedule
    extra = 0
    fields = ('day_of_week', 'start_time', 'end_time', 'is_working')
    readonly_fields = fields
    can_delete = False
    ordering = ('day_of_week',)

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False


class TechnicianServicePerformanceInline(admin.TabularInline):
    """Per-service Bayesian inputs — read-only audit view."""

    model = TechnicianServicePerformance
    extra = 0
    fields = ('service', 'rating_average', 'review_count')
    readonly_fields = fields
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False


class WalletLedgerInline(admin.TabularInline):
    """Wallet ledger rows for this technician — read-only.

    Replaces the standalone ``WalletTransactionAdmin`` (unregistered
    2026-05-16). Finance opens the technician's page and sees the
    ledger immediately; engineer can shell-query for older rows.

    Slicing the queryset breaks Django's ``filter(**{fk: instance})``
    call (TypeError on already-sliced QS) — keep ordering, let Django
    show every row. Per-tech volume is low (under 100 in practice).

    ``has_add_permission`` is force-False so the inline never offers an
    add row — every ledger write goes through ``record_transaction``.
    """

    from wallet.models import WalletTransaction as _WT
    model = _WT
    fk_name = 'technician'
    extra = 0
    can_delete = False
    fields = (
        'timestamp', 'transaction_type', 'amount',
        'balance_after', 'memo', 'gateway_reference',
    )
    readonly_fields = fields
    ordering = ('-timestamp',)
    verbose_name_plural = 'Wallet ledger'

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(TechnicianProfile)
class TechnicianProfileAdmin(admin.ModelAdmin):
    list_display = (
        'avatar',
        'user_label',
        'status_pill',
        'city',
        'rating_label',
        'wallet_label',
        'online_pill',
        'quick_actions',
    )
    list_filter = ('status', 'is_online')
    search_fields = (
        'user__username',
        'user__first_name',
        'user__last_name',
        'cnic_number',
        'work_address_label',
    )
    # SECURITY: most fields here are user/service-owned (set during
    # onboarding or via the work-location endpoint). Admin must NOT
    # overwrite them via the change form — only via named actions
    # (Approve/Reject/Suspend/Reinstate). Editing CNIC, lat/lng, or
    # is_online directly breaks onboarding/matchmaker/wallet invariants.
    readonly_fields = (
        # Identity (set at signup / onboarding)
        'user', 'cnic_number', 'cnic_front_image', 'profile_picture',
        # Approval state (controlled by Approve/Reject actions)
        'status', 'rejection_reason', 'is_onboarding_complete',
        # Live state (driven by ledger + WS lifecycle)
        'is_online', 'current_wallet_balance',
        # Work location (set via the dedicated map-picker endpoint)
        'base_latitude', 'base_longitude', 'work_address_label',
        # Aggregates (stamped by the review pipeline)
        'rating_average', 'review_count',
        # Computed previews
        'documents_strip', 'profile_picture_preview', 'cnic_preview',
    )
    inlines = [
        TechnicianSkillInline,
        TechnicianServiceLicenseInline,
        TechnicianScheduleInline,
        TechnicianServicePerformanceInline,
        WalletLedgerInline,
    ]
    actions = ['approve_selected', 'reject_selected', 'suspend_selected', 'reinstate_selected']
    ordering = ('-id',)
    list_per_page = 30
    list_select_related = ('user',)
    save_on_top = True

    fieldsets = (
        ('Documents (verify identity before approving)', {
            'fields': ('documents_strip',),
        }),
        ('Approval', {
            'fields': ('status', 'rejection_reason', 'is_onboarding_complete'),
            'description': 'Use the Approve / Reject actions to change status — '
                           'the field is read-only here so admins don\'t bypass the audit trail.',
        }),
        ('Identity (editable)', {
            'fields': ('city',),
        }),
        ('Identity (locked — set at onboarding)', {
            'classes': ('collapse',),
            'fields': ('user', 'cnic_number'),
        }),
        ('Operational tuning', {
            'fields': ('is_active', 'max_travel_radius_km'),
            'description': 'is_active toggles via Suspend / Reinstate action so '
                           'a forced-offline broadcast also fires.',
        }),
        ('Live state (locked — driven by ledger & WS)', {
            'classes': ('collapse',),
            'fields': ('is_online', 'current_wallet_balance',
                       'rating_average', 'review_count'),
        }),
        ('Work location (locked — set via map picker)', {
            'classes': ('collapse',),
            'fields': ('base_latitude', 'base_longitude', 'work_address_label'),
        }),
    )

    # --- save hook: enforce model-level invariants -------------------------

    def save_model(self, request, obj, form, change):
        """Run the model's ``clean()`` so the REJECTED-needs-reason rule
        fires on manual saves through the change form, not only on the
        bulk actions.

        Note: we deliberately invoke ``clean()`` only — not ``full_clean()``
        — to avoid re-validating image fields against ``blank=False`` on
        legitimate edits where the admin is not re-uploading the images.
        The DB CheckConstraint backs us up for any code path that bypasses
        this hook entirely.
        """
        obj.clean()
        super().save_model(request, obj, form, change)

    # --- bulk actions ------------------------------------------------------

    @admin.action(description=_('Approve selected technicians'))
    def approve_selected(self, request, queryset):
        """Flip selected rows to APPROVED, clearing any leftover reason.

        Atomic + row-locked so a concurrent finalize cannot land between the
        read and the write. ``update_fields`` is explicit so unrelated form
        edits in the same admin session don't leak in.
        """
        updated = 0
        with transaction.atomic():
            for profile in queryset.select_for_update():
                profile.status = 'APPROVED'
                profile.rejection_reason = ''
                profile.save(update_fields=['status', 'rejection_reason'])
                updated += 1

        self.message_user(
            request,
            _('Approved %(n)d technician(s).') % {'n': updated},
            level=messages.SUCCESS,
        )

    @admin.action(description=_('Reject selected technicians'))
    def reject_selected(self, request, queryset):
        """Two-phase bulk reject.

        Phase 1 (GET-equivalent): render the intermediate page with a reason
        textarea. Phase 2 (POST with ``apply``): persist the reason atomically
        across selected rows.
        """
        if 'apply' in request.POST:
            form = _RejectionReasonForm(request.POST)
            if form.is_valid():
                reason = form.cleaned_data['rejection_reason']
                updated = 0
                with transaction.atomic():
                    for profile in queryset.select_for_update():
                        profile.status = 'REJECTED'
                        profile.rejection_reason = reason
                        profile.save(update_fields=['status', 'rejection_reason'])
                        updated += 1
                self.message_user(
                    request,
                    _('Rejected %(n)d technician(s).') % {'n': updated},
                    level=messages.SUCCESS,
                )
                return HttpResponseRedirect(request.get_full_path())
        else:
            form = _RejectionReasonForm()

        return render(
            request,
            'admin/technicians/reject_action.html',
            context={
                'technicians': queryset,
                'form': form,
                'action': 'reject_selected',
            },
        )

    # --- per-row quick actions ---------------------------------------------

    def get_urls(self):
        """Inject the unified approval-review endpoint alongside default URLs."""
        urls = super().get_urls()
        custom = [
            path(
                '<int:profile_id>/review/',
                self.admin_site.admin_view(self.approval_review_view),
                name='technicians_technicianprofile_review',
            ),
        ]
        return custom + urls

    def change_view(self, request, object_id, form_url='', extra_context=None):
        """Redirect PENDING techs to the dedicated approval review page.

        APPROVED / REJECTED / SUSPENDED profiles continue to use the
        default model change view (their data is reference, not action).
        PENDING is the action path: a clean photos + Approve/Reject
        screen, no model chrome, no programming fields.
        """
        try:
            profile = TechnicianProfile.objects.only('id', 'status').get(pk=object_id)
        except (TechnicianProfile.DoesNotExist, ValueError):
            return super().change_view(request, object_id, form_url, extra_context)

        if profile.status == 'PENDING':
            return redirect(
                'admin:technicians_technicianprofile_review',
                profile_id=object_id,
            )

        # APPROVED / REJECTED / suspended techs keep the editable admin
        # form (inlines for skills, schedule, wallet ledger are reference
        # data the supervisor still needs to reach). But we prepend the
        # same hero strip the /review/ page uses so visual family holds.
        full_profile = (
            TechnicianProfile.objects
            .select_related('user')
            .get(pk=profile.pk)
        )
        skills = list(
            TechnicianSkill.objects
            .filter(technician=full_profile)
            .select_related('sub_service', 'sub_service__service')
            .order_by('sub_service__service__name', 'sub_service__name')
        )
        extra_context = dict(extra_context or {})
        extra_context['fx_hero'] = {
            'profile': full_profile,
            'skills': skills,
            'status': full_profile.get_status_display(),
            'is_approved': full_profile.status == 'APPROVED',
            'is_rejected': full_profile.status == 'REJECTED',
            'is_suspended': not full_profile.is_active,
        }
        return super().change_view(request, object_id, form_url, extra_context)

    def approval_review_view(self, request, profile_id: int):
        """Dedicated approval landing — photos + identity + Approve/Reject.

        Replaces the database model change page for PENDING techs. The
        rest of the technician's data (skills, schedule, wallet ledger)
        is irrelevant *at approval time* — the supervisor's only job
        is to verify identity from the photos and decide. Once approved
        / rejected, the model change page is what's shown.

        POST handles both ``action=approve`` and ``action=reject`` in
        one endpoint so the form doesn't need to route between two
        URLs. Reject without a reason is refused at the form layer.
        """
        try:
            profile = TechnicianProfile.objects.select_related('user').get(pk=profile_id)
        except TechnicianProfile.DoesNotExist:
            self.message_user(request, _('Technician not found.'), messages.ERROR)
            return redirect('admin:technicians_technicianprofile_changelist')

        # PENDING and REJECTED techs share this page: PENDING is the
        # first-time decision; REJECTED is the re-decision (admin can
        # change their mind / re-approve after the tech updates their
        # docs). APPROVED has nothing left to decide — fall through to
        # the model detail.
        if profile.status not in ('PENDING', 'REJECTED'):
            self.message_user(
                request,
                _('%(name)s is already %(status)s — opening detail page.') % {
                    'name': profile.user.get_full_name() or profile.user.username,
                    'status': profile.get_status_display(),
                },
                level=messages.INFO,
            )
            return redirect(
                'admin:technicians_technicianprofile_change',
                object_id=profile_id,
            )

        if request.method == 'POST':
            action = request.POST.get('action', '')
            if action == 'approve':
                with transaction.atomic():
                    locked = TechnicianProfile.objects.select_for_update().get(pk=profile.pk)
                    locked.status = 'APPROVED'
                    locked.rejection_reason = ''
                    locked.save(update_fields=['status', 'rejection_reason'])
                self.message_user(
                    request,
                    _('Approved %(name)s.') % {
                        'name': profile.user.get_full_name() or profile.user.username,
                    },
                    level=messages.SUCCESS,
                )
                return redirect('admin:technicians_technicianprofile_changelist')

            if action == 'reject':
                form = _RejectionReasonForm(request.POST)
                if form.is_valid():
                    reason = form.cleaned_data['rejection_reason']
                    with transaction.atomic():
                        locked = TechnicianProfile.objects.select_for_update().get(pk=profile.pk)
                        locked.status = 'REJECTED'
                        locked.rejection_reason = reason
                        locked.save(update_fields=['status', 'rejection_reason'])
                    self.message_user(
                        request,
                        _('Rejected %(name)s.') % {
                            'name': profile.user.get_full_name() or profile.user.username,
                        },
                        level=messages.SUCCESS,
                    )
                    return redirect('admin:technicians_technicianprofile_changelist')
            else:
                form = _RejectionReasonForm()
        else:
            form = _RejectionReasonForm()

        # Pull what the technician is asking to be approved FOR — the
        # admin's decision is service-scoped, not just identity-scoped.
        # A tech with valid CNIC but no skills selected has nothing to
        # be approved into; surfacing skills here forces that question.
        skills = (
            TechnicianSkill.objects
            .filter(technician=profile)
            .select_related('sub_service', 'sub_service__service')
            .order_by('sub_service__service__name', 'sub_service__name')
        )
        licenses = (
            TechnicianServiceLicense.objects
            .filter(technician=profile)
            .select_related('service')
            .order_by('service__name')
        )

        return render(
            request,
            'admin/technicians/approval_review.html',
            context={
                'title': f'Review {profile.user.get_full_name() or profile.user.username}',
                'profile': profile,
                'documents_strip': self.documents_strip(profile),
                'form': form,
                'opts': self.model._meta,
                'skills': skills,
                'licenses': licenses,
                # Friendly identity strip — no internal flags.
                'identity_rows': [
                    ('Full name', profile.user.get_full_name() or '—'),
                    ('Phone', getattr(getattr(profile.user, 'userprofile', None), 'phone', None) or '—'),
                    ('CNIC', profile.cnic_number or '—'),
                    ('City', profile.city or '—'),
                    ('Applied at', profile.user.date_joined),
                ],
            },
        )

    @admin.display(description='Actions')
    def quick_actions(self, obj):
        """Inline action button rendered in the list cell.

        PENDING and REJECTED both route to the same unified review page
        — supervisor decides approve / reject from there. APPROVED has
        no pending decision so no button.
        """
        if obj.status in ('PENDING', 'REJECTED'):
            review_url = reverse('admin:technicians_technicianprofile_review', args=[obj.pk])
            label = 'Review' if obj.status == 'PENDING' else 'Re-review'
            return format_html(
                '<a class="fx-qbtn fx-qbtn-approve" href="{}">{}</a>',
                review_url, label,
            )
        return format_html('<span style="color:#9ca3af;font-size:11px">{}</span>', '—')

    # --- list-cell helpers --------------------------------------------------

    @admin.display(description='')
    def avatar(self, obj):
        return thumb(obj.profile_picture, size=40)

    @admin.display(description='Name', ordering='user__username')
    def user_label(self, obj):
        full = obj.user.get_full_name() or obj.user.username
        return format_html(
            '<div style="line-height:1.3"><div style="font-weight:600">{}</div>'
            '<div style="color:#6b7280;font-size:11px">@{}</div></div>',
            full, obj.user.username,
        )

    @admin.display(description='Status', ordering='status')
    def status_pill(self, obj):
        return pill(obj.get_status_display(), _STATUS_TONES.get(obj.status, 'neutral'))

    @admin.display(description='Rating', ordering='rating_average')
    def rating_label(self, obj):
        if not obj.review_count:
            return format_html('<span style="color:#9ca3af">{}</span>', 'No reviews')
        return format_html(
            '<span style="font-weight:600">★ {}</span>'
            '<span style="color:#6b7280;font-size:11px"> ({})</span>',
            f'{obj.rating_average:.2f}', obj.review_count,
        )

    @admin.display(description='Wallet', ordering='current_wallet_balance')
    def wallet_label(self, obj):
        bal = obj.current_wallet_balance
        if bal < 0:
            return format_html(
                '<span style="color:#991b1b;font-weight:700;font-family:ui-monospace,monospace">{}</span>',
                money_rs(bal),
            )
        return format_html(
            '<span style="font-family:ui-monospace,monospace">{}</span>',
            money_rs(bal),
        )

    @admin.display(description='Online', ordering='is_online')
    def online_pill(self, obj):
        return pill('Online', 'positive') if obj.is_online else pill('Offline', 'neutral')

    @admin.display(description='Active', ordering='is_active')
    def active_pill(self, obj):
        return pill('Active', 'positive') if obj.is_active else pill('Suspended', 'negative')

    @admin.display(description='Profile picture')
    def profile_picture_preview(self, obj):
        return thumb(obj.profile_picture, size=180)

    @admin.display(description='CNIC front')
    def cnic_preview(self, obj):
        return thumb(obj.cnic_front_image, size=180)

    @admin.display(description='')
    def documents_strip(self, obj):
        """Side-by-side strip: profile picture · CNIC · every license image.

        Lives at the top of the change form so the supervisor sees every
        document needed for identity verification at a glance — without
        scrolling between collapsed fieldsets. Each thumb is click-to-
        lightbox (CSS-only :target overlay).
        """
        items: list[ImageGridItem] = []
        if obj.profile_picture:
            items.append(ImageGridItem(
                image_field=obj.profile_picture,
                caption='Profile picture',
                subcaption='Selfie at onboarding',
            ))
        if obj.cnic_front_image:
            items.append(ImageGridItem(
                image_field=obj.cnic_front_image,
                caption='CNIC (front)',
                subcaption=obj.cnic_number,
            ))
        for license in obj.service_licenses.select_related('service').all():
            items.append(ImageGridItem(
                image_field=license.license_picture,
                caption=f'License: {license.service.name}',
                subcaption='Service-licence document',
            ))
        return image_grid(items, size=160)

    # --- suspend / reinstate actions ---------------------------------------

    @admin.action(description=_('Suspend technician (force offline)'))
    def suspend_selected(self, request, queryset):
        """Atomically: is_active=False, is_online=False — kicks the tech
        offline and removes them from the matchmaker. The same flow a
        wallet-lockout takes; here it's admin-initiated suspension."""
        updated = 0
        with transaction.atomic():
            for profile in queryset.filter(is_active=True).select_for_update():
                profile.is_active = False
                profile.is_online = False
                profile.save(update_fields=['is_active', 'is_online'])
                updated += 1
        self.message_user(
            request,
            _('Suspended %(n)d technician(s).') % {'n': updated},
            level=messages.SUCCESS,
        )

    @admin.action(description=_('Reinstate technician'))
    def reinstate_selected(self, request, queryset):
        """Flip is_active back to True. is_online stays False — coming
        back online is intentionally an explicit tech action per
        ``wallet-money-mechanics`` memory."""
        updated = 0
        with transaction.atomic():
            for profile in queryset.filter(is_active=False).select_for_update():
                profile.is_active = True
                profile.save(update_fields=['is_active'])
                updated += 1
        self.message_user(
            request,
            _('Reinstated %(n)d technician(s).') % {'n': updated},
            level=messages.SUCCESS,
        )


# -------------------------------------------------------------------------
# Standalone admins for the secondary models
# -------------------------------------------------------------------------


# Standalone admins removed in the scope-reduction pass:
#   * TechnicianSkill — already inline on TechnicianProfileAdmin
#   * TechnicianServiceLicense — already inline
#   * TechnicianSchedule — already inline (the 7-day grid lives there)
#   * TechnicianServicePerformance — already inline (read-only Bayesian inputs)
# Each standalone view duplicated its inline with weaker UX and added a
# sidebar entry the supervisor never opens. Forensic filtering by skill /
# day-of-week / service is rare enough to drop the management/SQL shell
# when needed.


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    """Customer reviews post-booking.

    Read-only — reviews are user-generated content; admin can audit and
    delete (moderation) but never edit text on a customer's behalf.
    """

    list_display = (
        'id', 'created_at', 'technician_link',
        'reviewer_label', 'rating_stars', 'text_short',
    )
    list_filter = ('rating',)
    search_fields = (
        'technician__user__username',
        'reviewer__username',
        'text',
    )
    date_hierarchy = 'created_at'
    ordering = ('-created_at',)
    list_per_page = 40
    list_select_related = ('technician', 'technician__user', 'reviewer')
    readonly_fields = ('technician', 'reviewer', 'rating', 'text', 'created_at')

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return True  # view only; readonly_fields locks edits

    @admin.display(description='Technician', ordering='technician__user__username')
    def technician_link(self, obj):
        url = reverse('admin:technicians_technicianprofile_change', args=[obj.technician_id])
        return format_html(
            '<a href="{}">{}</a>',
            url, obj.technician.user.get_full_name() or obj.technician.user.username,
        )

    @admin.display(description='Reviewer', ordering='reviewer__username')
    def reviewer_label(self, obj):
        if obj.reviewer is None:
            return format_html('<em style="color:#9ca3af">{}</em>', '(deleted user)')
        return obj.reviewer.get_full_name() or obj.reviewer.username

    @admin.display(description='Rating', ordering='rating')
    def rating_stars(self, obj):
        filled = '★' * obj.rating
        empty = '☆' * (5 - obj.rating)
        color = '#16a34a' if obj.rating >= 4 else ('#f59e0b' if obj.rating == 3 else '#dc2626')
        return format_html(
            '<span style="color:{};font-size:14px;letter-spacing:1px">{}{}</span>',
            color, filled, empty,
        )

    @admin.display(description='Review')
    def text_short(self, obj):
        return truncate(obj.text, 100)


# TemporaryMediaAdmin removed in scope-reduction. The model is an
# onboarding staging table cleared on registration finalise — nothing
# in it survives the flow. Visible-but-empty is just clutter; if a
# row needs forensic inspection, ``./manage.py shell`` is correct.

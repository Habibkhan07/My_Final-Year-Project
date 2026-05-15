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
from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.utils.translation import gettext_lazy as _

from .models import (
    Service,
    SubService,
    TechnicianProfile,
    TechnicianSkill,
    TechnicianServiceLicense,
    TemporaryMedia,
)


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
    model = TechnicianSkill
    extra = 0
    fields = ('sub_service', 'years_of_experience', 'labor_rate')


class TechnicianServiceLicenseInline(admin.TabularInline):
    model = TechnicianServiceLicense
    extra = 0
    fields = ('service', 'license_picture')


@admin.register(TechnicianProfile)
class TechnicianProfileAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'user',
        'status',
        'city',
        'cnic_number',
        'is_active',
        'is_online',
    )
    list_filter = ('status', 'city', 'is_active', 'is_online')
    search_fields = (
        'user__username',
        'user__first_name',
        'user__last_name',
        'cnic_number',
    )
    readonly_fields = (
        'rating_average',
        'review_count',
        'current_wallet_balance',
    )
    inlines = [TechnicianSkillInline, TechnicianServiceLicenseInline]
    actions = ['approve_selected', 'reject_selected']
    ordering = ('-id',)

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


# Catalog + staging models — light registration. Catalog has its own admin
# in ``catalog/admin.py`` if a richer view is needed; these are here so
# they're at least browsable from a single technicians page.
admin.site.register(Service)
admin.site.register(SubService)
admin.site.register(TechnicianSkill)
admin.site.register(TemporaryMedia)

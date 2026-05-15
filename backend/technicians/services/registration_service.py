import os

from django.contrib.auth import get_user_model
from django.db import transaction

from accounts.models import UserProfile

from ..exceptions import DuplicateActiveApplicationError
from ..models import TechnicianProfile, TechnicianServiceLicense, TechnicianSkill

User = get_user_model()


def finalize_registration(*, user, validated_data):
    """Finalize a technician application for the given user.

    Three branches:

    1. **No existing profile** — create one (the original happy path).
    2. **Existing profile, status == 'REJECTED'** — reset in place. The OneToOne
       to ``User`` is preserved, ``rejection_reason`` is cleared, the row goes
       back to ``PENDING``, and old skills + licenses are wiped so the new
       submission's data is authoritative. Profile + CNIC images are replaced.
    3. **Existing profile, status in ('PENDING', 'APPROVED')** — raise
       :class:`DuplicateActiveApplicationError` (HTTP 409). A pending review is
       in flight (or already accepted) and a second submit would race it.

    Atomic: the whole flow runs inside a single ``transaction.atomic()`` block
    so a mid-way failure (image save, skill insert) cannot leave a half-reset
    profile behind.
    """
    skills_data = validated_data.pop('skills')
    category_licenses_data = validated_data.pop('category_licenses', [])
    profile_file = validated_data.pop('profile_picture_file')
    cnic_file = validated_data.pop('cnic_picture_file')

    first_name = validated_data.pop('first_name')
    last_name = validated_data.pop('last_name')

    with transaction.atomic():
        # Lock the User row first so two concurrent finalize calls for the
        # same user serialise. Without this, the first-time-apply path
        # (where no TechnicianProfile exists yet) is unprotected:
        # ``filter(user=user).select_for_update()`` returns an empty queryset,
        # acquires no row lock, and both tabs race past the duplicate check
        # before crashing on the OneToOne IntegrityError. Locking the User
        # row turns that race into a clean 409 on the loser.
        User.objects.select_for_update().get(pk=user.pk)

        existing = (
            TechnicianProfile.objects
            .select_for_update()
            .filter(user=user)
            .first()
        )

        if existing is not None and existing.status in ('PENDING', 'APPROVED'):
            raise DuplicateActiveApplicationError(current_status=existing.status)

        # Update core user details.
        user.first_name = first_name
        user.last_name = last_name
        user.save()

        # Flip the UserProfile.is_technician flag so verify-otp returns the
        # correct value on the next login. Without this the wire field stays
        # False forever and the router can never route a real tech to the
        # tech surface — even after approval.
        #
        # Most users hit the first branch — UserProfile is created during
        # process_otp_verification. The fallback handles Users created
        # outside the OTP path (Django admin, fixtures, shell) which
        # would otherwise crash on the ``user.userprofile`` access with
        # ``RelatedObjectDoesNotExist``. ``user.username`` is the phone
        # number in this app's auth flow (set by process_otp_verification),
        # so falling back to it preserves the UserProfile invariant.
        try:
            profile_obj = user.userprofile
            profile_obj.is_technician = True
            profile_obj.save(update_fields=['is_technician'])
        except UserProfile.DoesNotExist:
            UserProfile.objects.create(
                user=user,
                phone=user.username,
                is_technician=True,
            )

        if existing is not None:
            # REJECTED → re-application. Reset in place.
            profile = existing
            profile.status = 'PENDING'
            profile.rejection_reason = ''
            # Apply the new form values onto the existing row.
            for field, value in validated_data.items():
                setattr(profile, field, value)
            # Wipe old skills + licenses; the new submission replaces them.
            profile.technicianskill_set.all().delete()
            profile.service_licenses.all().delete()
        else:
            profile = TechnicianProfile(user=user, **validated_data)

        # Re-attach the new images. ``save=False`` defers the file-field save
        # until the row-level ``.save()`` below, so one DB write covers all.
        if profile_file:
            clean_name = os.path.basename(profile_file.name)
            profile.profile_picture.save(clean_name, profile_file, save=False)

        if cnic_file:
            clean_name = os.path.basename(cnic_file.name)
            profile.cnic_front_image.save(clean_name, cnic_file, save=False)

        profile.save()

        # Category-level licenses (parent Service, e.g. Plumbing).
        for cat_lic in category_licenses_data:
            new_license = TechnicianServiceLicense(
                technician=profile,
                service_id=cat_lic['service_id'],
            )
            if cat_lic.get('license_file'):
                clean_name = os.path.basename(cat_lic['license_file'].name)
                new_license.license_picture.save(
                    clean_name,
                    cat_lic['license_file'],
                    save=False,
                )
            new_license.save()

        # SubService-level skill rows.
        for skill in skills_data:
            TechnicianSkill.objects.create(
                technician=profile,
                sub_service_id=skill['sub_service_id'],
                years_of_experience=skill['years_of_experience'],
                labor_rate=skill.get('labor_rate'),
            )

    return profile

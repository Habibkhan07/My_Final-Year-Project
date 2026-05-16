"""Backfill ``TechnicianServiceLicense`` rows for existing technicians.

Context: migration 0011 made ``license_picture`` nullable and added a
``unique_together`` on ``(technician, service)`` so the table can serve
as the source of truth for "which categories did this tech opt into."
The skills CRUD endpoint (``add_skill``) reads this table to gate adds;
the picker endpoint (``/me/service-categories/``) reads it to filter
the catalog.

Existing technicians (created before this redesign) have ZERO license
rows — onboarding only inserted them when the tech uploaded a license
file. Without a backfill, every approved tech would be locked out of
adding any new skill: the gate sees an empty license set and rejects
every parent service.

This migration derives each existing tech's parent-service set from
their current ``TechnicianSkill`` rows and creates the matching license
rows. ``license_picture`` stays NULL — admin can attach the legal
documents out-of-band; the gate cares only about row existence.

Idempotent via ``get_or_create``: re-running is a no-op (and the
``unique_together`` index would refuse duplicates anyway).

Reverse: a no-op. Once rolled forward, we can't distinguish backfilled
rows from rows created at onboarding-finalize time, so blanket-deleting
on reverse would discard real opt-in data. The forward migration is
safe to re-run; reverse just leaves rows in place.
"""
from django.db import migrations


def backfill_service_licenses(apps, schema_editor):
    TechnicianProfile = apps.get_model('technicians', 'TechnicianProfile')
    TechnicianServiceLicense = apps.get_model(
        'technicians', 'TechnicianServiceLicense',
    )

    for profile in TechnicianProfile.objects.all():
        # Derive parent service set from this tech's current skills.
        # ``distinct()`` collapses duplicates when a tech has multiple
        # skills under the same parent service.
        service_ids = (
            profile.technicianskill_set
            .values_list('sub_service__service_id', flat=True)
            .distinct()
        )
        for service_id in service_ids:
            TechnicianServiceLicense.objects.get_or_create(
                technician=profile,
                service_id=service_id,
            )


class Migration(migrations.Migration):

    dependencies = [
        ('technicians', '0011_alter_technicianservicelicense_license_picture_and_more'),
    ]

    operations = [
        migrations.RunPython(
            backfill_service_licenses,
            reverse_code=migrations.RunPython.noop,
        ),
    ]

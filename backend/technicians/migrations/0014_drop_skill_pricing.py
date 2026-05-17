"""Drop ``years_of_experience`` and ``labor_rate`` from ``TechnicianSkill``.

Context: the onboarding refactor in 2026-05-17 removed the
"Skill Pricing" step (formerly step 5 of the wizard). The two columns
on the bridge row went with it:

* ``years_of_experience`` — write-only. Captured in the wizard, stored
  on the row, but never consulted by any production read path. Safe to
  drop without replacement.
* ``labor_rate`` — the only field with a live runtime read. Used by
  ``bookings.selectors.pricing_selector.resolve_booking_intent`` in the
  LABOR_GIG scenario to set ``JobBooking.price_amount``. Replaced by
  ``catalog.SubService.base_price`` (existing column) — the platform
  sets the labor figure now, not the technician. The pricing selector
  was updated in the same patch so this migration is the lockstep half.

Data loss: existing techs lose their per-skill labor_rate values. New
LABOR_GIG bookings to those techs now stamp ``sub_service.base_price``
onto ``JobBooking.price_amount``. Existing bookings already have the
amount snapshotted on ``JobBooking.price_amount`` and are unaffected.

Reverse: not provided. The data is gone; the catalog price replaces it.
"""
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('technicians', '0013_drop_profile_metadata'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='technicianskill',
            name='years_of_experience',
        ),
        migrations.RemoveField(
            model_name='technicianskill',
            name='labor_rate',
        ),
    ]

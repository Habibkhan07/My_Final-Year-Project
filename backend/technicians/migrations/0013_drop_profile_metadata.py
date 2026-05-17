"""Drop ``experience_years`` and ``bio`` from ``TechnicianProfile``.

Context: the onboarding refactor in 2026-05-17 trimmed the wizard from
6 steps to 5. Two profile-metadata fields were dropped in the process:

* ``experience_years`` — display-only number on the admin approval
  screen and the customer-facing technician profile JSON. Never gated
  matchmaking, never influenced ranking. The corresponding form field
  in step 2 of onboarding was removed.
* ``bio`` — free-text shown to the customer on the booking-checkout
  technician profile screen. Rarely populated meaningfully, dropped
  with the rest of step 2.

No data preservation: the columns carried free-text/numeric values that
have no analogue in the new schema (no aggregation, no audit obligation).
The values are lost on roll-forward — acceptable given the scrap.

Reverse: not provided. Once dropped, the column ordering and any data
that lived in these fields cannot be reconstructed.
"""
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('technicians', '0012_backfill_service_licenses'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='technicianprofile',
            name='experience_years',
        ),
        migrations.RemoveField(
            model_name='technicianprofile',
            name='bio',
        ),
    ]

"""
Split STATUS_REJECTED into two distinct end states.

Before this migration, both "tech tapped Decline" and "SLA timer fired
before tech replied" produced the same ``REJECTED`` status, with the
cause living only on the WS event payload's ``reason`` field. That
field is invisible to orchestrator detail refetches, so the customer's
screen could not differentiate the two on cold reload.

After: ``TECH_DECLINED`` and ``TECH_NO_RESPONSE`` are first-class
statuses. The cause is a type-system fact, not a side channel.

The data migration converts any historical ``REJECTED`` rows to
``TECH_DECLINED`` (the safer default — assumes active refusal rather
than ghosting). The dev DB has zero such rows at migration time; this
default exists only for safety, not because we expect rows to migrate.
"""
from django.db import migrations, models


def _rejected_to_tech_declined(apps, schema_editor):
    JobBooking = apps.get_model('bookings', 'JobBooking')
    JobBooking.objects.filter(status='REJECTED').update(status='TECH_DECLINED')


def _tech_declined_to_rejected(apps, schema_editor):
    """Reverse migration: collapse both new statuses back to REJECTED.

    Information is lost on reverse — TECH_NO_RESPONSE rows can no longer
    be distinguished from active declines. Acceptable: the schema before
    this migration didn't model the distinction either.
    """
    JobBooking = apps.get_model('bookings', 'JobBooking')
    JobBooking.objects.filter(
        status__in=['TECH_DECLINED', 'TECH_NO_RESPONSE']
    ).update(status='REJECTED')


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0012_supportticket_resolution_v2'),
    ]

    operations = [
        migrations.AlterField(
            model_name='jobbooking',
            name='status',
            field=models.CharField(
                choices=[
                    ('AWAITING', 'Awaiting tech accept'),
                    ('CONFIRMED', 'Confirmed'),
                    ('EN_ROUTE', 'En route'),
                    ('ARRIVED', 'Arrived'),
                    ('INSPECTING', 'Inspecting'),
                    ('QUOTED', 'Quoted'),
                    ('IN_PROGRESS', 'In progress'),
                    ('COMPLETED', 'Completed'),
                    ('COMPLETED_INSPECTION_ONLY', 'Completed (inspection only)'),
                    ('CANCELLED', 'Cancelled'),
                    ('REJECTED', 'Rejected'),  # transient — removed below
                    ('TECH_DECLINED', 'Tech declined'),
                    ('TECH_NO_RESPONSE', "Tech didn't respond"),
                    ('NO_SHOW', 'No show'),
                    ('DISPUTED', 'Disputed'),
                    ('PENDING', 'Pending (legacy, do not use for new bookings)'),
                ],
                default='AWAITING',
                max_length=32,
            ),
        ),
        migrations.RunPython(
            _rejected_to_tech_declined,
            reverse_code=_tech_declined_to_rejected,
        ),
        # Second AlterField drops 'REJECTED' from choices after the data
        # migration has moved every row off it. Doing this in one AlterField
        # would prevent the RunPython from finding 'REJECTED' rows to
        # convert (the CHECK would reject the read, on some DBs).
        migrations.AlterField(
            model_name='jobbooking',
            name='status',
            field=models.CharField(
                choices=[
                    ('AWAITING', 'Awaiting tech accept'),
                    ('CONFIRMED', 'Confirmed'),
                    ('EN_ROUTE', 'En route'),
                    ('ARRIVED', 'Arrived'),
                    ('INSPECTING', 'Inspecting'),
                    ('QUOTED', 'Quoted'),
                    ('IN_PROGRESS', 'In progress'),
                    ('COMPLETED', 'Completed'),
                    ('COMPLETED_INSPECTION_ONLY', 'Completed (inspection only)'),
                    ('CANCELLED', 'Cancelled'),
                    ('TECH_DECLINED', 'Tech declined'),
                    ('TECH_NO_RESPONSE', "Tech didn't respond"),
                    ('NO_SHOW', 'No show'),
                    ('DISPUTED', 'Disputed'),
                    ('PENDING', 'Pending (legacy, do not use for new bookings)'),
                ],
                default='AWAITING',
                max_length=32,
            ),
        ),
    ]

# Dispute-flow rebuild: splits the resolution model from a three-way
# outcome to binary ACCEPT_REFUND / REJECT, with the "how much does the
# tech pay" decision moved into ``tech_penalty_percentage``. Adds the
# external refund reference admin types after manually sending the
# JazzCash refund, and the customer-facing message that ships in the
# DISPUTE_RESOLVED realtime broadcast.
#
# Legacy OUTCOME_REFUND_CUSTOMER / OUTCOME_PENALIZE_TECH / OUTCOME_DISMISS
# values stay in CHOICES so any pre-existing RESOLVED rows still
# validate; new resolutions only write ACCEPT_REFUND or REJECT.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0011_jobbooking_customer_acknowledged_arrival_at'),
    ]

    operations = [
        migrations.AddField(
            model_name='supportticket',
            name='tech_penalty_percentage',
            field=models.PositiveSmallIntegerField(
                default=0,
                help_text='0–100. Percent of refund debited from tech wallet on '
                          'ACCEPT_REFUND. 0 = platform absorbs. 100 = tech absorbs.',
            ),
        ),
        migrations.AddField(
            model_name='supportticket',
            name='external_refund_reference',
            field=models.CharField(
                blank=True,
                default='',
                max_length=80,
                help_text='Gateway txn id of the refund admin sent to customer. '
                          'Required when outcome is ACCEPT_REFUND.',
            ),
        ),
        migrations.AddField(
            model_name='supportticket',
            name='customer_notification_message',
            field=models.TextField(
                blank=True,
                default='',
                help_text='Plain-text message surfaced to the customer in-app '
                          'when the dispute closes. Pakistani-Urdu phrasing OK.',
            ),
        ),
        migrations.AlterField(
            model_name='supportticket',
            name='resolution_outcome',
            field=models.CharField(
                choices=[
                    ('NONE', 'None'),
                    ('ACCEPT_REFUND', 'Accept (refund customer)'),
                    ('REJECT', 'Reject (close, no refund)'),
                    ('REFUND_CUSTOMER', 'Refund customer (legacy)'),
                    ('PENALIZE_TECH', 'Penalize tech (legacy)'),
                    ('DISMISS', 'Dismiss (legacy)'),
                ],
                default='NONE',
                max_length=32,
            ),
        ),
    ]

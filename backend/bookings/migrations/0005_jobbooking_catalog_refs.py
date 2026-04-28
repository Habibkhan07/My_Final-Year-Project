# Adds catalog reference FKs to JobBooking to capture customer discovery
# intent at booking time. service is added nullable here as the first
# phase of a two-step rollout; once the booking service is updated to
# populate it on every new booking, a follow-up migration tightens
# service to NOT NULL.
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0004_jobbooking_accepted_at'),
        ('catalog', '0007_add_duration_minutes'),
        ('marketing', '0002_remove_promotion_target_subservice_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='jobbooking',
            name='service',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name='bookings',
                to='catalog.service',
            ),
        ),
        migrations.AddField(
            model_name='jobbooking',
            name='sub_service',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name='bookings',
                to='catalog.subservice',
            ),
        ),
        migrations.AddField(
            model_name='jobbooking',
            name='promotion',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='bookings',
                to='marketing.promotion',
            ),
        ),
    ]

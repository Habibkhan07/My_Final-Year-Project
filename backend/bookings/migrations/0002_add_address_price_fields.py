import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0001_create_job_booking'),
        ('customers', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='jobbooking',
            name='address',
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='bookings',
                to='customers.savedaddress',
            ),
        ),
        migrations.AddField(
            model_name='jobbooking',
            name='price_amount',
            # Existing test/dev rows get 0.00 — production has no rows at this point
            field=models.DecimalField(decimal_places=2, default=0, max_digits=10),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='jobbooking',
            name='price_context',
            field=models.CharField(blank=True, default='', max_length=50),
        ),
    ]

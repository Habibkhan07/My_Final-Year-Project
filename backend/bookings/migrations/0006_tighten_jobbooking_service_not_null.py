# Phase 2 of the catalog-FK rollout: tighten JobBooking.service to NOT NULL.
# Phase 1 (migration 0005) added the column nullable; the booking service
# now populates service on every write, and the populate_test_dashboard
# script has been updated to do the same. This migration locks in the
# database-level guarantee that no row can have service_id NULL.
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0005_jobbooking_catalog_refs'),
    ]

    operations = [
        migrations.AlterField(
            model_name='jobbooking',
            name='service',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.PROTECT,
                related_name='bookings',
                to='catalog.service',
            ),
        ),
    ]

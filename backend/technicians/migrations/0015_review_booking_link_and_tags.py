"""Wire ``Review`` rows to a specific ``JobBooking`` + add structured tags.

Context: the customer-side review surface (per ``project_tech_reviews``
memory, ``technicians/api/reviews/``) ships in 2026-05-18 viva sprint.
Three changes on the existing ``Review`` model:

* ``booking`` — ``OneToOneField`` to ``JobBooking``. One review per
  booking is the wire invariant; the OneToOne is the duplicate-prevention
  gate at the database level. ``null=True`` so existing dev-seeded rows
  (no booking link) survive the migration. ``technicians.services.
  review_service.submit_review`` enforces non-null on every new write.
  ``on_delete=CASCADE`` — a review without its booking is orphan data;
  production never hard-deletes bookings (only status transitions), so
  CASCADE only fires under dev-wipe flows and explicit admin cleanup.
* ``tags`` — ``JSONField(default=list)``. Stores stable string keys
  from ``technicians.constants.review_tags.ALL_TAG_KEYS``. Keys (not
  display labels) so copy edits don't require data migration. MySQL
  JSON column, no PostgreSQL-only feature gate.
* ``text`` — relaxed to ``blank=True``. Tags + stars are the primary
  signal; the free-text field is now optional.

No backfill required: ``null=True`` + ``default=list`` means existing
rows continue to validate as-is. The service layer prevents new
booking-less rows on the customer review flow.
"""
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0013_split_rejected_status'),
        ('technicians', '0014_drop_skill_pricing'),
    ]

    operations = [
        migrations.AddField(
            model_name='review',
            name='booking',
            field=models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='review', to='bookings.jobbooking'),
        ),
        migrations.AddField(
            model_name='review',
            name='tags',
            field=models.JSONField(blank=True, default=list),
        ),
        migrations.AlterField(
            model_name='review',
            name='text',
            field=models.TextField(blank=True),
        ),
    ]

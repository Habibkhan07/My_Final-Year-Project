# Closes flag #1: collapse the "still awaiting tech accept" signal from
# (status=CONFIRMED, accepted_at IS NULL) into a single explicit status value.
#
# - RemoveField(accepted_at): the column was a side-field signal; the AWAITING
#   status now carries the meaning. Pre-launch project, no production data, so
#   no data migration is required.
# - AlterField(status): keep the choices list in sync with the model (advisory,
#   but flagged in code review if it drifts).
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0006_tighten_jobbooking_service_not_null'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='jobbooking',
            name='accepted_at',
        ),
        migrations.AlterField(
            model_name='jobbooking',
            name='status',
            field=models.CharField(
                choices=[
                    ('PENDING', 'Pending'),
                    ('AWAITING', 'Awaiting Tech Accept'),
                    ('CONFIRMED', 'Confirmed'),
                    ('COMPLETED', 'Completed'),
                    ('CANCELLED', 'Cancelled'),
                    ('REJECTED', 'Rejected'),
                ],
                default='PENDING',
                max_length=10,
            ),
        ),
    ]

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('technicians', '0009_alter_technicianprofile_status_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='technicianprofile',
            name='work_address_label',
            field=models.CharField(blank=True, max_length=200, null=True),
        ),
    ]

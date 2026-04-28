from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('technicians', '0006_technicianprofile_current_wallet_balance_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='technicianskill',
            name='max_rate',
        ),
        migrations.RenameField(
            model_name='technicianskill',
            old_name='base_rate',
            new_name='labor_rate',
        ),
    ]

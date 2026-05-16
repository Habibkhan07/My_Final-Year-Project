"""Rename the ``finance_admin`` Django auth Group to ``admin``.

The role's responsibilities are unchanged (wallet ledger + payout
accounts + withdrawal queue + RefundIntent IBANs + unredacted
chat_log). Only the display name changes — existing user-Group
assignments are preserved by the rename so anyone in finance_admin
yesterday stays in admin today.

Idempotent: re-running the migration is a no-op if the rename has
already happened, and is also safe in environments where the old
group never existed (e.g. fresh dev DBs).
"""
from django.db import migrations


def _rename_finance_admin_to_admin(apps, _schema_editor):
    Group = apps.get_model("auth", "Group")
    old = Group.objects.filter(name="finance_admin").first()
    new = Group.objects.filter(name="admin").first()
    if old is None:
        # Either fresh DB, or already renamed — nothing to do.
        return
    if new is not None and new.pk != old.pk:
        # Both exist (unusual but defensive): move members from the old
        # group into the new and delete the old. Django's User.groups
        # is a m2m, so a simple ``add`` is idempotent.
        for user in old.user_set.all():
            new.user_set.add(user)
        old.delete()
        return
    old.name = "admin"
    old.save(update_fields=["name"])


def _rename_admin_to_finance_admin(apps, _schema_editor):
    Group = apps.get_model("auth", "Group")
    cur = Group.objects.filter(name="admin").first()
    if cur is None:
        return
    cur.name = "finance_admin"
    cur.save(update_fields=["name"])


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0004_supervisor_engineer_groups"),
        # disputes/0002 created the ``finance_admin`` Group originally;
        # this rename must run after it (otherwise fresh test DBs would
        # see no group at rename time and the rename would no-op, then
        # disputes/0002 would create the group under the OLD name).
        ("disputes", "0002_finance_admin_group"),
    ]

    operations = [
        migrations.RunPython(
            _rename_finance_admin_to_admin,
            _rename_admin_to_finance_admin,
        ),
    ]

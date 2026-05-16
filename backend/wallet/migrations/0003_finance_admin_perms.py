"""Grant ``finance_admin`` group view-access to payout-account PII.

``TechnicianBankAccount`` and ``TechnicianJazzCashAccount`` hold full IBAN
and MSISDN data. Before this migration, any staff user with admin access
could read them. Brought to parity-of-protection with
``disputes.RefundIntent`` (which is already finance_admin-gated).

Granted to ``finance_admin``:
  - wallet.view_technicianbankaccount
  - wallet.view_technicianjazzcashaccount
  - wallet.view_withdrawalrequest      (so finance can audit the
                                        full payout target from the
                                        withdrawal change page)

NOT granted (admin is strictly read-only on these — writes come from
the JazzCash adapter / the tech-side withdrawal API):
  - add / change / delete perms on any of the three.

The group itself was created by ``disputes/migrations/0002_finance_admin_group``.
This migration assumes that ran first (declared as a dependency).
"""
from __future__ import annotations

from django.db import migrations


FINANCE_ADMIN_GROUP = "finance_admin"

PERMS_TO_GRANT = [
    # (app_label, model, codename)
    ("wallet", "technicianbankaccount", "view_technicianbankaccount"),
    ("wallet", "technicianjazzcashaccount", "view_technicianjazzcashaccount"),
    ("wallet", "withdrawalrequest", "view_withdrawalrequest"),
]


def grant_perms(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    group, _ = Group.objects.get_or_create(name=FINANCE_ADMIN_GROUP)

    for app_label, model, codename in PERMS_TO_GRANT:
        try:
            ct = ContentType.objects.get(app_label=app_label, model=model)
            perm = Permission.objects.get(content_type=ct, codename=codename)
        except (ContentType.DoesNotExist, Permission.DoesNotExist):
            # Skip silently if a model migration ran out of order; admin
            # will visibly lack the permission until re-applied.
            continue
        group.permissions.add(perm)


def revoke_perms(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    try:
        group = Group.objects.get(name=FINANCE_ADMIN_GROUP)
    except Group.DoesNotExist:
        return

    for app_label, model, codename in PERMS_TO_GRANT:
        try:
            ct = ContentType.objects.get(app_label=app_label, model=model)
            perm = Permission.objects.get(content_type=ct, codename=codename)
        except (ContentType.DoesNotExist, Permission.DoesNotExist):
            continue
        group.permissions.remove(perm)


class Migration(migrations.Migration):

    dependencies = [
        ("wallet", "0002_wallettopup_gateway_request_payload"),
        ("disputes", "0002_finance_admin_group"),
        ("auth", "0012_alter_user_first_name_max_length"),
        ("contenttypes", "0002_remove_content_type_name"),
    ]

    operations = [
        migrations.RunPython(grant_perms, revoke_perms),
    ]

"""Create the ``finance_admin`` Django auth group.

The chatbot dispute persona writes ``bookings.SupportTicket`` rows AND
``disputes.RefundIntent`` rows when a customer completes a dispute chat.
Regular staff need to triage tickets but MUST NOT see customer bank
details — that visibility is gated behind this group.

Permissions granted:
  - bookings.view_supportticket   (read the dispute queue)
  - bookings.change_supportticket (resolve/adjudicate)
  - disputes.view_refundintent    (read bank details when paying out)

NOT granted:
  - disputes.add_refundintent     (chatbot service creates these — never
                                  hand-entered through admin)
  - disputes.change_refundintent  (PII is write-once; if wrong, customer
                                  files a new dispute)
  - disputes.delete_refundintent  (audit retention; rows survive ticket
                                  resolution)

Reverse migration deletes the group. Idempotent: re-applying after an
existing group is safe (get_or_create).
"""
from __future__ import annotations

from django.db import migrations


FINANCE_ADMIN_GROUP = "finance_admin"

PERMS_TO_GRANT = [
    # (app_label, model, codename)
    ("bookings", "supportticket", "view_supportticket"),
    ("bookings", "supportticket", "change_supportticket"),
    ("disputes", "refundintent", "view_refundintent"),
]


def create_finance_admin_group(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    group, _ = Group.objects.get_or_create(name=FINANCE_ADMIN_GROUP)

    for app_label, model, codename in PERMS_TO_GRANT:
        try:
            ct = ContentType.objects.get(app_label=app_label, model=model)
            perm = Permission.objects.get(content_type=ct, codename=codename)
        except (ContentType.DoesNotExist, Permission.DoesNotExist):
            # Skip silently if a model migration ran out of order — the
            # group will be missing a permission, which is visible in admin
            # and trivially fixed by re-running this migration.
            continue
        group.permissions.add(perm)


def reverse_finance_admin_group(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Group.objects.filter(name=FINANCE_ADMIN_GROUP).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("disputes", "0001_initial"),
        # SupportTicket exists by 0008; depend on the latest known bookings
        # migration so any future column adds also land before this data
        # migration grants permissions on the model.
        ("bookings", "0011_jobbooking_customer_acknowledged_arrival_at"),
        ("auth", "0012_alter_user_first_name_max_length"),
        ("contenttypes", "0002_remove_content_type_name"),
    ]

    operations = [
        migrations.RunPython(
            create_finance_admin_group,
            reverse_finance_admin_group,
        ),
    ]

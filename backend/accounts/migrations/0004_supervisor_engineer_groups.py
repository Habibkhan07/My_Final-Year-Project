"""Create the ``supervisor`` and ``engineer`` admin groups + grant perms.

The third group, ``finance_admin``, was created earlier by
``disputes/migrations/0002_finance_admin_group`` and extended by
``wallet/migrations/0003_finance_admin_perms``. This migration completes
the role architecture documented in ``core/common/admin_permissions.py``:

* **supervisor** — sees Bookings + Catalog + Customers + Marketing +
  Technicians + Reviews + SupportTickets (no IBANs, no money flow).
  Can edit catalog/promotions; everything else flows through named
  admin actions (Approve/Reject/Resolve/etc.).
* **engineer** — view-only access to forensic surfaces (OTPRecord,
  EventLog, FCMDevice, Conversation transcripts, DailyLlmCallQuota,
  TemporaryMedia). For demo-day-eve debugging without handing out
  superuser.

Idempotent: ``get_or_create`` on the group; ``add`` on permissions
silently no-ops on duplicates. Reverse migration removes the two
groups (matches the disputes 0002 pattern).
"""
from __future__ import annotations

from django.db import migrations


SUPERVISOR_GROUP = "supervisor"
ENGINEER_GROUP = "engineer"

# Supervisor — the default operational role. View widely, change
# selectively. Add/delete only on truly admin-owned content (catalog,
# marketing).
SUPERVISOR_PERMS = [
    # (app_label, model, codename)
    ("accounts", "userprofile", "view_userprofile"),

    ("bookings", "jobbooking", "view_jobbooking"),
    ("bookings", "jobbooking", "change_jobbooking"),
    ("bookings", "quote", "view_quote"),
    ("bookings", "bookingitem", "view_bookingitem"),
    ("bookings", "supportticket", "view_supportticket"),
    ("bookings", "supportticket", "change_supportticket"),
    ("bookings", "techreliabilityincident", "view_techreliabilityincident"),

    ("catalog", "service", "view_service"),
    ("catalog", "service", "change_service"),
    ("catalog", "service", "add_service"),
    ("catalog", "service", "delete_service"),
    ("catalog", "subservice", "view_subservice"),
    ("catalog", "subservice", "change_subservice"),
    ("catalog", "subservice", "add_subservice"),
    ("catalog", "subservice", "delete_subservice"),

    ("customers", "customerprofile", "view_customerprofile"),
    ("customers", "customeraddress", "view_customeraddress"),
    ("customers", "customeraddress", "change_customeraddress"),

    ("marketing", "promotion", "view_promotion"),
    ("marketing", "promotion", "change_promotion"),
    ("marketing", "promotion", "add_promotion"),
    ("marketing", "promotion", "delete_promotion"),

    ("technicians", "technicianprofile", "view_technicianprofile"),
    ("technicians", "technicianprofile", "change_technicianprofile"),
    ("technicians", "review", "view_review"),
    ("technicians", "review", "delete_review"),
]

# Engineer — read-only access to the forensic surfaces. NO change/add/
# delete. The data is debug breadcrumbs; mutating it desyncs invariants.
ENGINEER_PERMS = [
    ("accounts", "otprecord", "view_otprecord"),
    ("chatbot", "conversation", "view_conversation"),
    ("chatbot", "dailyllmcallquota", "view_dailyllmcallquota"),
    ("realtime", "fcmdevice", "view_fcmdevice"),
    ("realtime", "eventlog", "view_eventlog"),
    ("technicians", "temporarymedia", "view_temporarymedia"),
    # Engineers also benefit from supervisor-level read access for
    # cross-referencing — but rather than duplicate, demo-day staff
    # who need both can be in both groups.
]


def _grant(apps, group_name: str, perms_list: list[tuple[str, str, str]]):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    group, _ = Group.objects.get_or_create(name=group_name)

    for app_label, model, codename in perms_list:
        try:
            ct = ContentType.objects.get(app_label=app_label, model=model)
            perm = Permission.objects.get(content_type=ct, codename=codename)
        except (ContentType.DoesNotExist, Permission.DoesNotExist):
            # A migration ran out of order; group ends up missing one
            # perm, visible in admin and trivially fixed by re-running.
            continue
        group.permissions.add(perm)


def create_groups(apps, schema_editor):
    _grant(apps, SUPERVISOR_GROUP, SUPERVISOR_PERMS)
    _grant(apps, ENGINEER_GROUP, ENGINEER_PERMS)


def delete_groups(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Group.objects.filter(name__in=[SUPERVISOR_GROUP, ENGINEER_GROUP]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0003_remove_savedaddress_user_delete_customerprofile_and_more"),
        ("auth", "0012_alter_user_first_name_max_length"),
        ("contenttypes", "0002_remove_content_type_name"),
        # Ensure every model whose perms we grant has its content types
        # registered before this runs. Pin to the latest known migration
        # of each contributing app so a future model change runs first.
        ("bookings", "0011_jobbooking_customer_acknowledged_arrival_at"),
        ("catalog", "0008_alter_service_base_inspection_fee_and_more"),
        ("customers", "0004_customeraddress_city_customeraddress_country_and_more"),
        ("marketing", "0002_remove_promotion_target_subservice_and_more"),
        ("technicians", "0010_technicianprofile_work_address_label"),
        ("chatbot", "0001_initial"),
        ("realtime", "0002_eventlog_expires_at"),
    ]

    operations = [
        migrations.RunPython(create_groups, delete_groups),
    ]

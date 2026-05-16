"""Centralised role checks for the admin.

The admin has three operational personas (plus superuser as the
break-glass). Keeping the predicates here means every ``has_*_permission``
override in every ``admin.py`` consults a single source of truth — adding
a fourth role or renaming a group only requires editing this file.

Roles:

* **supervisor** — operational lead: sees Bookings, SupportTicket,
  Catalog, Promotions, Technicians, Customers. No money, no PII, no
  forensic surfaces.
* **finance_admin** — supervisor view plus the wallet ledger, payout
  accounts, withdrawal queue, RefundIntent IBANs, and the unredacted
  chat_log. Read-most-only; writes happen through named actions.
* **engineer** — supervisor view plus forensic surfaces (EventLog,
  FCMDevice, OTPRecord, full Conversation transcripts, DailyLlmCallQuota,
  TemporaryMedia). Read-only; for incident triage and on-call debugging.
* **superuser** — bypasses every check. Reserved for one or two people.

Each helper returns True for superusers (so the break-glass path always
works) and short-circuits on inactive / non-staff users.
"""
from __future__ import annotations


SUPERVISOR_GROUP = "supervisor"
FINANCE_ADMIN_GROUP = "finance_admin"
ENGINEER_GROUP = "engineer"


def _has_group(user, name: str) -> bool:
    """True if the active staff user belongs to ``name``.

    Superusers also pass — they bypass group membership checks so the
    admin always remains operable for the break-glass user.
    """
    if not user.is_active or not user.is_staff:
        return False
    if user.is_superuser:
        return True
    return user.groups.filter(name=name).exists()


def is_supervisor(user) -> bool:
    return _has_group(user, SUPERVISOR_GROUP)


def is_finance_admin(user) -> bool:
    return _has_group(user, FINANCE_ADMIN_GROUP)


def is_engineer(user) -> bool:
    return _has_group(user, ENGINEER_GROUP)


def is_engineer_or_superuser(user) -> bool:
    """Forensic-surface gate.

    Used by admins that expose user-typed PII, raw payloads, push-token
    secrets, or other debug-only data. Engineer group OR superuser; no
    fallthrough for plain staff.
    """
    if not user.is_active or not user.is_staff:
        return False
    if user.is_superuser:
        return True
    return user.groups.filter(name=ENGINEER_GROUP).exists()


def is_finance_admin_or_superuser(user) -> bool:
    """Compat alias for the existing ``_is_finance_admin`` semantics.

    The helper in ``disputes/admin.py`` and ``wallet/admin.py`` already
    treats superusers as members of the group. Same here so callers
    can drop the duplicate definitions without behavioural drift.
    """
    return is_finance_admin(user)


class EngineerOnlyAdminMixin:
    """Hide a ModelAdmin from the sidebar unless caller is engineer/superuser.

    Apply by adding to the bases of a ``ModelAdmin``. The two
    permission overrides below are the ONLY thing needed for sidebar
    hiding plus 403 on direct URL access — Django's permission machinery
    chains: ``has_module_permission`` controls index visibility,
    ``has_view_permission`` gates detail/list pages.
    """

    def has_module_permission(self, request):
        return is_engineer_or_superuser(request.user)

    def has_view_permission(self, request, obj=None):
        return is_engineer_or_superuser(request.user)

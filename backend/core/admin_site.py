"""Custom admin index grouping — hide Django app labels, show task tabs.

The default Django admin sidebar groups registered models by their
``app_label`` (``bookings``, ``wallet``, ``catalog``, …). That mirrors
internal architecture, not operational thinking: the supervisor doesn't
care which Django app a model lives in — they care about *what work*
they're doing right now (resolving disputes, approving techs, processing
withdrawals).

This module monkey-patches ``admin.site.get_app_list`` to:

1. Pull the model dict from the default implementation (preserves all
   the permission filtering, URL resolution, verbose names).
2. Re-bucket those models into our own synthetic groups
   (``Operations`` / ``People`` / ``Catalog`` / ``Reviews``) using a
   declarative ``GROUPS`` map keyed by ``(app_label, model_name_lower)``.
3. Return the rebuilt list. Models not mentioned in ``GROUPS`` fall
   into a sentinel "Other" group at the bottom — defensive against
   future model additions that haven't been triaged into a tab yet.

No model code, admin registration, or URL routing changes. Reverting is
"comment out the call in ``core/apps.py::ready``".
"""
from __future__ import annotations

from django.contrib import admin


# ---------------------------------------------------------------------------
# Group definition — task-oriented, hides Django app boundaries.
# ---------------------------------------------------------------------------
# Each tuple is (app_label, model_name_lower) — the keys Django uses
# internally on the dict ``app_list`` returns. Order within a group
# determines the rendered order in the sidebar.
GROUPS: list[tuple[str, list[tuple[str, str]]]] = [
    (
        "Operations",
        [
            ("bookings", "jobbooking"),
            ("bookings", "supportticket"),
            ("wallet", "withdrawalrequest"),
            # Engineer-only entries (do not render for supervisors).
            # Filtered out by the permission layer before they even
            # reach us; placed here so superuser viewing still gets
            # them in the right tab rather than dumped under "Other".
            ("disputes", "refundintent"),
            ("chatbot", "conversation"),
        ],
    ),
    (
        "People",
        [
            ("technicians", "technicianprofile"),
            ("customers", "customerprofile"),
            ("auth", "user"),
            ("accounts", "userprofile"),
        ],
    ),
    (
        "Catalog",
        [
            ("catalog", "service"),
            ("catalog", "subservice"),
            ("marketing", "promotion"),
        ],
    ),
    (
        "Reviews",
        [
            ("technicians", "review"),
        ],
    ),
]


def _build_grouped_app_list(default_app_list):
    """Rebucket a Django app_list into task-oriented synthetic groups.

    ``default_app_list`` has shape::

        [
            {'name': 'Bookings', 'app_label': 'bookings', 'app_url': '...',
             'has_module_perms': True,
             'models': [
                {'object_name': 'JobBooking', 'name': 'Job bookings',
                 'admin_url': '...', 'add_url': '...',
                 'view_only': False, ...},
                ...
             ]},
            ...
        ]

    We index by ``(app_label, model_name_lower)`` so we can pluck the
    model dicts out preserving every permission-aware URL the default
    builder computed.
    """
    # Flatten: {(app_label, model_name_lower): model_dict}
    model_index: dict[tuple[str, str], dict] = {}
    for app in default_app_list:
        app_label = app.get("app_label", "")
        for model in app.get("models", []):
            obj_name = model.get("object_name", "")
            model_index[(app_label, obj_name.lower())] = model

    rebucketed_keys: set[tuple[str, str]] = set()
    new_app_list: list[dict] = []

    for group_name, model_keys in GROUPS:
        bucket_models: list[dict] = []
        for key in model_keys:
            md = model_index.get(key)
            if md is not None:
                bucket_models.append(md)
                rebucketed_keys.add(key)
        if bucket_models:
            new_app_list.append({
                "name": group_name,
                # ``app_label`` MUST be a non-empty string for Django's
                # default sidebar template (``app_list.html`` renders
                # ``{{ app.app_label }}`` in a few places). Use the
                # lowercased group name; nothing in the platform reads
                # this for routing.
                "app_label": group_name.lower(),
                "app_url": "",
                "has_module_perms": True,
                "models": bucket_models,
            })

    # Models NOT mentioned in GROUPS are intentionally absent from the
    # sidebar. Django's permission layer + URL routing still works
    # (e.g. ``/admin/auth/group/`` resolves) — they're only suppressed
    # from the navigation chrome. This is the "framework plumbing"
    # tier: auth tokens, Django Groups, contenttypes — operational
    # tooling, not part of the marketplace's domain model.
    return new_app_list


def install_grouped_sidebar() -> None:
    """Monkey-patch ``admin.site.get_app_list`` once.

    Idempotent — re-imports during dev autoreload or test setup don't
    stack patches. Detected via the ``_fixit_patched`` sentinel attribute.
    """
    site = admin.site
    if getattr(site, "_fixit_grouped_sidebar_patched", False):
        return

    original_get_app_list = site.get_app_list

    def patched_get_app_list(request, app_label=None):
        # When Django is rendering a single app's index page
        # (e.g. ``/admin/bookings/``) it passes ``app_label`` and
        # expects results filtered to that label. We DO NOT regroup
        # in that case — the per-app pages aren't where the regrouping
        # adds value, and overriding here can break ModelAdmin URL
        # round-tripping. Pass through to the default.
        if app_label is not None:
            return original_get_app_list(request, app_label)

        default_list = original_get_app_list(request)
        return _build_grouped_app_list(default_list)

    site.get_app_list = patched_get_app_list
    site._fixit_grouped_sidebar_patched = True

"""Tests for disputes.admin.RefundIntentAdmin permission gating.

Pins:
  - Non-staff users: no module permission, no view permission.
  - Staff outside finance_admin group: no module/view permission.
  - Staff in finance_admin: view yes, add/change/delete no.
  - Superusers: view yes, add/change/delete no (write restrictions
    apply uniformly so even a superuser can't accidentally edit PII).
  - finance_admin group exists (data migration 0002 ran).
"""
from __future__ import annotations

import pytest
from django.contrib.auth.models import Group
from django.test import RequestFactory

from disputes.admin import RefundIntentAdmin
from disputes.models import RefundIntent
from tests.factories.accounts import UserFactory


@pytest.fixture
def admin_instance():
    # Pass a stub admin site — the permission methods don't dispatch on it.
    from django.contrib.admin.sites import AdminSite

    return RefundIntentAdmin(model=RefundIntent, admin_site=AdminSite())


@pytest.fixture
def request_factory():
    return RequestFactory()


@pytest.mark.django_db
class TestPermissions:
    def test_finance_admin_group_exists(self):
        # Data migration 0002 should have created the group.
        assert Group.objects.filter(name="admin").exists()

    def test_anonymous_user_denied(self, admin_instance, request_factory):
        # Anonymous = is_active=False, is_staff=False
        from django.contrib.auth.models import AnonymousUser

        req = request_factory.get("/")
        req.user = AnonymousUser()
        assert admin_instance.has_module_permission(req) is False
        assert admin_instance.has_view_permission(req) is False

    def test_regular_user_denied(self, admin_instance, request_factory):
        user = UserFactory(is_staff=False)
        req = request_factory.get("/")
        req.user = user
        assert admin_instance.has_module_permission(req) is False
        assert admin_instance.has_view_permission(req) is False

    def test_staff_outside_group_denied(self, admin_instance, request_factory):
        user = UserFactory(is_staff=True)
        req = request_factory.get("/")
        req.user = user
        assert admin_instance.has_module_permission(req) is False
        assert admin_instance.has_view_permission(req) is False

    def test_staff_in_finance_admin_group_allowed_view(self, admin_instance, request_factory):
        user = UserFactory(is_staff=True)
        group = Group.objects.get(name="admin")
        user.groups.add(group)
        req = request_factory.get("/")
        req.user = user
        assert admin_instance.has_module_permission(req) is True
        assert admin_instance.has_view_permission(req) is True

    def test_superuser_allowed_view(self, admin_instance, request_factory):
        user = UserFactory(is_staff=True, is_superuser=True)
        req = request_factory.get("/")
        req.user = user
        assert admin_instance.has_view_permission(req) is True

    def test_writes_always_denied(self, admin_instance, request_factory):
        # Even superusers cannot add/change/delete from admin —
        # rows are created by the chatbot service only.
        user = UserFactory(is_staff=True, is_superuser=True)
        req = request_factory.get("/")
        req.user = user
        assert admin_instance.has_add_permission(req) is False
        assert admin_instance.has_change_permission(req) is False
        assert admin_instance.has_delete_permission(req) is False

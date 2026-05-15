"""Tests for the technicians admin: approve / reject bulk actions and the
model-level ``REJECTED-requires-reason`` invariant.

These are pytest-style tests hitting the admin via the standard Django test
client. ``force_login`` on a staff superuser bypasses login but exercises the
real admin URL routing + action handlers.
"""
import pytest
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.test import Client
from django.urls import reverse

from technicians.models import TechnicianProfile
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db

User = get_user_model()


@pytest.fixture
def admin_client():
    staff = User.objects.create_superuser(
        username='+923000000000', password='admin', email='admin@example.com'
    )
    client = Client()
    client.force_login(staff)
    return client


CHANGELIST_URL = reverse('admin:technicians_technicianprofile_changelist')


class TestApproveSelectedAction:
    def test_approve_flips_status_and_clears_reason(self, admin_client):
        pending = TechnicianProfileFactory(status='PENDING')
        rejected = TechnicianProfileFactory(
            status='REJECTED',
            rejection_reason='old reason',
        )

        response = admin_client.post(
            CHANGELIST_URL,
            data={
                'action': 'approve_selected',
                '_selected_action': [pending.pk, rejected.pk],
                'index': '0',
            },
            follow=True,
        )

        assert response.status_code == 200
        pending.refresh_from_db()
        rejected.refresh_from_db()
        assert pending.status == 'APPROVED'
        assert pending.rejection_reason == ''
        assert rejected.status == 'APPROVED'
        # Approving a previously-rejected row also wipes the stale reason,
        # so the holding-screen contract (`reason only when REJECTED`) stays
        # honest if admin later flips them back.
        assert rejected.rejection_reason == ''


class TestRejectSelectedAction:
    def test_reject_renders_intermediate_page(self, admin_client):
        pending = TechnicianProfileFactory(status='PENDING')

        response = admin_client.post(
            CHANGELIST_URL,
            data={
                'action': 'reject_selected',
                '_selected_action': [pending.pk],
                'index': '0',
            },
        )

        assert response.status_code == 200
        assert b'Reject selected technicians' in response.content
        assert b'rejection_reason' in response.content
        # Row not yet mutated — phase 1 is render-only.
        pending.refresh_from_db()
        assert pending.status == 'PENDING'

    def test_reject_apply_persists_reason(self, admin_client):
        pending = TechnicianProfileFactory(status='PENDING')

        response = admin_client.post(
            CHANGELIST_URL,
            data={
                'action': 'reject_selected',
                '_selected_action': [pending.pk],
                'index': '0',
                'apply': '1',
                'rejection_reason': 'CNIC image was illegible — please reupload.',
            },
            follow=True,
        )

        assert response.status_code == 200
        pending.refresh_from_db()
        assert pending.status == 'REJECTED'
        assert pending.rejection_reason == 'CNIC image was illegible — please reupload.'

    def test_reject_apply_with_blank_reason_is_refused(self, admin_client):
        """Form layer refuses a blank reason — row stays PENDING."""
        pending = TechnicianProfileFactory(status='PENDING')

        response = admin_client.post(
            CHANGELIST_URL,
            data={
                'action': 'reject_selected',
                '_selected_action': [pending.pk],
                'index': '0',
                'apply': '1',
                'rejection_reason': '',
            },
        )

        # Form re-renders with the field error; no mutation.
        assert response.status_code == 200
        pending.refresh_from_db()
        assert pending.status == 'PENDING'
        assert pending.rejection_reason == ''


class TestModelInvariant:
    """Tests for the ``clean()`` rule: REJECTED requires a non-empty reason.

    We invoke ``clean()`` directly rather than ``full_clean()`` to isolate the
    invariant under test from unrelated field-level validators (image fields,
    CNIC format, etc.) that the factory does not populate. The admin's
    ``save_model`` calls ``full_clean`` against a fully-populated form, so
    the production path is well-covered by the action tests above.
    """

    def test_rejected_with_blank_reason_fails_clean(self):
        profile = TechnicianProfileFactory(status='APPROVED', rejection_reason='')
        profile.status = 'REJECTED'

        with pytest.raises(ValidationError) as exc_info:
            profile.clean()

        assert 'rejection_reason' in exc_info.value.error_dict

    def test_rejected_with_whitespace_only_reason_fails_clean(self):
        """Whitespace is not a reason. ``"   "`` would render as an empty
        block on the tech's holding screen — refuse it at the model layer.
        """
        profile = TechnicianProfileFactory(
            status='REJECTED', rejection_reason='   \n\t  '
        )

        with pytest.raises(ValidationError):
            profile.clean()

    def test_rejected_with_reason_passes_clean(self):
        profile = TechnicianProfileFactory(
            status='REJECTED', rejection_reason='Photo unclear'
        )
        profile.clean()  # no exception

    def test_approved_with_blank_reason_passes_clean(self):
        """The rule only fires on REJECTED. APPROVED + blank is the norm."""
        profile = TechnicianProfileFactory(status='APPROVED', rejection_reason='')
        profile.clean()  # no exception

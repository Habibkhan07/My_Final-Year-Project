import pytest
from technicians.selectors.tech_status_selector import get_my_tech_status
from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db


class TestGetMyTechStatus:
    def test_returns_no_profile_for_pure_customer(self, django_assert_num_queries):
        """User who never applied: has_profile=False, all status fields null."""
        user = UserFactory()

        with django_assert_num_queries(1):
            result = get_my_tech_status(user=user)

        assert result == {
            "has_profile": False,
            "status": None,
            "status_display": None,
            "rejection_reason": None,
            "submitted_at": None,
        }

    def test_returns_pending_for_freshly_applied_tech(self, django_assert_num_queries):
        tech = TechnicianProfileFactory(status='PENDING')

        with django_assert_num_queries(1):
            result = get_my_tech_status(user=tech.user)

        assert result["has_profile"] is True
        assert result["status"] == 'PENDING'
        assert result["status_display"] == 'Pending Approval'
        assert result["rejection_reason"] is None

    def test_returns_approved_for_approved_tech(self, django_assert_num_queries):
        tech = TechnicianProfileFactory(status='APPROVED')

        with django_assert_num_queries(1):
            result = get_my_tech_status(user=tech.user)

        assert result["status"] == 'APPROVED'
        assert result["status_display"] == 'Approved'
        assert result["rejection_reason"] is None

    def test_returns_rejected_with_reason(self, django_assert_num_queries):
        tech = TechnicianProfileFactory(
            status='REJECTED',
            rejection_reason='CNIC image was illegible — please reupload.',
        )

        with django_assert_num_queries(1):
            result = get_my_tech_status(user=tech.user)

        assert result["status"] == 'REJECTED'
        assert result["rejection_reason"] == 'CNIC image was illegible — please reupload.'

    def test_rejected_with_blank_reason_is_blocked_at_db_level(self):
        """REJECTED + empty reason is forbidden by the
        ``technicianprofile_rejected_requires_reason`` CheckConstraint —
        the row simply cannot exist. This test pins that contract so the
        selector's "empty string maps to null on the wire" branch can be
        removed (dead code under the new constraint).
        """
        from django.db.utils import IntegrityError

        with pytest.raises(IntegrityError):
            TechnicianProfileFactory(status='REJECTED', rejection_reason='')

    def test_reason_suppressed_for_non_rejected_status(self):
        """Reason on a PENDING profile (stale admin write) must not leak to the wire."""
        tech = TechnicianProfileFactory(
            status='PENDING',
            rejection_reason='stale reason from a previous rejection',
        )
        result = get_my_tech_status(user=tech.user)
        assert result["rejection_reason"] is None

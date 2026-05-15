"""Tests for technicians.services.registration_service.finalize_registration.

Focused on the re-application path: a REJECTED tech submitting again must
reset their existing row in place, while a PENDING or APPROVED tech must
be blocked. The happy-path (no existing profile) is covered by the API-level
test in ``tests/technicians/test_onboarding.py`` — this file owns the branches
that test couldn't exercise from the HTTP layer cleanly.
"""
import io

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image

from technicians.exceptions import DuplicateActiveApplicationError
from technicians.models import TechnicianProfile, TechnicianSkill
from technicians.services.registration_service import finalize_registration
from tests.factories.accounts import UserFactory, UserProfileFactory
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.technicians import TechnicianProfileFactory, TechnicianSkillFactory

pytestmark = pytest.mark.django_db


def _image_file(name='img.jpg'):
    buf = io.BytesIO()
    Image.new('RGB', (10, 10), color='white').save(buf, format='JPEG')
    buf.seek(0)
    return SimpleUploadedFile(name=name, content=buf.read(), content_type='image/jpeg')


def _valid_payload(*, sub_service, first='Re', last='Applied', city='LHR',
                   cnic='12345-1234567-1', labor_rate=3000.00):
    """Validated-data dict matching what the serializer hands to the service."""
    return {
        'first_name': first,
        'last_name': last,
        'city': city,
        'cnic_number': cnic,
        'experience_years': 4,
        'bio': 'Updated bio after rejection.',
        'profile_picture_file': _image_file('profile.jpg'),
        'cnic_picture_file': _image_file('cnic.jpg'),
        'category_licenses': [],
        'skills': [
            {
                'sub_service_id': sub_service.id,
                'years_of_experience': 2,
                'labor_rate': labor_rate,
            }
        ],
    }


class TestReapplicationFlow:
    def setup_method(self):
        self.service = ServiceFactory(name='Plumbing')
        self.sub_service = SubServiceFactory(service=self.service, name='Tap Repair')
        self.other_sub_service = SubServiceFactory(service=self.service, name='Drain')

    def test_rejected_tech_can_reapply_resets_profile_in_place(self):
        """REJECTED → PENDING, reason cleared, row identity preserved."""
        user = UserFactory()
        UserProfileFactory(user=user)
        rejected_profile = TechnicianProfileFactory(
            user=user,
            status='REJECTED',
            rejection_reason='CNIC illegible',
            cnic_number='99999-9999999-9',
            bio='Old bio',
        )
        TechnicianSkillFactory(
            technician=rejected_profile,
            sub_service=self.other_sub_service,
            labor_rate=1000.00,
        )
        original_id = rejected_profile.id

        result = finalize_registration(
            user=user,
            validated_data=_valid_payload(sub_service=self.sub_service),
        )

        # Same row — OneToOne preserved, no orphan.
        assert result.id == original_id
        assert TechnicianProfile.objects.filter(user=user).count() == 1

        # Status reset, reason cleared.
        assert result.status == 'PENDING'
        assert result.rejection_reason == ''

        # New submission's fields replaced the old ones.
        assert result.bio == 'Updated bio after rejection.'
        assert result.cnic_number == '12345-1234567-1'

        # Old skills wiped; new skill in place.
        skills = list(TechnicianSkill.objects.filter(technician=result))
        assert len(skills) == 1
        assert skills[0].sub_service_id == self.sub_service.id

    def test_rejected_reapply_flips_is_technician(self):
        """is_technician was already True from the first apply, but the flag
        must remain True after reset — a stray ``False`` would lock the router
        out of the tech surface even after a future approval.
        """
        user = UserFactory()
        UserProfileFactory(user=user, is_technician=True)
        TechnicianProfileFactory(user=user, status='REJECTED', rejection_reason='X')

        finalize_registration(
            user=user,
            validated_data=_valid_payload(sub_service=self.sub_service),
        )

        user.userprofile.refresh_from_db()
        assert user.userprofile.is_technician is True

    def test_pending_tech_cannot_reapply(self):
        """PENDING → 409. A second submit would race the admin review."""
        user = UserFactory()
        UserProfileFactory(user=user)
        TechnicianProfileFactory(user=user, status='PENDING')

        with pytest.raises(DuplicateActiveApplicationError) as exc_info:
            finalize_registration(
                user=user,
                validated_data=_valid_payload(sub_service=self.sub_service),
            )

        assert exc_info.value.status_code == 409
        assert exc_info.value.code == 'duplicate_application'
        assert exc_info.value.errors['application_status'] == ['PENDING']

    def test_approved_tech_cannot_reapply(self):
        """APPROVED → 409. Re-application has no defined product meaning."""
        user = UserFactory()
        UserProfileFactory(user=user)
        TechnicianProfileFactory(user=user, status='APPROVED')

        with pytest.raises(DuplicateActiveApplicationError) as exc_info:
            finalize_registration(
                user=user,
                validated_data=_valid_payload(sub_service=self.sub_service),
            )

        assert exc_info.value.errors['application_status'] == ['APPROVED']

    def test_duplicate_application_returns_canonical_envelope_via_api(self, client):
        """End-to-end: the custom exception handler maps the error class to
        the project's ``{status, code, message, errors}`` envelope. Without
        this wiring, DRF would default to a generic ``"validation_error"``
        and the Flutter mapper would mis-route to the wrong sealed failure.
        """
        from django.urls import reverse
        from rest_framework.test import APIClient

        from technicians.models import TemporaryMedia

        user = UserFactory()
        UserProfileFactory(user=user)
        TechnicianProfileFactory(user=user, status='PENDING')

        api_client = APIClient()
        api_client.force_authenticate(user=user)

        # Stage media so the serializer's UUID -> File lookup succeeds before
        # the service-layer duplicate check fires.
        profile_media = TemporaryMedia.objects.create(file=_image_file())
        cnic_media = TemporaryMedia.objects.create(file=_image_file())

        response = api_client.post(
            reverse('tech-register'),
            {
                'first_name': 'A',
                'last_name': 'B',
                'city': 'LHR',
                'cnic_number': '12345-1234567-1',
                'experience_years': 1,
                'bio': '...',
                'profile_picture_uuid': str(profile_media.id),
                'cnic_picture_uuid': str(cnic_media.id),
                'skills': [
                    {
                        'sub_service_id': self.sub_service.id,
                        'years_of_experience': 1,
                        'labor_rate': 1500.00,
                    }
                ],
            },
            format='json',
        )

        assert response.status_code == 409
        body = response.json()
        assert body['code'] == 'duplicate_application'
        assert body['status'] == 409
        assert 'message' in body and body['message']

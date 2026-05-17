import uuid
import io
from django.urls import reverse
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from PIL import Image

# Absolute imports targeting the new structure
from technicians.models import TemporaryMedia, TechnicianProfile, SubService, Service
from accounts.models import UserProfile

User = get_user_model()

class TechnicianOnboardingTests(APITestCase):

    def setUp(self):
        """Sets up the environment matching the refined structure."""
        self.user = User.objects.create_user(username='tech_tester', password='password123')
        # Production path always creates a UserProfile alongside the User
        # via process_otp_verification. Mirror that here so finalize can
        # flip is_technician on the existing row instead of crashing.
        UserProfile.objects.create(user=self.user, phone='+923000000000')
        self.client.force_authenticate(user=self.user)
        
        # Domain data for Metadata and Skill tests
        self.service = Service.objects.create(name="AC Service")
        self.sub_service = SubService.objects.create(
            service=self.service, 
            name="Gas Refill", 
            base_price=2500.00,
            max_price=3000.00
        )
        
        # Generate a real valid image for Phase 1 tests
        file_obj = io.BytesIO()
        Image.new('RGB', (10, 10), color='white').save(file_obj, format='JPEG')
        file_obj.seek(0)
        self.dummy_image = SimpleUploadedFile(
            name='test.jpg',
            content=file_obj.read(),
            content_type='image/jpeg'
        )

    # --- 1. NEW ENDPOINT: METADATA SELECTOR ---

    def test_get_onboarding_metadata(self):
        """Verifies Flutter can fetch the service tree with pricing guardrails."""
        url = reverse('onboarding-metadata') 
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Verify structure: List of Services -> List of SubServices
        self.assertEqual(len(response.data), 1)
        sub_service_data = response.data[0]['sub_services'][0]
        self.assertEqual(sub_service_data['name'], "Gas Refill")
        self.assertEqual(sub_service_data['base_price'], "2500.00")
        self.assertEqual(sub_service_data['max_price'], "3000.00")

    # --- 2. PHASE 1: MEDIA STAGING (Service Layer) ---

    def test_media_staging_flow(self):
        """Tests robust Phase 1: UUID generation and storage."""
        url = reverse('media-upload')
        response = self.client.post(url, {'file': self.dummy_image}, format='multipart')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('uuid', response.data)
        self.assertTrue(TemporaryMedia.objects.filter(id=response.data['uuid']).exists())

    # --- 3. PHASE 2: ATOMIC REGISTRATION (Service Layer) ---

    def test_full_registration_contract(self):
        """Happy-path finalize after the 2026-05-17 onboarding refactor.

        Payload no longer carries ``experience_years``, ``bio``,
        ``years_of_experience``, or ``labor_rate`` — the wizard's
        Professional ID and Skill Pricing steps were dropped.
        """
        profile_media = TemporaryMedia.objects.create(file=self.dummy_image)
        cnic_media = TemporaryMedia.objects.create(file=self.dummy_image)

        url = reverse('tech-register')
        payload = {
            "first_name": "Hamayon",
            "last_name": "Khan",
            "city": "LHR",
            "cnic_number": "12345-1234567-1",
            "profile_picture_uuid": str(profile_media.id),
            "cnic_picture_uuid": str(cnic_media.id),
            "skills": [
                {"sub_service_id": self.sub_service.id},
            ],
        }

        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        profile = TechnicianProfile.objects.get(user=self.user)
        skill = profile.technicianskill_set.first()
        self.assertEqual(skill.sub_service_id, self.sub_service.id)

        # Regression: finalize_registration must flip the UserProfile
        # `is_technician` flag. Without this, verify-otp keeps returning
        # is_technician=False for real techs and the router can never
        # route them to the tech surface.
        self.user.userprofile.refresh_from_db()
        self.assertTrue(self.user.userprofile.is_technician)

    # --- 4. EDGE CASES & SECURITY ---

    def test_invalid_uuid_rejection(self):
        """Security: Rejects if UUID doesn't exist in staging table."""
        url = reverse('tech-register')
        fake_uuid = str(uuid.uuid4())
        payload = {
            "first_name": "Invalid", "last_name": "UUID", "city": "KHI",
            "cnic_number": "12345-1234567-1",
            "profile_picture_uuid": fake_uuid, "cnic_picture_uuid": fake_uuid,
            "skills": [
                {"sub_service_id": self.sub_service.id},
            ],
        }
        response = self.client.post(url, payload, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.data['code'], 'not_found')

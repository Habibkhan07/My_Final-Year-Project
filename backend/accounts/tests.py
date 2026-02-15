from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from django.urls import reverse

# New Imports: Directed at the domain and presentation layers
from .services import auth_service, profile_service
from .selectors import user_selectors
from .models import UserProfile, CustomerProfile
from .api.auth.serializers import PhoneLoginInputSerializer, OTPVerifyInputSerializer

class AccountsRefinedTests(TestCase):
    def setUp(self):
        """Sets up the testing environment for each test execution."""
        self.client = APIClient()
        self.phone = "+923001234567"
        # Pre-creating a user for verification tests
        self.user = User.objects.create(username=self.phone)
        UserProfile.objects.create(user=self.user, phone=self.phone)

    # --- 1. UNIT TESTS: VALIDATION MATRIX ---

    def test_login_serializer_validation_matrix(self):
        """Tests PhoneLoginInputSerializer with 10+ phone variations."""
        test_cases = [
            {"phone": "+923001111111", "valid": True},
            {"phone": "03001234567", "valid": True},
            {"phone": "invalid-chars!", "valid": False},
            {"phone": "123", "valid": False},
            {"phone": "+1234567890123456", "valid": False},
            {"phone": " ", "valid": False},
            {"phone": "923009999999", "valid": True},
            {"phone": "+14155552671", "valid": True},
            {"phone": "ABCDEFGHIJKL", "valid": False},
            {"phone": "0000000000", "valid": True},
        ]

        for case in test_cases:
            serializer = PhoneLoginInputSerializer(data={"phone": case["phone"]})
            if case["valid"]:
                self.assertTrue(serializer.is_valid(), f"Failed on valid phone: {case['phone']}")
            else:
                self.assertFalse(serializer.is_valid(), f"Failed to catch invalid phone: {case['phone']}")

    def test_auth_service_otp_matrix(self):
        """Tests process_otp_verification with various OTP inputs."""
        otp_cases = [
            {"otp": "1234", "success": True},
            {"otp": "0000", "success": False},
            {"otp": "abcd", "success": False},
            {"otp": "123", "success": False},
            {"otp": "", "success": False},
            {"otp": " 1234", "success": False},
        ]

        for case in otp_cases:
            if case["success"]:
                result = auth_service.process_otp_verification(phone=self.phone, otp_input=case["otp"])
                self.assertIsNotNone(result)
                self.assertIn("token", result) #
            else:
                # NEW: Catching the ValueError instead of checking a tuple
                with self.assertRaises(ValueError):
                    auth_service.process_otp_verification(phone=self.phone, otp_input=case["otp"])

    def test_profile_service_name_matrix(self):
        """Tests profile_service with various name inputs."""
        name_cases = [
            {"f": "John", "l": "Doe", "valid": True},
            {"f": "", "l": "Doe", "valid": False},
            {"f": "John", "l": "", "valid": False},
            {"f": "🚀", "l": "Tech", "valid": True},
            {"f": "A" * 100, "l": "Name", "valid": True},
        ]

        for case in name_cases:
            success, msg = profile_service.update_user_profile(
                user=self.user, 
                first_name=case["f"], 
                last_name=case["l"]
            )
            if case["valid"]:
                self.assertTrue(success) #
                self.user.refresh_from_db()
                self.assertEqual(self.user.first_name, case["f"])
            else:
                self.assertFalse(success) #

    # --- 2. INTEGRATION TESTS: FLUTTER CONTRACT ---

    def test_full_auth_flow(self):
        """Verifies the integration from View to Service to DB."""
        
        # 1. Test Login View
        login_url = reverse('phone-login') 
        login_res = self.client.post(login_url, {'phone': '+923334445555'}, format='json')
        self.assertEqual(login_res.status_code, status.HTTP_200_OK) #

        # 2. Test Verify View
        verify_url = reverse('verify-otp')
        verify_res = self.client.post(verify_url, {
            'phone': '+923334445555', 
            'otp': '1234'
        }, format='json')
        
        self.assertEqual(verify_res.status_code, status.HTTP_200_OK) #
        
        # --- VERIFY FLUTTER EXPECTATIONS ---
        # These keys must exist or Flutter will crash
        expected_keys = ["token", "is_technician", "name_required", "new_user"]
        for key in expected_keys:
            self.assertIn(key, verify_res.data, f"Missing critical Flutter key: {key}")
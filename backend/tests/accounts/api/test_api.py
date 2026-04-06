"""
Auth API contract tests.

Every test asserts the full error envelope shape so Flutter's error pipeline
never encounters a surprise field name or missing key.

Twilio is ALWAYS mocked — no SMS is sent, no credits are burned.
The mock target is the twilio_service function that the view's service calls,
not the Twilio SDK directly, so the mock is isolated to our code boundary.
"""
import pytest
from django.urls import reverse
from django.utils import timezone
from datetime import timedelta
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token

from accounts.models import OTPRecord
from tests.factories.accounts import UserFactory, UserProfileFactory, CustomerProfileFactory, OTPRecordFactory

TWILIO_MOCK = 'accounts.services.twilio_service.send_otp'


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def client():
    return APIClient()


@pytest.fixture
def login_url():
    return reverse('phone-login')


@pytest.fixture
def verify_url():
    return reverse('verify-otp')


@pytest.fixture
def signup_url():
    return reverse('complete-signup')


# ---------------------------------------------------------------------------
# 1. PhoneLoginView  POST /api/accounts/login-otp/
# ---------------------------------------------------------------------------

@pytest.mark.django_db
def test_login_valid_pk_phone_returns_200(client, login_url, mocker):
    mocker.patch(TWILIO_MOCK)
    response = client.post(login_url, {'phone': '03001234567'})
    assert response.status_code == 200
    assert response.data == {'message': 'OTP sent successfully'}


@pytest.mark.django_db
def test_login_e164_pk_phone_returns_200(client, login_url, mocker):
    """E.164 format should also be accepted and normalised."""
    mocker.patch(TWILIO_MOCK)
    response = client.post(login_url, {'phone': '+923001234567'})
    assert response.status_code == 200


@pytest.mark.django_db
def test_login_creates_otp_record(client, login_url, mocker):
    """A valid request must persist exactly one OTPRecord."""
    mocker.patch(TWILIO_MOCK)
    client.post(login_url, {'phone': '03001234567'})
    assert OTPRecord.objects.filter(phone='+923001234567').count() == 1


@pytest.mark.django_db
def test_login_invalid_phone_format_returns_400(client, login_url):
    """Non-PK numbers (e.g. Indian) must be rejected at the serializer."""
    response = client.post(login_url, {'phone': '+911234567890'})
    assert response.status_code == 400
    assert response.data['code'] == 'validation_error'
    assert 'phone' in response.data['errors']


@pytest.mark.django_db
def test_login_missing_phone_returns_400(client, login_url):
    response = client.post(login_url, {})
    assert response.status_code == 400
    assert 'phone' in response.data['errors']


@pytest.mark.django_db
def test_login_twilio_failure_returns_400_with_human_message(client, login_url, mocker):
    """
    When Twilio rejects the SMS, the error message must be human-readable
    in the `message` field (used for toasts), not buried in `errors`.
    Also verifies the OTPRecord is rolled back — no orphaned records.
    """
    mocker.patch(TWILIO_MOCK, side_effect=ValueError('Failed to send OTP via SMS: test error'))
    response = client.post(login_url, {'phone': '03001234567'})

    assert response.status_code == 400
    assert response.data['code'] == 'validation_error'
    # Toast message must contain the reason, not a generic fallback
    assert 'Failed to send OTP' in response.data['message']
    # OTPRecord must have been rolled back
    assert OTPRecord.objects.count() == 0


# ---------------------------------------------------------------------------
# 2. VerifyOTPView  POST /api/accounts/verify-otp/
# ---------------------------------------------------------------------------

@pytest.mark.django_db
def test_verify_new_user_returns_token_and_flags(client, verify_url):
    """First-time login: user is created, new_user=True, name_required=True."""
    OTPRecordFactory(phone='+923001234567', code='123456')
    response = client.post(verify_url, {'phone': '+923001234567', 'otp': '123456'})

    assert response.status_code == 200
    data = response.data
    assert 'token' in data
    assert data['new_user'] is True
    assert data['name_required'] is True
    assert data['is_technician'] is False


@pytest.mark.django_db
def test_verify_returning_user_new_user_false(client, verify_url):
    """Returning user with complete profile: new_user=False, name_required=False."""
    user = UserFactory(username='+923009999999', first_name='Ali', last_name='Raza')
    UserProfileFactory(user=user, phone='+923009999999')
    CustomerProfileFactory(user=user)
    OTPRecordFactory(phone='+923009999999', code='654321')

    response = client.post(verify_url, {'phone': '+923009999999', 'otp': '654321'})

    assert response.status_code == 200
    assert response.data['new_user'] is False
    assert response.data['name_required'] is False


@pytest.mark.django_db
def test_verify_otp_is_marked_used_after_success(client, verify_url):
    """Replay attack prevention: the OTPRecord must be marked is_used=True."""
    record = OTPRecordFactory(phone='+923001234567', code='123456')
    client.post(verify_url, {'phone': '+923001234567', 'otp': '123456'})

    record.refresh_from_db()
    assert record.is_used is True


@pytest.mark.django_db
def test_verify_wrong_otp_returns_400_with_field_error(client, verify_url):
    """Wrong code: message is human-readable, errors.otp has the field hint."""
    OTPRecordFactory(phone='+923001234567', code='111111')
    response = client.post(verify_url, {'phone': '+923001234567', 'otp': '999999'})

    assert response.status_code == 400
    assert response.data['code'] == 'validation_error'
    assert response.data['message'] == 'Invalid OTP.'
    assert response.data['errors']['otp'] == ['Invalid OTP.']


@pytest.mark.django_db
def test_verify_expired_otp_returns_400(client, verify_url):
    """Expired OTP: distinct message from wrong-code so Flutter can show 'resend'."""
    record = OTPRecordFactory(phone='+923001234567', code='123456')
    OTPRecord.objects.filter(pk=record.pk).update(
        expires_at=timezone.now() - timedelta(seconds=1)
    )

    response = client.post(verify_url, {'phone': '+923001234567', 'otp': '123456'})

    assert response.status_code == 400
    assert 'expired' in response.data['message'].lower()
    assert 'expired' in response.data['errors']['otp'][0].lower()


@pytest.mark.django_db
def test_verify_no_otp_record_returns_400(client, verify_url):
    """No OTPRecord for this phone: user never requested one."""
    response = client.post(verify_url, {'phone': '+923001234567', 'otp': '123456'})

    assert response.status_code == 400
    assert 'No OTP found' in response.data['message']


@pytest.mark.django_db
def test_verify_already_used_otp_returns_400(client, verify_url):
    """Replay attack: a used OTPRecord must not be accepted again."""
    OTPRecordFactory(phone='+923001234567', code='123456', is_used=True)
    response = client.post(verify_url, {'phone': '+923001234567', 'otp': '123456'})

    assert response.status_code == 400
    assert 'No OTP found' in response.data['message']


@pytest.mark.django_db
def test_verify_otp_wrong_length_returns_400(client, verify_url):
    """4-digit OTP (old Flutter client) must be rejected by the serializer."""
    response = client.post(verify_url, {'phone': '+923001234567', 'otp': '1234'})

    assert response.status_code == 400
    assert 'otp' in response.data['errors']


@pytest.mark.django_db
def test_verify_missing_fields_returns_400(client, verify_url):
    response = client.post(verify_url, {})
    assert response.status_code == 400
    assert 'phone' in response.data['errors']
    assert 'otp' in response.data['errors']


# ---------------------------------------------------------------------------
# 3. CompleteSignupView  POST /api/accounts/complete-signup/
# ---------------------------------------------------------------------------

@pytest.mark.django_db
def test_complete_signup_unauthenticated_returns_401(client, signup_url):
    response = client.post(signup_url, {'first_name': 'Ali', 'last_name': 'Raza'})
    assert response.status_code == 401
    assert response.data['code'] == 'unauthorized'


@pytest.mark.django_db
def test_complete_signup_updates_name_returns_200(client, signup_url):
    user = UserFactory(first_name='', last_name='')
    token = Token.objects.create(user=user)
    client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

    response = client.post(signup_url, {'first_name': 'Ali', 'last_name': 'Raza'})

    assert response.status_code == 200
    assert response.data == {'message': 'Profile updated successfully.'}
    user.refresh_from_db()
    assert user.first_name == 'Ali'
    assert user.last_name == 'Raza'


@pytest.mark.django_db
def test_complete_signup_missing_last_name_returns_400(client, signup_url):
    user = UserFactory()
    token = Token.objects.create(user=user)
    client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

    response = client.post(signup_url, {'first_name': 'Ali'})

    assert response.status_code == 400
    assert response.data['code'] == 'validation_error'


@pytest.mark.django_db
def test_complete_signup_empty_names_returns_400(client, signup_url):
    user = UserFactory()
    token = Token.objects.create(user=user)
    client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

    response = client.post(signup_url, {'first_name': '', 'last_name': ''})

    assert response.status_code == 400

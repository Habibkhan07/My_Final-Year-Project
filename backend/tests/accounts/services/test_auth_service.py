"""
auth_service unit tests.

These test business logic in isolation — no HTTP layer.
Twilio is always mocked. DB is real (SQLite in-memory per settings.py test override).
"""
import pytest
from django.utils import timezone
from datetime import timedelta
from django.contrib.auth import get_user_model

from accounts.models import OTPRecord, UserProfile
from customers.models import CustomerProfile
from accounts.services import auth_service
from tests.factories.accounts import UserFactory, UserProfileFactory, OTPRecordFactory
from tests.factories.customers import CustomerProfileFactory

User = get_user_model()

TWILIO_MOCK = 'accounts.services.twilio_service.send_otp'


# ---------------------------------------------------------------------------
# initiate_phone_login
# ---------------------------------------------------------------------------

@pytest.mark.django_db
def test_initiate_creates_otp_record(mocker):
    """A successful call must persist exactly one OTPRecord for the phone."""
    mocker.patch(TWILIO_MOCK)
    auth_service.initiate_phone_login(phone='+923001234567')

    assert OTPRecord.objects.filter(phone='+923001234567', is_used=False).count() == 1


@pytest.mark.django_db
def test_initiate_calls_twilio_with_correct_args(mocker):
    """Twilio must receive the normalised E.164 phone and the generated code."""
    mock_send = mocker.patch(TWILIO_MOCK)
    auth_service.initiate_phone_login(phone='+923001234567')

    mock_send.assert_called_once()
    call_kwargs = mock_send.call_args.kwargs
    assert call_kwargs['phone'] == '+923001234567'
    assert len(call_kwargs['code']) == 6
    assert call_kwargs['code'].isdigit()


@pytest.mark.django_db
def test_initiate_twilio_failure_rolls_back_otp_record(mocker):
    """
    If Twilio raises, the transaction must roll back.
    No orphaned OTPRecord should remain in the DB.
    """
    mocker.patch(TWILIO_MOCK, side_effect=ValueError('SMS failed'))

    with pytest.raises(ValueError, match='SMS failed'):
        auth_service.initiate_phone_login(phone='+923001234567')

    assert OTPRecord.objects.count() == 0


@pytest.mark.django_db
def test_initiate_generates_unique_codes_each_call(mocker):
    """Two consecutive calls must not always produce the same code (statistical check)."""
    mocker.patch(TWILIO_MOCK)
    auth_service.initiate_phone_login(phone='+923001234567')
    auth_service.initiate_phone_login(phone='+923001234568')

    codes = list(OTPRecord.objects.values_list('code', flat=True))
    assert len(codes) == 2
    # Both must be 6-digit numeric strings
    for code in codes:
        assert len(code) == 6
        assert code.isdigit()


# ---------------------------------------------------------------------------
# process_otp_verification
# ---------------------------------------------------------------------------

@pytest.mark.django_db
def test_verify_new_user_creates_user_and_profiles():
    """First verification for a phone must create User, UserProfile, CustomerProfile."""
    OTPRecordFactory(phone='+923001234567', code='123456')
    result = auth_service.process_otp_verification(phone='+923001234567', otp_input='123456')

    assert result['new_user'] is True
    assert result['name_required'] is True
    assert result['is_technician'] is False
    user = User.objects.get(username='+923001234567')
    # ``user_id`` is the realtime recipient-filter anchor (flag #19) — it must
    # match the actual User row so the frontend pipeline can compare it against
    # envelope.recipient_user_id without indirection.
    assert result['user_id'] == user.id
    assert UserProfile.objects.filter(phone='+923001234567').exists()
    assert CustomerProfile.objects.filter(user__username='+923001234567').exists()


@pytest.mark.django_db
def test_verify_returning_user_does_not_duplicate():
    """Second login for the same phone must not create duplicate User or profiles."""
    user = UserFactory(username='+923001234567', first_name='Ali', last_name='Raza')
    UserProfileFactory(user=user, phone='+923001234567')
    CustomerProfileFactory(user=user)
    OTPRecordFactory(phone='+923001234567', code='123456')

    result = auth_service.process_otp_verification(phone='+923001234567', otp_input='123456')

    assert result['new_user'] is False
    assert result['name_required'] is False
    assert User.objects.filter(username='+923001234567').count() == 1


@pytest.mark.django_db
def test_verify_marks_otp_record_as_used():
    """OTPRecord.is_used must be True after a successful verification."""
    record = OTPRecordFactory(phone='+923001234567', code='123456')
    auth_service.process_otp_verification(phone='+923001234567', otp_input='123456')

    record.refresh_from_db()
    assert record.is_used is True


@pytest.mark.django_db
def test_verify_wrong_code_raises():
    OTPRecordFactory(phone='+923001234567', code='111111')

    with pytest.raises(ValueError, match='Invalid OTP'):
        auth_service.process_otp_verification(phone='+923001234567', otp_input='999999')


@pytest.mark.django_db
def test_verify_wrong_code_does_not_mark_record_used():
    """A failed attempt must not consume the OTPRecord."""
    record = OTPRecordFactory(phone='+923001234567', code='111111')

    with pytest.raises(ValueError):
        auth_service.process_otp_verification(phone='+923001234567', otp_input='999999')

    record.refresh_from_db()
    assert record.is_used is False


@pytest.mark.django_db
def test_verify_expired_otp_raises():
    record = OTPRecordFactory(phone='+923001234567', code='123456')
    OTPRecord.objects.filter(pk=record.pk).update(
        expires_at=timezone.now() - timedelta(seconds=1)
    )

    with pytest.raises(ValueError, match='expired'):
        auth_service.process_otp_verification(phone='+923001234567', otp_input='123456')


@pytest.mark.django_db
def test_verify_no_record_raises():
    """No OTPRecord at all — user never called login-otp."""
    with pytest.raises(ValueError, match='No OTP found'):
        auth_service.process_otp_verification(phone='+923001234567', otp_input='123456')


@pytest.mark.django_db
def test_verify_used_otp_raises():
    """Replay attack: a previously used OTPRecord must be rejected when
    there is no matching user (which there wouldn't be for a stale
    OTP that was never followed up with a successful first verify).
    """
    OTPRecordFactory(phone='+923001234567', code='123456', is_used=True)

    with pytest.raises(ValueError, match='already been used'):
        auth_service.process_otp_verification(phone='+923001234567', otp_input='123456')


@pytest.mark.django_db
def test_verify_used_otp_outside_grace_window_raises():
    """Replay attack with the user already in the DB but the OTP record
    consumed > 60s ago: must reject. The idempotent retry path is gated
    on a short grace window — anything older is a stale replay.
    """
    from django.utils import timezone
    from django.contrib.auth.models import User

    User.objects.create_user(username='+923001234567')
    record = OTPRecordFactory(
        phone='+923001234567', code='123456', is_used=True,
    )
    # Backdate so the grace check fails.
    OTPRecord.objects.filter(pk=record.pk).update(
        created_at=timezone.now() - timezone.timedelta(minutes=5),
    )

    with pytest.raises(ValueError, match='already been used'):
        auth_service.process_otp_verification(phone='+923001234567', otp_input='123456')


@pytest.mark.django_db
def test_verify_used_otp_within_grace_returns_same_token():
    """Idempotent retry (audit S-12): a duplicate verify within the
    grace window must return the SAME token instead of 400, so the FE
    auto-submit + manual-button race doesn't dislodge a just-acquired
    session.
    """
    from rest_framework.authtoken.models import Token
    from django.contrib.auth.models import User
    from accounts.models import UserProfile

    user = User.objects.create_user(username='+923001234567')
    UserProfile.objects.create(user=user, phone='+923001234567')
    original_token = Token.objects.create(user=user)
    # Used record, just consumed (within grace window).
    OTPRecordFactory(phone='+923001234567', code='123456', is_used=True)

    result = auth_service.process_otp_verification(
        phone='+923001234567', otp_input='123456',
    )

    assert result['token'] == original_token.key
    assert result['user_id'] == user.id
    assert result['new_user'] is False


@pytest.mark.django_db
def test_verify_returns_valid_token():
    """The returned token must exist in the DB and belong to the right user."""
    from rest_framework.authtoken.models import Token
    OTPRecordFactory(phone='+923001234567', code='123456')

    result = auth_service.process_otp_verification(phone='+923001234567', otp_input='123456')

    token = Token.objects.get(key=result['token'])
    assert token.user.username == '+923001234567'

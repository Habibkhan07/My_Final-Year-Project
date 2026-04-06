import random
from django.db import transaction
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework.authtoken.models import Token

from ..models import UserProfile, CustomerProfile, OTPRecord
from ..selectors import user_selectors
from . import twilio_service


def initiate_phone_login(*, phone: str):
    """
    Generates a 6-digit OTP, persists it as an OTPRecord, and dispatches
    an SMS via Twilio.

    Why atomic: if Twilio raises, the transaction rolls back so no orphaned
    OTPRecord accumulates in the DB.

    Raises:
        ValueError: if SMS delivery fails (Twilio error).
    """
    code = f"{random.randint(0, 999999):06d}"

    with transaction.atomic():
        OTPRecord.objects.create(phone=phone, code=code)
        # twilio_service.send_otp raises ValueError on failure → rolls back the record
        twilio_service.send_otp(phone=phone, code=code)


def process_otp_verification(*, phone: str, otp_input: str):
    """
    Verifies the OTP and performs the register-or-login logic atomically.

    Why select_for_update: prevents two concurrent requests from both seeing
    the same unused OTPRecord and both succeeding (replay attack / race condition).

    Raises:
        ValueError: for invalid, expired, or already-used OTPs.
    """
    # SECURITY: scoped to the submitted phone + unused + non-expired
    with transaction.atomic():
        record = (
            OTPRecord.objects
            .select_for_update()
            .filter(phone=phone, is_used=False)
            .order_by('-created_at')
            .first()
        )

        if record is None:
            raise ValueError("No OTP found for this number. Please request a new one.")

        if record.is_expired:
            raise ValueError("OTP has expired. Please request a new one.")

        if record.code != otp_input:
            raise ValueError("Invalid OTP.")

        # Mark consumed before any further writes
        record.is_used = True
        record.save(update_fields=['is_used'])

        user, created = User.objects.get_or_create(username=phone)

        if created:
            UserProfile.objects.create(user=user, phone=phone)
            CustomerProfile.objects.create(user=user)

        token, _ = Token.objects.get_or_create(user=user)
        name_required = user_selectors.is_profile_incomplete(user=user)

        return {
            "token": token.key,
            "is_technician": user.userprofile.is_technician,
            "name_required": name_required,
            "new_user": created,
        }

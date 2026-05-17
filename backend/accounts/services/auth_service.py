import random
from django.db import transaction
from django.contrib.auth.models import User
from django.utils import timezone
from django.conf import settings
from rest_framework.authtoken.models import Token

from ..models import UserProfile, OTPRecord
from customers.models import CustomerProfile
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
    if settings.DEBUG:
        code = "123456"
    else:
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

    Idempotency (audit S-12): the verify endpoint is intentionally
    idempotent within a short grace window. If the most-recent OTPRecord
    for this phone is already-used AND its code matches the submitted
    ``otp_input`` AND it was consumed in the last
    ``_REVERIFY_GRACE_SECONDS``, we treat the call as a duplicate of the
    successful first verify and return the existing Token. This closes
    the "FE fired verify twice (auto-submit + button)" race without
    weakening security — the grace check guarantees the duplicate must
    be a near-immediate retry, not a stale replay.

    Raises:
        ValueError: for invalid, expired, or already-used OTPs.
    """
    # SECURITY: scoped to the submitted phone + non-expired
    with transaction.atomic():
        # Look at the most-recent OTP record regardless of ``is_used`` so
        # we can detect the idempotent-retry case before bailing out.
        record = (
            OTPRecord.objects
            .select_for_update()
            .filter(phone=phone)
            .order_by('-created_at')
            .first()
        )

        if record is None:
            raise ValueError("No OTP found for this number. Please request a new one.")

        if record.is_expired:
            raise ValueError("OTP has expired. Please request a new one.")

        if record.code != otp_input:
            raise ValueError("Invalid OTP.")

        # Idempotent-retry path: same code, already consumed, within the
        # grace window. Return the existing token instead of 400.
        if record.is_used:
            grace_cutoff = timezone.now() - timezone.timedelta(
                seconds=_REVERIFY_GRACE_SECONDS,
            )
            # ``is_used`` flips together with ``record.save(update_fields=...)``
            # below — the ``modified_at`` field would be cleaner but isn't
            # on the model, so we approximate with ``created_at + grace``.
            # Far enough in the past → treat as exhausted, fail.
            if record.created_at < grace_cutoff:
                raise ValueError(
                    "OTP has already been used. Please request a new one.",
                )
            # Within grace: re-issue the same response shape. The user
            # row + token must already exist from the first verify;
            # `get_or_create` is idempotent on both.
            user = User.objects.filter(username=phone).first()
            if user is None:
                # Shouldn't happen — the first verify created the user —
                # but if the DB is somehow inconsistent, fall through to
                # the strict "already used" error rather than silently
                # bypassing auth.
                raise ValueError(
                    "OTP has already been used. Please request a new one.",
                )
            token, _ = Token.objects.get_or_create(user=user)
            name_required = user_selectors.is_profile_incomplete(user=user)
            return {
                "user_id": user.id,
                "token": token.key,
                "is_technician": user.userprofile.is_technician,
                "name_required": name_required,
                "new_user": False,
            }

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
            # ``user_id`` is consumed by the frontend orchestrator's
            # override of ``currentAuthUserIdProvider`` — the realtime
            # pipeline's recipient filter compares this id against
            # envelope.recipient_user_id to drop frames intended for a
            # different account on a shared device. See flag #19.
            "user_id": user.id,
            "token": token.key,
            "is_technician": user.userprofile.is_technician,
            "name_required": name_required,
            "new_user": created,
        }


# Grace window for the verify-otp idempotency check. A duplicate verify
# (FE auto-submit + button race, network retry of an already-succeeded
# request) is allowed within this window; anything later is a stale
# replay and gets the strict "already used" error.
_REVERIFY_GRACE_SECONDS = 60


def logout(*, user) -> None:
    """
    Invalidates the user's auth token server-side.

    Idempotent: deleting a missing row is a 0-row no-op, not an error.
    This matters because the FE's logout flow first POSTs here, then
    clears local secure storage — a retried POST after a transient
    network failure must succeed cleanly.

    Why a service for one line: the view stays a thin HTTP shell per
    the 4-layer rule, and this is the right home for future side-effects
    (audit-log row, per-device revoke in v1.1, etc.).
    """
    Token.objects.filter(user=user).delete()

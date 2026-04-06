from django.conf import settings
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException


def send_otp(*, phone: str, code: str) -> None:
    """
    Sends an OTP SMS via Twilio to the given phone number.

    Credential selection:
      DEBUG=True  → skips Twilio entirely; prints OTP to the terminal for
                    local development (Pakistan restricts trial SMS verification).
      DEBUG=False → uses TWILIO_* live credentials (real SMS, burns credits).

    Raises:
        ValueError: if Twilio rejects the request (unverified number, bad
                    credentials, network error, etc.)
    """
    if settings.DEBUG:
        # Dev-only mock: no SMS sent, OTP visible in runserver terminal.
        print(f"\n{'='*40}")
        print(f"  [DEV OTP]  Phone : {phone}")
        print(f"  [DEV OTP]  Code  : {code}")
        print(f"{'='*40}\n")
        return

    client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)

    try:
        client.messages.create(
            body=f"Your verification code is: {code}. It expires in 30 seconds.",
            from_=settings.TWILIO_FROM_NUMBER,
            to=phone,
        )
    except TwilioRestException as e:
        raise ValueError(
            f"Failed to send OTP to {phone} (from {settings.TWILIO_FROM_NUMBER}): {e.msg}"
        ) from e
    except Exception as e:
        # Catches network errors, requests exceptions, auth failures at the HTTP
        # layer, etc. — anything Twilio raises that isn't TwilioRestException.
        raise ValueError(
            f"Failed to send OTP to {phone} (from {settings.TWILIO_FROM_NUMBER}): {e}"
        ) from e

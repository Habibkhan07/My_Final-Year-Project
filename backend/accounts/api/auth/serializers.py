import re
from rest_framework import serializers

# Matches Pakistani mobile numbers in two formats:
#   Local : 03XXXXXXXXX  (11 digits, starts with 03 + active network prefix 0-6 + 8 digits)
#   E.164 : +923XXXXXXXXX (same number with country code +92)
_PK_PHONE_RE = re.compile(r'^(?:0|\+92)(3[0-6]\d{8})$')


class PhoneLoginInputSerializer(serializers.Serializer):
    """
    Validates and normalises Pakistani mobile numbers to E.164 (+92XXXXXXXXXX)
    before passing them downstream to Twilio and the DB.
    """
    phone = serializers.CharField(
        help_text="Pakistani mobile number — local (03001234567) or E.164 (+923001234567)"
    )

    def validate_phone(self, value):
        phone = value.strip()

        match = _PK_PHONE_RE.match(phone)
        if not match:
            raise serializers.ValidationError(
                "Enter a valid Pakistani mobile number (e.g. 03001234567 or +923001234567)."
            )

        # Normalise to E.164 so Twilio always gets a consistent format
        # match.group(1) is the 9-digit part after the leading 0 or +92
        return f"+92{match.group(1)}"

class OTPVerifyInputSerializer(serializers.Serializer):
    """
    New Serializer for the second step of Auth. [cite: 211, 363]
    """
    phone = serializers.CharField(required=True)
    otp = serializers.CharField(required=True, min_length=6, max_length=6)
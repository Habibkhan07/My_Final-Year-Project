import re
from rest_framework import serializers

class PhoneLoginInputSerializer(serializers.Serializer):
    """
    Renamed from SignupSerializer to match your new View. [cite: 156, 261]
    Strictly handles phone data integrity.
    """
    phone = serializers.CharField(
        help_text="Enter mobile number with country code (e.g., +923001234567)"
    )

    def validate_phone(self, value):
        # 1. Remove accidental whitespace
        phone = value.strip()

        # 2. Regex for digits and leading '+'
        if not re.match(r'^\+?[\d]+$', phone):
            raise serializers.ValidationError(
                "Phone number contains invalid characters. Use only digits and '+'."
            )

        # 3. Standard E.164 length check
        if len(phone) < 10:
            raise serializers.ValidationError("Phone number is too short.")
        if len(phone) > 15:
            raise serializers.ValidationError("Phone number is too long.")

        return phone

class OTPVerifyInputSerializer(serializers.Serializer):
    """
    New Serializer for the second step of Auth. [cite: 211, 363]
    """
    phone = serializers.CharField(required=True)
    otp = serializers.CharField(required=True, min_length=4, max_length=4)
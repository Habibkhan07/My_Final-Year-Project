from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework import serializers

from ...services import auth_service, profile_service
from .serializers import PhoneLoginInputSerializer, OTPVerifyInputSerializer


class PhoneLoginView(APIView):
    """Handles the initiation of the OTP flow."""

    def post(self, request):
        serializer = PhoneLoginInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            auth_service.initiate_phone_login(
                phone=serializer.validated_data['phone']
            )
        except ValueError as e:
            # detail → exception handler promotes it to the toast `message` field
            raise serializers.ValidationError({"detail": str(e)})
        except Exception as e:
            # Safety net for unexpected errors (e.g. DB down, OTPRecord.create fails).
            # Log-worthy: means something outside Twilio broke.
            raise serializers.ValidationError({"detail": f"Could not send OTP: {e}"})

        return Response({"message": "OTP sent successfully"}, status=status.HTTP_200_OK)


class VerifyOTPView(APIView):
    """Handles OTP verification and the register-or-login logic."""

    class OutputSerializer(serializers.Serializer):
        token = serializers.CharField()
        is_technician = serializers.BooleanField()
        name_required = serializers.BooleanField()
        new_user = serializers.BooleanField()

    def post(self, request):
        serializer = OTPVerifyInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            result = auth_service.process_otp_verification(
                phone=serializer.validated_data['phone'],
                otp_input=serializer.validated_data['otp'],
            )
        except ValueError as e:
            # detail  → exception handler puts this in the toast `message` field
            # otp     → Flutter uses this for field-level error highlighting
            raise serializers.ValidationError({"detail": str(e), "otp": [str(e)]})

        return Response(self.OutputSerializer(result).data, status=status.HTTP_200_OK)


class CompleteSignupView(APIView):
    """Updates name on first login. Requires authentication."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        success, message = profile_service.update_user_profile(
            user=request.user,
            first_name=request.data.get('first_name'),
            last_name=request.data.get('last_name'),
        )

        if not success:
            raise serializers.ValidationError({"detail": message})

        return Response({"message": message}, status=status.HTTP_200_OK)

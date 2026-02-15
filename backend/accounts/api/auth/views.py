from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework import serializers

# Import the logic and selectors [cite: 77, 260]
from ...services import auth_service, profile_service
from .serializers import PhoneLoginInputSerializer, OTPVerifyInputSerializer

class PhoneLoginView(APIView):
    """Handles the initiation of the OTP flow[cite: 262]."""
    def post(self, request):
        serializer = PhoneLoginInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True) # Validates HTTP input [cite: 266]
        
        # Delegate to Service [cite: 82, 368]
        result, error = auth_service.initiate_phone_login(
            phone=serializer.validated_data['phone']
        )
        
        if error:
            return Response(error, status=status.HTTP_400_BAD_REQUEST)
        return Response(result, status=status.HTTP_200_OK)

class VerifyOTPView(APIView):
    """Handles the verification and authentication logic[cite: 361]."""

    class OutputSerializer(serializers.Serializer):
        token = serializers.CharField()
        is_technician = serializers.BooleanField()
        name_required = serializers.BooleanField()
        new_user = serializers.BooleanField()

    def post(self, request):
        serializer = OTPVerifyInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            # Delegate to Service [cite: 268, 370]
            result = auth_service.process_otp_verification(
                phone=serializer.validated_data['phone'],
                otp_input=serializer.validated_data['otp']
            )
            response_serializer = self.OutputSerializer(result)
            return Response(result, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class CompleteSignupView(APIView):
    """Handles updating the user profile once authenticated[cite: 78]."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # We pass request.user directly to the service [cite: 84, 269]
        success, message = profile_service.update_user_profile(
            user=request.user,
            first_name=request.data.get('first_name'),
            last_name=request.data.get('last_name')
        )
        
        if not success:
            return Response({"error": message}, status=status.HTTP_400_BAD_REQUEST)
        return Response({"message": message}, status=status.HTTP_200_OK)
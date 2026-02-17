from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework import serializers

# Import the logic and selectors
from ...services import auth_service, profile_service
from .serializers import PhoneLoginInputSerializer, OTPVerifyInputSerializer

class PhoneLoginView(APIView):
    """Handles the initiation of the OTP flow."""
    def post(self, request):
        serializer = PhoneLoginInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True) # Validates HTTP input
        
        # Delegate to Service
        result, error = auth_service.initiate_phone_login(
            phone=serializer.validated_data['phone']
        )
        
        if error:
            # OLD: return Response(error, status=status.HTTP_400_BAD_REQUEST)
            # NEW: Raise exception so Global Handler formats it
            # We use 'detail' so it appears as a main message, or map to 'phone' field
            raise serializers.ValidationError({"detail": error})

        return Response(result, status=status.HTTP_200_OK)

class VerifyOTPView(APIView):
    """Handles the verification and authentication logic."""

    class OutputSerializer(serializers.Serializer):
        token = serializers.CharField()
        is_technician = serializers.BooleanField()
        name_required = serializers.BooleanField()
        new_user = serializers.BooleanField()

    def post(self, request):
        serializer = OTPVerifyInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            # Delegate to Service
            result = auth_service.process_otp_verification(
                phone=serializer.validated_data['phone'],
                otp_input=serializer.validated_data['otp']
            )
            # Note: You were creating response_serializer but not using it in the return.
            # Ideally: data = self.OutputSerializer(result).data
            return Response(result, status=status.HTTP_200_OK)

        except ValueError as e:
            # OLD: return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
            
            # NEW: Raise Validation error mapped to the 'otp' field
            # This allows Flutter to highlight the specific OTP input box
            raise serializers.ValidationError({"otp": [str(e)]})

class CompleteSignupView(APIView):
    """Handles updating the user profile once authenticated."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # We pass request.user directly to the service
        success, message = profile_service.update_user_profile(
            user=request.user,
            first_name=request.data.get('first_name'),
            last_name=request.data.get('last_name')
        )
        
        if not success:
            # OLD: return Response({"error": message}, status=status.HTTP_400_BAD_REQUEST)
            
            # NEW: Raise exception
            raise serializers.ValidationError({"detail": message})
            
        return Response({"message": message}, status=status.HTTP_200_OK)
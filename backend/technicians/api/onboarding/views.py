from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, parsers
from rest_framework.permissions import IsAuthenticated
from .serializers import MediaUploadSerializer, TechnicianFinalizeSerializer
from ...services import media_service, registration_service
from ...selectors import service_selectors

class OnboardingMetadataView(APIView):
    """New: Provides the metadata Flutter needs to build the form."""
    #permission_classes = [IsAuthenticated]
    
    def get(self, request):
        data = service_selectors.get_services_with_subservices()
        return Response(data, status=status.HTTP_200_OK)

class MediaUploadView(APIView):
    """Phase 1: Handles your robust UUID staging."""
    parser_classes = (parsers.MultiPartParser, parsers.FormParser)
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        serializer = MediaUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        media_obj = media_service.save_temporary_media(file_obj=request.FILES['file'])
        return Response({"uuid": media_obj.id}, status=status.HTTP_201_CREATED)

class RegisterTechnicianView(APIView):
    """Phase 2: Finalizes registration using UUIDs sent back from Flutter."""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        # The serializer here still uses your robust 'to_internal_value'
        # which converts UUIDs back into actual File objects for the service.
        serializer = TechnicianFinalizeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        profile = registration_service.finalize_registration(
            user=request.user, 
            validated_data=serializer.validated_data
        )
        return Response(serializer.to_representation(profile), status=status.HTTP_201_CREATED)
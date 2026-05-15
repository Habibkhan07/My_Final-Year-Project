"""HTTP layer for tech work-location read/write.

Single endpoint (``GET``/``PATCH``) keyed to ``request.user``. The URL never
carries a PK — every operation is intrinsically scoped to the caller's
``TechnicianProfile``, so there is no IDOR surface.

Lifts validation into the serializers and writes into the service. The view
itself parses request → calls serializer → delegates → returns the read
shape, matching the project's thin-view standard ([[claudemd]] 4-layer rule).
"""
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.selectors.profile_selector import get_work_location
from technicians.services.work_location_service import update_work_location

from .serializers import (
    TechnicianWorkLocationReadSerializer,
    TechnicianWorkLocationWriteSerializer,
)


class TechnicianWorkLocationView(APIView):
    """``/api/technicians/me/work-location/`` — read or update the caller's work location.

    GET returns ``has_profile=False`` for pure customers so the FE router can
    branch without a 404 round-trip. PATCH is rejected (404) for pure
    customers — they have nothing to patch.
    """

    # SECURITY: IsAuthenticated locks the endpoint to a real JWT session.
    # The ``/me/`` shape (no PK in the URL) means caller can only target
    # their own row — IDOR-impossible.
    permission_classes = [IsAuthenticated]

    def get(self, request):
        data = get_work_location(user=request.user)
        # ``has_profile`` is read-only metadata for the FE router; strip it
        # from the body before running the serialiser so the contract stays
        # focused on the work-location fields.
        has_profile = data.pop('has_profile')
        serializer = TechnicianWorkLocationReadSerializer(data)
        payload = dict(serializer.data)
        payload['has_profile'] = has_profile
        return Response(payload, status=status.HTTP_200_OK)

    def patch(self, request):
        serializer = TechnicianWorkLocationWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        update_work_location(user=request.user, validated_data=serializer.validated_data)
        # Re-read through the selector so the response is the same shape the
        # GET returns — keeps the FE's cache write trivial.
        read_data = get_work_location(user=request.user)
        has_profile = read_data.pop('has_profile')
        read_serializer = TechnicianWorkLocationReadSerializer(read_data)
        payload = dict(read_serializer.data)
        payload['has_profile'] = has_profile
        return Response(payload, status=status.HTTP_200_OK)

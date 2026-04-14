# customers/api/technician_profile/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from technicians.models import TechnicianProfile
from technicians.selectors.profile_selector import get_technician_profile_detail
from customers.api.technician_profile.serializers import TechnicianProfileDetailSerializer


class TechnicianProfileDetailView(APIView):
    """
    Returns the full public profile of an approved technician, with contextual
    pricing resolved from the discovery path the customer took to arrive here.
    """

    def get(self, request, pk, *args, **kwargs):
        # SECURITY: Profile is public-readable; status='APPROVED' guard in the selector
        # prevents exposing PENDING or REJECTED technician profiles.

        # 1. Safely parse optional GPS coordinates
        try:
            lat = float(request.query_params.get('lat'))
            lng = float(request.query_params.get('lng'))
        except (TypeError, ValueError):
            lat, lng = None, None

        # 2. Safely parse optional discovery context IDs
        def _safe_int(key):
            val = request.query_params.get(key)
            if val and str(val).isdigit():
                return int(val)
            return None

        service_id = _safe_int('service_id')
        sub_service_id = _safe_int('sub_service_id')
        promotion_id = _safe_int('promotion_id')

        # 3. Delegate to the selector — raises DoesNotExist for unknown/unapproved profiles
        try:
            tech, resolved_service, resolved_subservice, resolved_promo = get_technician_profile_detail(
                tech_id=pk,
                lat=lat,
                lng=lng,
                service_id=service_id,
                sub_service_id=sub_service_id,
                promotion_id=promotion_id,
            )
        except TechnicianProfile.DoesNotExist:
            return Response(
                {
                    "status": 404,
                    "code": "not_found",
                    "message": "Technician profile not found.",
                    "errors": {},
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        # 4. Serialize with pricing context injected
        serializer = TechnicianProfileDetailSerializer(
            tech,
            context={
                'resolved_service': resolved_service,
                'resolved_subservice': resolved_subservice,
                'resolved_promo': resolved_promo,
                'request': request,
            },
        )
        return Response(serializer.data)

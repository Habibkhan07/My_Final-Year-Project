from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.models import TechnicianProfile
from technicians.selectors.metrics_selector import get_technician_metrics


class TechnicianMetricsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # SECURITY: technician resolved through request.user — no pk in URL,
        # so a logged-in customer or another tech cannot reach this data.
        try:
            technician = request.user.tech_profile
        except TechnicianProfile.DoesNotExist:
            return Response(
                {
                    'status': 403,
                    'code': 'permission_denied',
                    'message': 'User is not a registered technician.',
                    'errors': {'user': ['Technician profile not found.']},
                },
                status=403,
            )

        return Response(get_technician_metrics(technician))

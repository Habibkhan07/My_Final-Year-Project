from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from technicians.selectors.dashboard_selector import get_technician_dashboard
from technicians.models import TechnicianProfile

class TechnicianDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # SECURITY: Ensure only authenticated technicians can access their own dashboard by resolving tech_profile through the authenticated user
        try:
            technician = request.user.tech_profile
        except TechnicianProfile.DoesNotExist:
            return Response({
                "status": 403,
                "code": "permission_denied",
                "message": "User is not a registered technician.",
                "errors": {"user": ["Technician profile not found."]}
            }, status=403)

        dashboard_data = get_technician_dashboard(technician, request)
        return Response(dashboard_data)

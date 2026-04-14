import datetime

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from technicians.models import TechnicianProfile
from technicians.selectors.availability_selector import get_technician_availability


def _safe_int(value: str | None) -> int | None:
    """Parse a query-param string to int, returning None on any failure."""
    if value is None:
        return None
    try:
        return int(value)
    except (ValueError, TypeError):
        return None


class TechnicianAvailabilityView(APIView):
    """
    GET /api/customers/technicians/{pk}/availability/?date=YYYY-MM-DD[&service_id=...][&sub_service_id=...]

    Returns a flat array of bookable 1-hour slots for the given technician on the given date.
    Context params (service_id / sub_service_id) determine job duration for end-of-day clipping —
    pass the same params used on the profile detail endpoint so pricing and availability stay in sync.

    # SECURITY: only APPROVED technicians expose availability; selector enforces this via DoesNotExist guard
    """

    def get(self, request, pk: int):
        # --- Parse & validate date (required) ---
        date_str = request.query_params.get('date')
        if not date_str:
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'The "date" query parameter is required (YYYY-MM-DD).',
                    'errors': {'date': ['This field is required.']},
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            date_obj = datetime.date.fromisoformat(date_str)  # strict YYYY-MM-DD
        except ValueError:
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': f'Invalid date format: "{date_str}". Expected YYYY-MM-DD.',
                    'errors': {'date': ['Enter a valid date in YYYY-MM-DD format.']},
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # --- Parse optional context params (silently ignore garbage) ---
        sub_service_id = _safe_int(request.query_params.get('sub_service_id'))
        service_id     = _safe_int(request.query_params.get('service_id'))

        # --- Delegate to selector ---
        try:
            slots = get_technician_availability(
                tech_id=pk,
                date_obj=date_obj,
                sub_service_id=sub_service_id,
                service_id=service_id,
            )
        except TechnicianProfile.DoesNotExist:
            return Response(
                {
                    'status': 404,
                    'code': 'not_found',
                    'message': 'Technician profile not found.',
                    'errors': {},
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(slots, status=status.HTTP_200_OK)

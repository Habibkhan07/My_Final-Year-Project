from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from technicians.models import TechnicianProfile
from bookings.exceptions import (
    InconsistentBookingIntentError,
    InvalidAddressError,
    OutOfServiceAreaError,
    PromoFirewallError,
    SlotUnavailableError,
)
from bookings.services.instant_book_service import create_instant_booking
from bookings.api.instant_book.serializers import InstantBookSerializer

# SECURITY: IsAuthenticated blocks unauthenticated callers at the permission layer;
# address ownership is enforced inside the service so no IDOR is possible.


class InstantBookView(APIView):
    """
    POST /api/bookings/instant-book/

    Creates a CONFIRMED booking for the authenticated customer.
    All business logic (ownership, geofence, race condition) lives in the service.
    This view is HTTP-only: parse → validate → delegate → respond.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = InstantBookSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'Invalid booking data.',
                    'errors': serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            booking = create_instant_booking(
                customer_user=request.user,
                **serializer.validated_data,
            )

        except InvalidAddressError:
            # Opaque: same response whether the address doesn't exist or belongs
            # to another user — prevents address ID enumeration.
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'Invalid address.',
                    'errors': {'address_id': ['No matching address found for this account.']},
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        except TechnicianProfile.DoesNotExist:
            return Response(
                {
                    'status': 404,
                    'code': 'not_found',
                    'message': 'Technician not found.',
                    'errors': {},
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        except OutOfServiceAreaError as exc:
            return Response(
                {
                    'status': 400,
                    'code': 'out_of_service_area',
                    'message': (
                        f'This technician does not service your area. '
                        f'Your address is {exc.distance_km} km away '
                        f'(limit: {exc.radius_km} km).'
                    ),
                    'errors': {},
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        except SlotUnavailableError:
            return Response(
                {
                    'status': 409,
                    'code': 'slot_unavailable',
                    'message': 'This time slot was just booked. Please choose another.',
                    'errors': {},
                },
                status=status.HTTP_409_CONFLICT,
            )

        except InconsistentBookingIntentError as exc:
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'Inconsistent booking intent.',
                    'errors': {exc.field: [exc.message]},
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        except PromoFirewallError:
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'Promotions cannot be applied to fixed-price gigs.',
                    'errors': {
                        'promotion_id': [
                            'Discount stacking is not allowed on fixed-price sub-services.'
                        ],
                    },
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({'booking_id': booking.id}, status=status.HTTP_201_CREATED)

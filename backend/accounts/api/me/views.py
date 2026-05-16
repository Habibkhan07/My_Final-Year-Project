"""
`/api/accounts/me/` view — the authenticated user's own profile.

GET   returns the current user's editable identity fields plus phone +
      is_technician (read-only).
PATCH updates first_name / last_name. Returns the fresh state so the FE
      cache can sync without a second round-trip.
"""
from rest_framework import serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from ...selectors import user_selectors
from ...services import profile_service
from .serializers import MeOutputSerializer, MeUpdateSerializer


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # SECURITY: scoped to request.user only. No user_id ever appears
        # in the URL, body, or query — the only thing the caller can read
        # is their own row.
        user = user_selectors.get_me(user=request.user)
        return Response(MeOutputSerializer(user).data)

    def patch(self, request):
        # SECURITY: MeUpdateSerializer whitelists exactly `first_name` and
        # `last_name`. Any extra fields in the request body (e.g.
        # is_technician, is_staff, phone) are dropped at validation —
        # never reach the service.
        serializer = MeUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        success, message = profile_service.update_user_profile(
            user=request.user,
            first_name=serializer.validated_data['first_name'],
            last_name=serializer.validated_data['last_name'],
        )
        if not success:
            # `detail` is promoted to the toast `message` by the custom
            # exception handler — matches the rest of the auth surface.
            raise serializers.ValidationError({"detail": message})

        # Return the fresh row so the FE notifier can swap its state
        # without a follow-up GET — matches the addresses PATCH contract.
        user = user_selectors.get_me(user=request.user)
        return Response(MeOutputSerializer(user).data, status=status.HTTP_200_OK)

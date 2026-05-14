from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError

def custom_exception_handler(exc, context):
    # 0. Bookings orchestrator + chatbot views raise canonical-envelope
    # errors that carry their own ``code`` / ``message`` / ``errors``.
    # DRF's default flow would flatten ``code`` into the generic
    # "validation_error" and drop the field map — match these first.
    # Lazy imports: ``bookings`` / ``chatbot`` import DRF, which imports
    # settings, which imports this handler. Top-level imports here would
    # create a module-load cycle.
    from bookings.exceptions import BookingValidationError
    from chatbot.exceptions import ChatbotError
    from wallet.exceptions import (
        DuplicatePendingWithdrawalError,
        InactiveTechnicianError,
        InsufficientFundsError,
        WalletLockoutError,
    )

    if isinstance(
        exc,
        (
            BookingValidationError,
            ChatbotError,
            DuplicatePendingWithdrawalError,
            InactiveTechnicianError,
            InsufficientFundsError,
            WalletLockoutError,
        ),
    ):
        return Response(
            {
                "status": exc.status_code,
                "code": exc.code,
                "message": exc.message,
                "errors": exc.errors,
            },
            status=exc.status_code,
        )

    # 1. Call DRF's default handler first
    # This handles standard ValidationErrors (400), NotAuthenticated (401), etc.
    response = exception_handler(exc, context)

    # 2. Handle Database Integrity Errors (Duplicate CNIC/Email)
    # Your 'registration_service' will trigger this if a user already exists.
    # DRF ignores this by default (returns None), so we catch it here.
    if isinstance(exc, IntegrityError) and not response:
        return Response(
            {
                "status": status.HTTP_409_CONFLICT,
                "code": "resource_conflict",
                "message": "A record with this information (CNIC or Email) already exists.",
                "errors": {}
            },
            status=status.HTTP_409_CONFLICT
        )

    # 3. Standardize the Response Structure for Flutter
    if response is not None:
        # Define default values based on the status code
        custom_status = response.status_code
        custom_code = "error"
        default_msg = "Operation failed."

        if custom_status == status.HTTP_404_NOT_FOUND:
            default_msg = "Resource not found."
            custom_code = "not_found"
        elif custom_status == status.HTTP_400_BAD_REQUEST:
            default_msg = "Invalid input data."
            custom_code = "validation_error"
        elif custom_status == status.HTTP_401_UNAUTHORIZED:
            default_msg = "Unauthorized."
            custom_code = "unauthorized"

        # SMART LOGIC: Prefer specific messages from Serializers/Views
        # If the serializer raised a specific 'detail' message (like "UUID expired"), use it.
        # Otherwise, fallback to the 'default_msg' defined above.
        
        custom_message = default_msg # Start with default

        if isinstance(response.data, dict):
            # If 'detail' key exists, use it as the main message
            custom_message = response.data.get('detail', default_msg)
            # Remove 'detail' from payload so it doesn't appear twice in JSON
            if 'detail' in response.data:
                del response.data['detail']
        elif isinstance(response.data, list):
            # If response is a list (rare, but possible), take the first item
            custom_message = str(response.data[0])

        # Final JSON Envelope
        response.data = {
            "status": custom_status,
            "code": custom_code,       # Stable string for Flutter logic
            "message": custom_message, # Human readable string for Toast
            "errors": response.data    # Raw errors for highlighting fields
        }

    return response
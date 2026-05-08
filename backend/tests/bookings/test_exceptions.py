"""Envelope-shape tests for ``BookingValidationError``.

Verifies that the custom DRF exception handler at
``core.common.failures.exception.custom_exception_handler`` emits the
canonical ``{status, code, message, errors}`` envelope for the orchestrator's
validation exception — and crucially that ``code`` and ``errors`` are
preserved verbatim (not flattened to ``"validation_error"`` / ``{}`` by
DRF's default flow).
"""

from rest_framework import status as drf_status
from rest_framework.test import APIRequestFactory

from bookings.exceptions import (
    BookingValidationError,
    ERROR_INVALID_TRANSITION,
    ERROR_QUOTE_BAND_VIOLATION,
)
from core.common.failures.exception import custom_exception_handler


def _ctx():
    factory = APIRequestFactory()
    request = factory.get('/dummy')
    return {'request': request, 'view': None}


class TestBookingValidationErrorEnvelope:
    def test_envelope_shape_400_invalid_transition(self):
        exc = BookingValidationError(
            code=ERROR_INVALID_TRANSITION,
            message='Booking is not in ARRIVED state.',
            errors={'current_status': ['CONFIRMED']},
        )
        response = custom_exception_handler(exc, _ctx())
        assert response is not None
        assert response.status_code == 400
        # All four envelope keys present.
        assert set(response.data.keys()) == {'status', 'code', 'message', 'errors'}
        assert response.data['status'] == 400
        assert response.data['code'] == ERROR_INVALID_TRANSITION
        assert response.data['message'] == 'Booking is not in ARRIVED state.'
        assert response.data['errors'] == {'current_status': ['CONFIRMED']}

    def test_code_not_flattened_to_generic_validation_error(self):
        # The whole point of patching the handler — DRF's default flow
        # would force code='validation_error' for any 400.
        exc = BookingValidationError(
            code=ERROR_QUOTE_BAND_VIOLATION,
            message='outside the band',
            errors={'line_items[0].priced_at': ['too high']},
        )
        response = custom_exception_handler(exc, _ctx())
        assert response.data['code'] == 'quote_band_violation'
        assert response.data['code'] != 'validation_error'

    def test_errors_default_to_empty_dict(self):
        exc = BookingValidationError(code='whatever', message='x')
        response = custom_exception_handler(exc, _ctx())
        assert response.data['errors'] == {}

    def test_custom_status_propagates(self):
        exc = BookingValidationError(
            code='not_assigned_to_you',
            message='nope',
            status=drf_status.HTTP_403_FORBIDDEN,
        )
        response = custom_exception_handler(exc, _ctx())
        assert response.status_code == 403
        assert response.data['status'] == 403

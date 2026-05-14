"""Canonical-envelope exception class for chatbot views.

Modeled on ``bookings.exceptions.BookingValidationError``. The custom DRF
exception handler at ``core.common.failures.exception`` matches on this
class and emits the project's ``{status, code, message, errors}``
envelope without flattening ``code`` into the generic "validation_error"
the way DRF's default flow does.

Views translate service-layer exceptions (NotEligibleToStart,
ConversationNotFound, QuotaExceeded, UnsupportedMessageKind) into a
``ChatbotError`` with the appropriate code + status code, then let DRF
+ the exception handler render the envelope.
"""
from __future__ import annotations

from rest_framework import status as drf_status
from rest_framework.exceptions import APIException


class ChatbotError(APIException):
    """Raised by chatbot views to produce the canonical error envelope.

    Always pass ``code`` (one of the ``ERROR_*`` constants below) and a
    user-facing ``message``. Pass ``errors={'field': ['detail']}`` for
    per-field validation messages; leave it empty for top-level errors.
    """

    status_code = drf_status.HTTP_400_BAD_REQUEST
    default_detail = "Chatbot operation failed."
    default_code = "chatbot_error"

    def __init__(
        self,
        *,
        code: str,
        message: str,
        errors: dict | None = None,
        status: int = drf_status.HTTP_400_BAD_REQUEST,
    ):
        self.status_code = status
        self.code = code
        self.message = message
        self.errors = errors or {}
        # APIException expects ``detail``. Mirrors BookingValidationError's
        # pattern so DRF logs are readable even if the handler chain
        # doesn't reach our custom branch.
        super().__init__(detail=message, code=code)


# Stable wire-strings for the ``code`` field. Frontend keys off these
# literals to branch UI logic — do NOT rename without a coordinated
# frontend change.
ERROR_PERSONA_NOT_FOUND = "persona_not_found"
ERROR_NOT_ELIGIBLE_TO_START = "not_eligible_to_start"
ERROR_CONVERSATION_NOT_FOUND = "conversation_not_found"
ERROR_CONVERSATION_CLOSED = "conversation_closed"
ERROR_UNSUPPORTED_MESSAGE_KIND = "unsupported_message_kind"
ERROR_LLM_QUOTA_EXCEEDED = "llm_quota_exceeded"
ERROR_ATTACHMENT_TOO_LARGE = "attachment_too_large"
ERROR_ATTACHMENT_COUNT_EXCEEDED = "attachment_count_exceeded"

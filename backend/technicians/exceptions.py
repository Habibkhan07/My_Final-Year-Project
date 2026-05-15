"""Canonical-envelope exception classes for technician operations.

Mirrors the pattern in ``wallet.exceptions`` / ``bookings.exceptions`` /
``chatbot.exceptions``. The custom DRF exception handler at
``core.common.failures.exception`` matches on these classes and emits the
project's ``{status, code, message, errors}`` envelope without DRF flattening
``code`` to the generic ``"validation_error"``.
"""
from __future__ import annotations

from rest_framework import status as drf_status
from rest_framework.exceptions import APIException


class DuplicateActiveApplicationError(APIException):
    """Raised when a user finalizes onboarding while they already have an
    in-flight (``PENDING``) or accepted (``APPROVED``) technician profile.

    Re-applying after ``REJECTED`` is allowed and handled by the service —
    that path resets the existing row in place. This exception fires only
    for ``PENDING`` / ``APPROVED`` because:

    * ``PENDING`` — admin already has a queued decision; a second submit
      would race the review and produce two histories of the same person.
    * ``APPROVED`` — the user is a working technician; "applying again"
      has no defined product meaning.

    Status 409 (Conflict) — request well-formed, server state forbids it.
    """

    status_code = drf_status.HTTP_409_CONFLICT
    default_code = "duplicate_application"
    default_detail = "You already have an active technician application."

    def __init__(self, *, current_status: str):
        self.code = "duplicate_application"
        self.message = (
            "You already have an active technician application."
            if current_status == "PENDING"
            else "You are already an approved technician."
        )
        # Named ``application_status`` (not ``status``) to avoid colliding
        # with the envelope's top-level ``status`` field — both would
        # otherwise read as "the status" in error-log scans, and the wire
        # consumer (Flutter ``_mapFailures``) needs an unambiguous key
        # to pick the message and CTA from.
        self.errors = {
            "application_status": [current_status],
        }
        super().__init__(detail=self.message, code=self.code)

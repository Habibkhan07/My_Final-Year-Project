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


class DuplicateSkillError(APIException):
    """Raised when a tech tries to add a sub-service they already hold.

    The bridge table has a ``unique_together`` index on
    ``(technician, sub_service)`` so the DB would catch a duplicate
    write anyway — this exception exists to translate that race into
    a typed 409 with a wire-stable ``code`` for the Flutter mapper,
    instead of leaking an ``IntegrityError`` as a generic 500.
    """

    status_code = drf_status.HTTP_409_CONFLICT
    default_code = "duplicate_skill"
    default_detail = "You already have this skill."

    def __init__(self, *, sub_service_id: int):
        self.code = "duplicate_skill"
        self.message = "You already have this skill."
        # Keyed by ``sub_service_id`` so the Flutter mapper can use the
        # value to decide which row to highlight on the add screen. Wrapped
        # in a list to match the standard envelope's ``errors`` shape.
        self.errors = {"sub_service_id": [str(sub_service_id)]}
        super().__init__(detail=self.message, code=self.code)


class ServiceCategoryNotAllowedError(APIException):
    """Raised when a tech tries to add a sub-service whose PARENT
    service is not in the set of categories they opted into at
    onboarding.

    Anchored on ``TechnicianServiceLicense`` row existence. Onboarding
    finalize auto-creates one row per parent service the tech picked
    skills under, so every approved tech has a non-empty license set.
    The picture field is optional; the ROW is the gate.

    Message copy is intentionally neutral — it states the rule without
    promising a self-serve "request a new category" flow that the
    platform does not yet implement.

    Status 403 (Forbidden) — request well-formed and authorized, but
    the tech did not opt into this category at registration.
    """

    status_code = drf_status.HTTP_403_FORBIDDEN
    default_code = "category_not_allowed"
    default_detail = (
        "You can only add specialties within categories you opted "
        "into at onboarding."
    )

    def __init__(self, *, service_name: str):
        self.code = "category_not_allowed"
        self.message = (
            f"{service_name} is not in the categories you chose at "
            "onboarding."
        )
        # The FE pulls ``service_name`` from this map for the snackbar
        # copy. Wrapped in a list to match the standard envelope shape.
        self.errors = {"service_name": [service_name]}
        super().__init__(detail=self.message, code=self.code)


class LastSkillRequiredError(APIException):
    """Raised when removing a skill would drop the tech to zero skills.

    A tech with zero skills is invisible to the matchmaker — the
    bounding-box query joins through ``skills``, so a no-skill row is
    silently excluded from every dispatch. Forcing a minimum of one
    skill means the tech must add a replacement before dropping their
    last specialty, so the "I have no jobs, why?" state never has a
    silent cause.

    Status 400 (Bad Request) — request well-formed, server-side rule
    rejects it. Matches the envelope used by other typed validation
    failures (``InsufficientFundsError``, etc.).
    """

    status_code = drf_status.HTTP_400_BAD_REQUEST
    default_code = "last_skill_required"
    default_detail = (
        "You must keep at least one skill. "
        "Add a new skill before removing this one."
    )

    def __init__(self):
        self.code = "last_skill_required"
        self.message = (
            "You must keep at least one skill. "
            "Add a new skill before removing this one."
        )
        # No field-level errors; the constraint is on the *operation*,
        # not on any one input field. The standard envelope still
        # requires the ``errors`` key, so it's an empty dict.
        self.errors = {}
        super().__init__(detail=self.message, code=self.code)


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

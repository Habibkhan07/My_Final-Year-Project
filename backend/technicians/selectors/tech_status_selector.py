"""Status selector for the logged-in user's TechnicianProfile.

This is the data source the Flutter router uses on every cold start to decide
where to land a freshly-authenticated user: customer home, pending-approval
holding screen, rejected screen, or technician dashboard. It deliberately
returns a flat dict (not a model instance) so the view layer stays a one-liner
and the contract is observable in one place.
"""
from typing import Optional

from django.contrib.auth.models import User

from technicians.models import TechnicianProfile


def get_my_tech_status(*, user: User) -> dict:
    """Return the current user's technician application status.

    Why a `has_profile` flag rather than null: the router needs three distinct
    cases (no profile / pending / approved / rejected) and a single nullable
    field would collapse "never applied" into "applied but no status yet",
    which the UI would have to disambiguate again.

    No N+1: one indexed lookup on the OneToOne reverse accessor.
    """
    try:
        profile: TechnicianProfile = (
            TechnicianProfile.objects
            .only('status', 'rejection_reason')
            .get(user=user)
        )
    except TechnicianProfile.DoesNotExist:
        return {
            "has_profile": False,
            "status": None,
            "status_display": None,
            "rejection_reason": None,
            "submitted_at": None,
        }

    # `rejection_reason` is only surfaced when status is REJECTED. For all
    # other states we send null so the Flutter screen can rely on the field
    # presence as the "show reason block" signal.
    #
    # No `or None` fallback: the
    # ``technicianprofile_rejected_requires_reason`` CheckConstraint
    # guarantees that REJECTED rows always carry a non-empty reason, so
    # the empty-string case is unreachable.
    rejection_reason: Optional[str] = (
        profile.rejection_reason if profile.status == 'REJECTED' else None
    )

    # `submitted_at` is reserved on the wire now so the Flutter contract
    # doesn't break when we add the column to the model.
    return {
        "has_profile": True,
        "status": profile.status,                  # PENDING / APPROVED / REJECTED
        "status_display": profile.get_status_display(),
        "rejection_reason": rejection_reason,
        "submitted_at": None,
    }

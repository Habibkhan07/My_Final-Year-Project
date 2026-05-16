from ..models import User # Django's default User [cite: 229]

def get_user_by_phone(*, phone: str):
    """Fetches user by username (phone). [cite: 230]"""
    return User.objects.filter(username=phone).first()

def is_profile_incomplete(*, user) -> bool:
    """Read Logic: Checks if first/last names are missing. [cite: 220]"""
    return not (bool(user.first_name) and bool(user.last_name))


def get_me(*, user):
    """
    Returns the caller's User row with `userprofile` pre-joined so the
    `MeOutputSerializer` (which reads `userprofile.phone` /
    `userprofile.is_technician`) does not trigger a second query.

    Mandatory `select_related` per the no-N+1 rule on selectors.
    """
    return User.objects.select_related('userprofile').get(pk=user.pk)
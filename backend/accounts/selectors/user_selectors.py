from ..models import User # Django's default User [cite: 229]

def get_user_by_phone(*, phone: str):
    """Fetches user by username (phone). [cite: 230]"""
    return User.objects.filter(username=phone).first() 

def is_profile_incomplete(*, user) -> bool:
    """Read Logic: Checks if first/last names are missing. [cite: 220]"""
    return not (bool(user.first_name) and bool(user.last_name)) 
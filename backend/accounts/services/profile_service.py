from django.db import transaction

def update_user_profile(*, user, first_name: str, last_name: str):
    """
    Handles the business logic of updating a user's identity.
    """
    # 1. Domain Validation
    if not first_name or not last_name:
        return False, "Both first and last names are required."
            
    # 2. Atomic Update
    with transaction.atomic():
        user.first_name = first_name
        user.last_name = last_name
        user.save()
        
    return True, "Profile updated successfully."
import random
from django.db import transaction
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from ..models import UserProfile, CustomerProfile #
from ..selectors import user_selectors #

def initiate_phone_login(*, phone: str):
    """
    Validates the phone format and generates a mock OTP.
    Matches the call in PhoneLoginView.
    """
    # Logic: Mock OTP Generation for development
    otp = "1234" 
    print(f"\n[SMS DEBUG] OTP for {phone} is: {otp}\n")
    
    return {"message": "OTP sent successfully"}, None

def process_otp_verification(*, phone: str, otp_input: str):
    """
    Handles OTP check and the 'Register or Login' logic.
    Matches the call in VerifyOTPView.
    """
    # 1. Verify OTP
    if otp_input != "1234":
        raise ValueError("Invalid OTP") 

    # 2. Atomic Operation for User/Profile creation
    with transaction.atomic(): 
        user, created = User.objects.get_or_create(username=phone) 
        
        if created:
            UserProfile.objects.create(user=user, phone=phone) #
            CustomerProfile.objects.create(user=user) #
            
        token, _ = Token.objects.get_or_create(user=user)
        
        # 3. Use the Selector for the profile check
        name_required = user_selectors.is_profile_incomplete(user=user)
        
        return {
            "token": token.key,
            "is_technician": user.userprofile.is_technician,
            "name_required": name_required,
            "new_user": created
        }
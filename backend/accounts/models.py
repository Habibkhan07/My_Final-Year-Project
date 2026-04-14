from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta

# Create your models here.


# 1. This is the "Base" profile for everyone. 
# It holds info that both Customers and Techs need.
class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone = models.CharField(max_length=15, unique=True)
    # This acts as the "Switch" for your Flutter logic
    is_technician = models.BooleanField(default=False)

    def __str__(self):
        return self.user.username


OTP_EXPIRY_SECONDS = 30


class OTPRecord(models.Model):
    """
    Stores a single-use OTP per phone number.
    Verified in process_otp_verification and marked used atomically.
    """
    phone = models.CharField(max_length=15)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    def save(self, *args, **kwargs):
        if not self.pk:
            self.expires_at = timezone.now() + timedelta(seconds=OTP_EXPIRY_SECONDS)
        super().save(*args, **kwargs)

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at

    def __str__(self):
        return f"OTP({self.phone}, used={self.is_used})"
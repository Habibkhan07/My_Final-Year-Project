from django.db import models
from django.contrib.auth.models import User

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

# 2. This holds info ONLY for the Customer role.
class CustomerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
   # address = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Customer: {self.user.username}"



class SavedAddress(models.Model):
    # This links the address to a specific User
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='addresses')
    
    # Label helps the user identify the spot (e.g., "Home", "Office")
    label = models.CharField(max_length=50, default="Home") 
    
    # Live Location data
    latitude = models.DecimalField(max_digits=22, decimal_places=16)
    longitude = models.DecimalField(max_digits=22, decimal_places=16)
    address_text = models.TextField() # The human-readable version

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.label}"
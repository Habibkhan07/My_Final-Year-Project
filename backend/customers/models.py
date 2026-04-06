# customer/models.py
from django.db import models
from django.conf import settings

# 1. This holds info ONLY for the Customer role.
class CustomerProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE,
        related_name='customer_profile'
    )
    # Add any extra customer fields here later (e.g., phone_number)

    def __str__(self):
        return f"Customer: {self.user.username}"


class SavedAddress(models.Model):
    customer = models.ForeignKey(
        CustomerProfile, 
        on_delete=models.CASCADE, 
        related_name='addresses'
    )
    
    label = models.CharField(max_length=50, default="Home") 
    
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    
    address_text = models.TextField() 
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.customer.user.username} - {self.label}"
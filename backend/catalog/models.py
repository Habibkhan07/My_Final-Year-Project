from django.db import models

# Create your models here.
class Service(models.Model):
    """Top-level category (e.g., AC Service, Plumbing)"""
    name = models.CharField(max_length=100)
    icon_name = models.CharField(max_length=50, null=True, blank=True)
    display_order = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    base_inspection_fee = models.DecimalField(max_digits=6, decimal_places=2, default=500.00)
    # Duration of a standard inspection/job for this service category (minutes).
    # Used for availability slot generation when no specific sub-service is requested.
    default_duration_minutes = models.PositiveIntegerField(default=60)

    def __str__(self):
        return self.name
    


class SubService(models.Model):
    """Specific task (e.g., Gas Refill)"""
    service = models.ForeignKey(Service, on_delete=models.CASCADE, related_name='sub_services')
    name = models.CharField(max_length=100)
    
    # Standardized pricing metadata
    base_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    max_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    # NEW: The 'Phase 2 Bypass' flags
    is_fixed_price = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    
    # NEW: The Intelligence Layer
    # This stores your synonyms like ["bijli", "drip", "leak"]
    search_tags = models.JSONField(default=list, blank=True)

    icon_name = models.CharField(max_length=50, null=True, blank=True)
    card_image_url = models.URLField(null=True, blank=True)  # Lifestyle photo for fixed gig cards on home screen
    # Estimated job duration for this specific gig (minutes).
    # Null = inherit from parent Service.default_duration_minutes.
    estimated_duration_minutes = models.PositiveIntegerField(null=True, blank=True)

    def __str__(self):
        return f"{self.service.name} -> {self.name}"
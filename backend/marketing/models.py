# marketing/models.py
from django.db import models

class Promotion(models.Model):
    # Modern Django Enums (Classes instead of lists)
    class DiscountType(models.TextChoices):
        PERCENTAGE = 'PERCENTAGE', 'Percentage (%)'
        FIXED = 'FIXED', 'Fixed Amount (Rs.)'

    class FundingSource(models.TextChoices):
        PLATFORM = 'PLATFORM', 'Platform-Funded'
    
        TECHNICIAN = 'TECHNICIAN', 'Technician-Funded'

    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    
    # Using the classes for the choices
    discount_type = models.CharField(
        max_length=15, 
        choices=DiscountType.choices, 
        default=DiscountType.FIXED
    )
    discount_value = models.DecimalField(max_digits=10, decimal_places=2) 
    
    target_service = models.ForeignKey(
        'catalog.Service', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    
    funded_by = models.CharField(
        max_length=20, 
        choices=FundingSource.choices, 
        default=FundingSource.PLATFORM
    )
    
    image = models.ImageField(upload_to='promo_banners/') 
    valid_from = models.DateTimeField()
    valid_until = models.DateTimeField()
    is_active = models.BooleanField(default=True)
    is_featured_on_home = models.BooleanField(default=True)

    @property
    def ui_description(self):
        """
        Dumb UI Logic: Focuses strictly on the Final Bill Discount.
        The inspection fee is never discounted; only the total work bill.
        """
        if self.description:
            return self.description
            
        target_name = self.target_service.name if self.target_service else "the service"
        
        if self.discount_type == self.DiscountType.PERCENTAGE:
            return f"Get {int(self.discount_value)}% OFF the total bill for {target_name}!"
        else:
            return f"Get Rs. {int(self.discount_value)} OFF your final {target_name} bill!"

    def __str__(self):
        return f"{self.name} - {self.discount_value} ({self.discount_type})"
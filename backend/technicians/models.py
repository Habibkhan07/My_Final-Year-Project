from django.db import models
from django.conf import settings
import uuid


class TemporaryMedia(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    file = models.ImageField(upload_to='temp_uploads/') # Temporary folder
    uploaded_at = models.DateTimeField(auto_now_add=True)



class Service(models.Model):
    """Top-level category (e.g., AC Service, Plumbing)"""
    name = models.CharField(max_length=100)
    
    def __str__(self):
        return self.name
    


class SubService(models.Model):
    """Specific task (e.g., Gas Refill)"""
    service = models.ForeignKey(Service, on_delete=models.CASCADE, related_name='sub_services')
    name = models.CharField(max_length=100)
    
    # Standardized pricing metadata
    base_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    max_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return f"{self.service.name} -> {self.name}"

class TechnicianProfile(models.Model):
    """The core professional profile for Sprint 2"""
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='tech_profile')
    
    # Acceptance Criteria: Selection of primary services via Through Model
    skills = models.ManyToManyField(SubService, through='TechnicianSkill', related_name='technicians')
    
    # Acceptance Criteria: City and CNIC
    CITY_CHOICES = [('LHR', 'Lahore'), ('KHI', 'Karachi'), ('ISL', 'Islamabad')]
    city = models.CharField(max_length=3, choices=CITY_CHOICES)
    cnic_number = models.CharField(max_length=15, unique=True)
    cnic_front_image = models.ImageField(upload_to='tech_docs/cnic/')
    
    # Acceptance Criteria: Profile Metadata
    experience_years = models.PositiveIntegerField(default=0)
    bio = models.TextField(help_text="Details about qualifications and expertise.")
    profile_picture = models.ImageField(upload_to='tech_profiles/')
    
    # Acceptance Criteria: Approval Status
    STATUS_CHOICES = [('PENDING', 'Pending Approval'), ('APPROVED', 'Approved'), ('REJECTED', 'Rejected')]
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING')

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.status}"

class TechnicianSkill(models.Model):
    """Custom Junction Table for Skill-Specific Licenses"""
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE)
    sub_service = models.ForeignKey(SubService, on_delete=models.CASCADE)
    
    # Added detail for specialized verification
    years_of_experience = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = ('technician', 'sub_service')

# NEW TABLE: Maps a single license to a parent Service (e.g., Plumbing)
class TechnicianServiceLicense(models.Model):
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE, related_name="service_licenses")
    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    license_picture = models.ImageField(upload_to='tech_docs/licenses/')
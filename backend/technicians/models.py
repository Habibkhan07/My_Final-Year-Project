from django.db import models
from django.conf import settings
from django.contrib.auth.models import User
import uuid
from catalog.models import Service, SubService # Critical: New Import

class TemporaryMedia(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    file = models.ImageField(upload_to='temp_uploads/') # Temporary folder
    uploaded_at = models.DateTimeField(auto_now_add=True)





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

    base_latitude = models.FloatField(null=True, blank=True)
    base_longitude = models.FloatField(null=True, blank=True)
    max_travel_radius_km = models.IntegerField(default=10)
    is_onboarding_complete = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    # NEW: Ratings Variables (Performance Layer) [cite: 12, 538]
    rating_average = models.DecimalField(max_digits=3, decimal_places=2, default=0.0)
    review_count = models.IntegerField(default=0)
    
    def __str__(self):
        return f"{self.user.get_full_name()} - {self.status}"

class TechnicianSkill(models.Model):
    """Custom Junction Table for Skill-Specific Licenses"""
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE)
    sub_service = models.ForeignKey(SubService, on_delete=models.CASCADE)
    
    # Added detail for specialized verification
    years_of_experience = models.PositiveIntegerField(default=0)
    
    # NEW: Technician-specific pricing window for this specific skill/gig
    # Scenario 3: Technician decides their labor within the SubService limits.
    base_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    max_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    class Meta:
        unique_together = ('technician', 'sub_service')

# NEW TABLE: Maps a single license to a parent Service (e.g., Plumbing)
class TechnicianServiceLicense(models.Model):
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE, related_name="service_licenses")
    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    license_picture = models.ImageField(upload_to='tech_docs/licenses/')


# --- MATCHMAKING / PERFORMANCE DOMAIN ---
class TechnicianServicePerformance(models.Model):
    """Strictly handles the variables needed for the Bayesian Matchmaking Algorithm."""
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE, related_name="service_performances")
    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    
    # The Bayesian Math Variables
    review_count = models.IntegerField(default=0)            # The 'v' variable
    rating_average = models.FloatField(default=0.0)          # The 'R' variable

    class Meta:
        unique_together = ('technician', 'service')

    def __str__(self):
        return f"{self.technician.user.get_full_name()} - {self.service.name} Performance"


class TechnicianSchedule(models.Model):
    """
    Defines a technician's working hours for a specific day of the week.
    A missing record for a given day_of_week means the technician does not work that day.
    """
    DAY_CHOICES = [
        (0, 'Monday'), (1, 'Tuesday'), (2, 'Wednesday'),
        (3, 'Thursday'), (4, 'Friday'), (5, 'Saturday'), (6, 'Sunday'),
    ]
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE, related_name='schedule')
    day_of_week = models.IntegerField(choices=DAY_CHOICES)  # 0=Monday, 6=Sunday (matches Python's date.weekday())
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_working = models.BooleanField(default=True)

    class Meta:
        unique_together = ('technician', 'day_of_week')

    def __str__(self):
        return f"{self.technician.user.get_full_name()} - {self.get_day_of_week_display()} ({self.start_time}–{self.end_time})"


class Review(models.Model):
    """Customer review left after a completed job."""
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE, related_name='reviews')
    reviewer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='given_reviews')
    rating = models.PositiveSmallIntegerField()   # 1–5
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        reviewer_name = self.reviewer.get_full_name() if self.reviewer else "Deleted User"
        return f"Review by {reviewer_name} for {self.technician.user.get_full_name()} ({self.rating}★)"
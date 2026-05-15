from django.core.exceptions import ValidationError
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
    # Indexed because matchmaking, dispatch, and the wallet-active gate all
    # filter on ``status='APPROVED'`` on every booking write — a full scan
    # on a low-cardinality column scales poorly as the tech base grows.
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING', db_index=True)

    # Admin-authored reason surfaced on the rejected holding screen. Only
    # meaningful when status == 'REJECTED' — left blank otherwise. Free-text
    # so the admin can phrase it however the case demands; the tech sees it
    # verbatim, so admins should write it with that audience in mind.
    rejection_reason = models.TextField(blank=True, default='')

    base_latitude = models.FloatField(null=True, blank=True)
    base_longitude = models.FloatField(null=True, blank=True)
    max_travel_radius_km = models.IntegerField(default=10)
    is_onboarding_complete = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    # NEW: Ratings Variables (Performance Layer) [cite: 12, 538]
    rating_average = models.DecimalField(max_digits=3, decimal_places=2, default=0.0)
    review_count = models.IntegerField(default=0)
    
    # NEW: Technician Dashboard state
    current_wallet_balance = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    is_online = models.BooleanField(default=False)
    
    class Meta:
        # Invariant: a REJECTED profile must carry a non-empty reason.
        # Backed at both layers — model ``clean()`` runs in the admin and
        # surfaces a field-level error, the DB CheckConstraint catches any
        # write path that bypasses ``full_clean`` (raw SQL, ``QuerySet.update``,
        # data migrations). The ~Q-OR formulation means PENDING/APPROVED
        # rows with empty reason are accepted; only REJECTED+empty is refused.
        # MySQL ≥ 8.0.16 enforces this; the project's local DB is 8.0.45.
        constraints = [
            models.CheckConstraint(
                name='technicianprofile_rejected_requires_reason',
                condition=(
                    ~models.Q(status='REJECTED')
                    | ~models.Q(rejection_reason='')
                ),
            ),
        ]

    def clean(self):
        """Invariant: a REJECTED profile must carry a non-empty reason.

        Model-level mirror of the DB CheckConstraint above. ``clean()``
        rejects whitespace-only reasons too — the DB constraint only catches
        the literal empty string, but a reason that renders as a blank block
        on the tech's holding screen is equally useless.
        """
        super().clean()
        if self.status == 'REJECTED' and not (self.rejection_reason or '').strip():
            raise ValidationError({
                'rejection_reason': 'A rejection reason is required when status is REJECTED.',
            })

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.status}"

class TechnicianSkill(models.Model):
    """Custom Junction Table for Skill-Specific Licenses"""
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE)
    sub_service = models.ForeignKey(SubService, on_delete=models.CASCADE)
    
    # Added detail for specialized verification
    years_of_experience = models.PositiveIntegerField(default=0)
    
    # Technician's labor rate for this skill (Scenario B labor gigs).
    # Single value; the booking write path enforces exact equality.
    labor_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

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
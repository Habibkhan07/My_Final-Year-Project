from django.db import models
from django.conf import settings


class CustomerProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='customer_profile'
    )

    def __str__(self):
        return f"Customer: {self.user.username}"


class CustomerAddress(models.Model):
    customer = models.ForeignKey(
        CustomerProfile,
        on_delete=models.CASCADE,
        related_name='addresses'
    )
    label = models.CharField(max_length=50, default='Home')
    street_address = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    # Client-supplied structured locality fields. The Flutter map-picker
    # reverse-geocodes (Google in prod, OSM Nominatim in dev) and POSTs these
    # alongside lat/lng. Backend stores verbatim; lat/lng remains the trusted
    # source for distance/matchmaking.
    neighborhood = models.CharField(max_length=120, null=True, blank=True)
    suburb = models.CharField(max_length=120, null=True, blank=True)
    city = models.CharField(max_length=120, null=True, blank=True)
    state = models.CharField(max_length=120, null=True, blank=True)
    country = models.CharField(max_length=8, null=True, blank=True)  # ISO-3166 alpha-2 e.g. "PK"
    postal_code = models.CharField(max_length=20, null=True, blank=True)
    locality_label = models.CharField(max_length=200, null=True, blank=True)

    class Meta:
        ordering = ['-is_default', '-id']

    def __str__(self):
        return f"{self.customer.user.username} - {self.label}"
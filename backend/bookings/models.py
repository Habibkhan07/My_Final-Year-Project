from django.db import models
from django.conf import settings
from technicians.models import TechnicianProfile


class JobBooking(models.Model):
    """
    Represents a customer's booking of a technician for a specific time window.
    scheduled_start and scheduled_end drive the conflict filter in the availability selector.

    price_context is a short display label for the UI receipt (e.g. "AC Repair — 2 hrs").
    address is SET_NULL so deleted addresses don't cascade-delete booking history.
    """
    STATUS_PENDING = 'PENDING'
    STATUS_CONFIRMED = 'CONFIRMED'
    STATUS_COMPLETED = 'COMPLETED'
    STATUS_CANCELLED = 'CANCELLED'
    STATUS_REJECTED = 'REJECTED'

    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_CONFIRMED, 'Confirmed'),
        (STATUS_COMPLETED, 'Completed'),
        (STATUS_CANCELLED, 'Cancelled'),
        (STATUS_REJECTED, 'Rejected'),
    ]

    # SECURITY: customer FK ensures bookings are always owned by a real user account
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE, related_name='bookings')
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='bookings')
    # String reference avoids circular import (customers ↔ bookings)
    address = models.ForeignKey(
        'customers.SavedAddress',
        on_delete=models.SET_NULL,
        null=True,
        related_name='bookings',
    )
    scheduled_start = models.DateTimeField()
    scheduled_end = models.DateTimeField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_PENDING)
    price_amount = models.DecimalField(max_digits=10, decimal_places=2)
    price_context = models.CharField(max_length=50, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['technician', 'scheduled_start']),
        ]
        ordering = ['scheduled_start']

    def __str__(self):
        return f"Booking({self.technician.user.get_full_name()}, {self.scheduled_start:%Y-%m-%d %H:%M}, {self.status})"

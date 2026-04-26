from __future__ import annotations

import uuid
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone


class EventLogManager(models.Manager["EventLog"]):
    """Read-side convenience queries exposed to selectors."""

    #: Window for "pending action" screens on cold start. Events older than
    #: this are considered stale and not surfaced as unacknowledged prompts.
    UNACKNOWLEDGED_WINDOW = timedelta(hours=24)

    def unacknowledged_critical(self, user) -> models.QuerySet["EventLog"]:
        """
        Critical events for ``user`` that were never ACK'd and are still
        inside the 24-hour recovery window.
        """
        cutoff = timezone.now() - self.UNACKNOWLEDGED_WINDOW
        return (
            self.get_queryset()
            .filter(
                user=user,
                is_critical=True,
                acknowledged_at__isnull=True,
                created_at__gte=cutoff,
            )
            .order_by("created_at")
        )


class EventLog(models.Model):
    TARGET_CUSTOMER = "customer"
    TARGET_TECHNICIAN = "technician"
    TARGET_ROLE_CHOICES = (
        (TARGET_CUSTOMER, "Customer"),
        (TARGET_TECHNICIAN, "Technician"),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="event_logs",
    )
    event_type = models.CharField(max_length=100)
    target_role = models.CharField(max_length=16, choices=TARGET_ROLE_CHOICES)
    payload = models.JSONField()
    is_critical = models.BooleanField(default=False)
    acknowledged_at = models.DateTimeField(null=True, blank=True, default=None)
    created_at = models.DateTimeField(auto_now_add=True)

    objects = EventLogManager()

    class Meta:
        app_label = "realtime"
        db_table = "core_eventlog"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["user", "created_at"], name="evlog_user_created_idx"),
            models.Index(
                fields=["user", "is_critical", "acknowledged_at"],
                name="evlog_user_crit_ack_idx",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.event_type} → user={self.user_id} ({self.id})"

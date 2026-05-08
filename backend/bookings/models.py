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
    # Pre-orchestrator status set. PENDING is legacy (pre-migration 0007) and
    # never produced or consumed by current code paths; kept in CHOICES so
    # existing rows still validate. New bookings default to AWAITING.
    STATUS_PENDING = 'PENDING'
    STATUS_AWAITING_TECH_ACCEPT = 'AWAITING'
    STATUS_CONFIRMED = 'CONFIRMED'
    STATUS_COMPLETED = 'COMPLETED'
    STATUS_CANCELLED = 'CANCELLED'
    STATUS_REJECTED = 'REJECTED'

    # Booking orchestrator v1 (sprint 0008). Each value is a distinct phase
    # in the post-CONFIRMED lifecycle. Transitions live in
    # bookings/services/orchestrator.py — never mutate ``status`` from a view.
    STATUS_EN_ROUTE = 'EN_ROUTE'
    STATUS_ARRIVED = 'ARRIVED'
    STATUS_INSPECTING = 'INSPECTING'
    STATUS_QUOTED = 'QUOTED'
    STATUS_IN_PROGRESS = 'IN_PROGRESS'
    STATUS_COMPLETED_INSPECTION_ONLY = 'COMPLETED_INSPECTION_ONLY'
    STATUS_NO_SHOW = 'NO_SHOW'
    STATUS_DISPUTED = 'DISPUTED'

    STATUS_CHOICES = [
        (STATUS_AWAITING_TECH_ACCEPT, 'Awaiting tech accept'),
        (STATUS_CONFIRMED, 'Confirmed'),
        (STATUS_EN_ROUTE, 'En route'),
        (STATUS_ARRIVED, 'Arrived'),
        (STATUS_INSPECTING, 'Inspecting'),
        (STATUS_QUOTED, 'Quoted'),
        (STATUS_IN_PROGRESS, 'In progress'),
        (STATUS_COMPLETED, 'Completed'),
        (STATUS_COMPLETED_INSPECTION_ONLY, 'Completed (inspection only)'),
        (STATUS_CANCELLED, 'Cancelled'),
        (STATUS_REJECTED, 'Rejected'),
        (STATUS_NO_SHOW, 'No show'),
        (STATUS_DISPUTED, 'Disputed'),
        (STATUS_PENDING, 'Pending (legacy, do not use for new bookings)'),
    ]

    # Status-set helpers consumed by orchestrator and selectors. Frozensets
    # so accidental mutation is impossible at runtime.
    TERMINAL_STATUSES = frozenset({
        STATUS_COMPLETED,
        STATUS_COMPLETED_INSPECTION_ONLY,
        STATUS_CANCELLED,
        STATUS_REJECTED,
        STATUS_NO_SHOW,
        STATUS_DISPUTED,
    })

    POST_ARRIVAL_STATUSES = frozenset({
        STATUS_ARRIVED,
        STATUS_INSPECTING,
        STATUS_QUOTED,
        STATUS_IN_PROGRESS,
    })

    # SECURITY: customer FK ensures bookings are always owned by a real user account
    technician = models.ForeignKey(TechnicianProfile, on_delete=models.CASCADE, related_name='bookings')
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='bookings')
    # String reference avoids circular import (customers ↔ bookings)
    address = models.ForeignKey(
        'customers.CustomerAddress',
        on_delete=models.SET_NULL,
        null=True,
        related_name='bookings',
    )

    # Catalog references — capture customer's discovery intent at booking time.
    # service is required (every booking has a parent category). sub_service
    # is set only for Scenario A (fixed gig) and B (labor gig). promotion is
    # set only when the customer arrived via a promo banner; the resolver's
    # firewall strips it on fixed gigs (no discount stacking).
    # PROTECT on catalog deletes — historical bookings preserve intent; if a
    # Service must be removed, deactivate (is_active=False) rather than delete.
    service = models.ForeignKey(
        'catalog.Service',
        on_delete=models.PROTECT,
        related_name='bookings',
    )
    sub_service = models.ForeignKey(
        'catalog.SubService',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='bookings',
    )
    promotion = models.ForeignKey(
        'marketing.Promotion',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='bookings',
    )

    scheduled_start = models.DateTimeField()
    scheduled_end = models.DateTimeField()
    # max_length=32 fits the longest value (COMPLETED_INSPECTION_ONLY = 26).
    # default flipped from PENDING (legacy) to AWAITING — every new booking
    # is awaiting tech accept at creation time.
    status = models.CharField(
        max_length=32,
        choices=STATUS_CHOICES,
        default=STATUS_AWAITING_TECH_ACCEPT,
    )
    price_amount = models.DecimalField(max_digits=10, decimal_places=2)
    price_context = models.CharField(max_length=50, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    # ---------------------------------------------------------------
    # Booking orchestrator v1 (sprint 0008) — added columns.
    # All nullable / defaulted so existing rows render correctly without
    # a backfill. The orchestrator stamps these as transitions occur.
    # ---------------------------------------------------------------

    # Phase timestamps. Each is set exactly once at the corresponding
    # transition; once non-null, never rewritten (idempotency guard in
    # orchestrator skips re-stamps).
    accepted_at = models.DateTimeField(null=True, blank=True)
    en_route_started_at = models.DateTimeField(null=True, blank=True)
    arrived_at = models.DateTimeField(null=True, blank=True)
    inspection_started_at = models.DateTimeField(null=True, blank=True)
    quote_first_submitted_at = models.DateTimeField(null=True, blank=True)
    work_started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    # Cash collection (sprint meta §16). final_cash_to_collect is the
    # number the tech sees on the cash button — set at QUOTED→IN_PROGRESS
    # for the regular path, or at QUOTED→COMPLETED_INSPECTION_ONLY (= just
    # the inspection fee) for the decline path.
    final_cash_to_collect = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    cash_collected_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    cash_collected_at = models.DateTimeField(null=True, blank=True)
    cash_collection_method = models.CharField(max_length=16, default='cash')

    # Pricing breakdown — denormalized for the receipt UI; finance sprint
    # will reconcile these against BookingItem rows for commission math.
    inspection_fee = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    base_services_total = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    discount_applied = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    # Promotion snapshot (audit P1-03). The FK above can become NULL if the
    # promo is deleted; these snapshots survive that. Populated at booking
    # creation (instant_book_service) when ``promotion is not None``.
    promo_code_snapshot = models.CharField(max_length=64, null=True, blank=True)
    promo_discount_snapshot = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    # Address snapshot — survives customer-side address deletion (which
    # SET_NULLs the FK above). Frozen at booking creation.
    actual_address_snapshot = models.TextField(blank=True, default='')

    # Reschedule chain (sprint meta §12). On reschedule, the original is
    # CANCELLED and a child booking is created with parent_booking pointing
    # at it. Lineage is informational; never hard-delete a parent.
    parent_booking = models.ForeignKey(
        'self',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='child_bookings',
    )

    # Cancellation audit. cancel_reason values (validated at service layer):
    #   customer_cancelled_pre_accept | customer_cancelled_post_accept
    #   customer_cancelled_post_arrival | customer_rescheduled
    #   technician_cancelled
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancelled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='cancelled_bookings',
    )
    cancel_reason = models.CharField(max_length=64, null=True, blank=True)

    # No-show audit. ``no_show_actor`` is 'tech' | 'customer' (who reported
    # the other party).
    no_show_at = models.DateTimeField(null=True, blank=True)
    no_show_actor = models.CharField(max_length=16, null=True, blank=True)

    # Dispute audit. Stamped at the FIRST SupportTicket; multiple tickets
    # are allowed but the status flip to DISPUTED is one-shot.
    dispute_opened_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=['technician', 'scheduled_start']),
        ]
        ordering = ['scheduled_start']

    def __str__(self):
        return f"Booking({self.technician.user.get_full_name()}, {self.scheduled_start:%Y-%m-%d %H:%M}, {self.status})"


# ===========================================================================
# Booking orchestrator v1 (sprint 0008) — quote, snapshot, dispute, audit.
#
# The Quote/QuoteLineItem/BookingItem trio captures the multi-revision quote
# flow: tech submits a Quote (revision 1, 2, ...); on customer approval, the
# accepted line items are SNAPSHOT into BookingItem rows (the immutable
# source of truth for "what work was performed" — finance reads here).
# Mid-job upsell appends to BookingItem; never deletes prior items.
# ===========================================================================


class Quote(models.Model):
    STATUS_DRAFT = 'DRAFT'
    STATUS_SUBMITTED = 'SUBMITTED'
    STATUS_APPROVED = 'APPROVED'
    STATUS_DECLINED = 'DECLINED'
    STATUS_SUPERSEDED = 'SUPERSEDED'

    STATUS_CHOICES = [
        (STATUS_DRAFT, 'Draft'),
        (STATUS_SUBMITTED, 'Submitted'),
        (STATUS_APPROVED, 'Approved'),
        (STATUS_DECLINED, 'Declined'),
        (STATUS_SUPERSEDED, 'Superseded (replaced by next revision)'),
    ]

    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE, related_name='quotes')
    revision_number = models.PositiveIntegerField()
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_DRAFT)
    # Server-derived; orchestrator recomputes on every line-item mutation.
    # Stored (not computed at read) so admin and analytics can index it.
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    # True when the quote is submitted during IN_PROGRESS (mid-job upsell);
    # the orchestrator handles the from-state difference but the flag also
    # lets the customer-side UI render a different approval card.
    is_upsell = models.BooleanField(default=False)
    decision_reason = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    submitted_at = models.DateTimeField(null=True, blank=True)
    decided_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['booking_id', 'revision_number']
        constraints = [
            models.UniqueConstraint(
                fields=['booking', 'revision_number'],
                name='unique_quote_revision_per_booking',
            ),
            # Belt-and-braces: the orchestrator's submit_quote flow
            # (supersede prior → create new) enforces "at most one
            # SUBMITTED quote per (booking, flavour)" — but only at the
            # application layer. A bug in a future caller (or a concurrent
            # path that bypasses the supersede) could violate this without
            # any DB signal. The partial index makes the invariant
            # database-enforced. Filter on status=SUBMITTED so prior
            # SUPERSEDED / APPROVED / DECLINED rows don't collide with
            # the new one.
            models.UniqueConstraint(
                fields=['booking', 'is_upsell'],
                condition=models.Q(status='SUBMITTED'),
                name='unique_submitted_quote_per_booking_flavour',
            ),
        ]

    def __str__(self):
        return f"Quote #{self.id} (booking {self.booking_id}, rev {self.revision_number}, {self.status})"


class QuoteLineItem(models.Model):
    quote = models.ForeignKey(Quote, on_delete=models.CASCADE, related_name='line_items')
    sub_service = models.ForeignKey('catalog.SubService', on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)
    priced_at = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ['quote_id', 'id']

    def save(self, *args, **kwargs):
        # ``line_total`` is server-derived, never user-controlled — always
        # recompute on save. Defensive against:
        #   * admin / shell sessions that build rows manually
        #   * hypothetical future code paths that miscompute the total
        #   * factory_boy fixtures that pass an unrelated line_total
        # The orchestrator computes line_total upstream too, but pinning
        # it here means a single source of truth (quantity * priced_at)
        # regardless of caller.
        if self.quantity and self.priced_at is not None:
            self.line_total = self.quantity * self.priced_at
        super().save(*args, **kwargs)


class BookingItem(models.Model):
    """Snapshot of accepted line items.

    Populated on Quote APPROVAL — never on Quote SUBMIT. Mid-job upsell
    APPENDS to existing rows; the orchestrator must never delete prior
    BookingItem rows. This is the immutable "what work was performed"
    record that the finance sprint reconciles against.
    """
    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE, related_name='items')
    sub_service = models.ForeignKey('catalog.SubService', on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)
    price_charged = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=10, decimal_places=2)
    sourced_quote = models.ForeignKey(
        Quote,
        null=True,
        on_delete=models.PROTECT,
        related_name='snapshotted_into_items',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['booking_id', 'id']


class SupportTicket(models.Model):
    """Form-intake dispute ticket.

    ``dispute_intake_method`` is a seam: the chatbot intake module (future
    sprint) will write tickets with method=CHATBOT and populate ``chat_log``
    with the conversation. Form intake (this sprint) leaves ``chat_log``
    null. Multiple tickets per booking are allowed; the booking's status
    flip to DISPUTED is one-shot.
    """
    INTAKE_FORM = 'FORM'
    INTAKE_CHATBOT = 'CHATBOT'
    INTAKE_CHOICES = [
        (INTAKE_FORM, 'Form'),
        (INTAKE_CHATBOT, 'Chatbot'),
    ]

    STATUS_OPEN = 'OPEN'
    STATUS_RESOLVED = 'RESOLVED'
    STATUS_CHOICES = [
        (STATUS_OPEN, 'Open'),
        (STATUS_RESOLVED, 'Resolved'),
    ]

    OUTCOME_NONE = 'NONE'
    OUTCOME_REFUND_CUSTOMER = 'REFUND_CUSTOMER'
    OUTCOME_PENALIZE_TECH = 'PENALIZE_TECH'
    OUTCOME_DISMISS = 'DISMISS'
    OUTCOME_CHOICES = [
        (OUTCOME_NONE, 'None'),
        (OUTCOME_REFUND_CUSTOMER, 'Refund customer'),
        (OUTCOME_PENALIZE_TECH, 'Penalize tech'),
        (OUTCOME_DISMISS, 'Dismiss'),
    ]

    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE, related_name='tickets')
    opened_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='opened_tickets',
    )
    dispute_intake_method = models.CharField(max_length=16, choices=INTAKE_CHOICES, default=INTAKE_FORM)
    initial_reason = models.TextField()
    chat_log = models.JSONField(null=True, blank=True)
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_OPEN)
    resolution_outcome = models.CharField(max_length=32, choices=OUTCOME_CHOICES, default=OUTCOME_NONE)
    resolution_notes = models.TextField(blank=True, default='')
    # The admin who resolved the dispute (audit trail; populated by
    # ``orchestrator.admin_resolve_dispute``). PROTECT so deleting an
    # admin user cannot orphan resolution attribution. Nullable for
    # backwards compatibility with rows resolved before this column
    # existed (none in production — pre-launch — but keeps the schema
    # honest for tests that pre-create RESOLVED tickets).
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name='resolved_tickets',
    )
    opened_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-opened_at']


class TicketEvidence(models.Model):
    ticket = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='evidence')
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    image = models.ImageField(upload_to='dispute_evidence/')
    caption = models.TextField(blank=True, default='')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['ticket_id', 'uploaded_at']


class BookingAttachment(models.Model):
    """Reserved schema for booking-lifecycle photos (e.g. before/after, quote
    evidence). No upload UI or admin registration this sprint — the chatbot
    intake feature will be the first writer. Existing tables remain free of
    these rows; the model is here so a future migration doesn't have to
    coordinate with anything else.
    """
    KIND_BEFORE = 'BEFORE'
    KIND_AFTER = 'AFTER'
    KIND_QUOTE = 'QUOTE'
    KIND_OTHER = 'OTHER'
    KIND_CHOICES = [
        (KIND_BEFORE, 'Before'),
        (KIND_AFTER, 'After'),
        (KIND_QUOTE, 'Quote evidence'),
        (KIND_OTHER, 'Other'),
    ]

    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE, related_name='attachments')
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    kind = models.CharField(max_length=16, choices=KIND_CHOICES, default=KIND_OTHER)
    image = models.ImageField(upload_to='booking_attachments/')
    caption = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['booking_id', 'created_at']


class TechReliabilityIncident(models.Model):
    """Admin log of tech reliability events.

    Replaces the v0.9-planned ``tech_reliability_penalty`` realtime event
    (audit P0-08). ``EventLog.target_role`` does not accept ``"admin"``,
    so the broadcast would fail at save. The DB row is the source of
    truth; admin reads via Django Admin. A future "reliability score"
    sprint aggregates over this table; until then it is read-only audit.

    Two incident types in v1:
      - TECH_CANCEL: technician voluntarily cancelled a confirmed (or
        post-arrival) job.
      - TECH_NO_SHOW: customer reported the technician as no-show.

    See flag.md::admin-realtime-channel-deferred for the path to
    re-introducing an admin-targeted realtime channel.
    """
    INCIDENT_TECH_CANCEL = 'TECH_CANCEL'
    INCIDENT_TECH_NO_SHOW = 'TECH_NO_SHOW'
    INCIDENT_CHOICES = [
        (INCIDENT_TECH_CANCEL, 'Tech cancelled job'),
        (INCIDENT_TECH_NO_SHOW, 'Tech reported as no-show by customer'),
    ]

    technician = models.ForeignKey(
        TechnicianProfile,
        on_delete=models.CASCADE,
        related_name='reliability_incidents',
    )
    booking = models.ForeignKey(
        JobBooking,
        on_delete=models.CASCADE,
        related_name='tech_reliability_incidents',
    )
    incident_type = models.CharField(max_length=32, choices=INCIDENT_CHOICES)
    # 'pre_arrival' | 'post_arrival' | '' (unknown). Free-form for now;
    # the future reliability sprint may convert to choices.
    phase = models.CharField(max_length=32, blank=True, default='')
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['technician', '-created_at']),
        ]

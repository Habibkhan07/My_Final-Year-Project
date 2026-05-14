"""Chatbot framework data models.

Persona-agnostic. ``Conversation`` is the durable session — its ``state`` and
``context`` JSON columns are owned by the persona's flow engine; the framework
itself only enforces the lifecycle (start → message* → close). ``Message``
captures the audit trail. ``Attachment`` holds any file the user sent (photos
for dispute v1; voice/docs in later personas). ``DailyLlmCallQuota`` is a
per-user shared budget across all personas.

Persona-specific outputs (e.g. ``DisputeTicket``) live in their own domain
apps and FK back to ``Conversation`` — never the other way around.
"""
from __future__ import annotations

from io import BytesIO

from django.conf import settings
from django.db import models


class Conversation(models.Model):
    """One open chat session for one user with one persona.

    Service-layer rules — not enforced by DB constraints because they vary
    per persona — guarantee at most one open conversation per
    (user, persona, scope). The dispute persona enforces "one per booking"
    by locking the booking row in ``is_eligible_to_start``.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chat_conversations",
    )
    # Registry key, e.g. ``"dispute"``. Resolved by ``chatbot.personas.get``.
    persona_key = models.CharField(max_length=32, db_index=True)

    # Immutable per-session input the caller provided at start
    # (e.g. ``{"booking_id": 42}`` for dispute). Persona owns the schema.
    context = models.JSONField(default=dict)

    # Mutable runtime state managed by the persona's flow engine
    # (e.g. ``{"phase": "UNDERSTAND", "captured_fields": {...}}``).
    # Top-level fields like ``current_phase`` are NOT promoted to columns —
    # admin query patterns for in-progress conversations don't justify it,
    # and promoting would couple Conversation to persona internals.
    state = models.JSONField(default=dict)

    turn_count = models.PositiveIntegerField(default=0)
    is_closed = models.BooleanField(default=False)

    # Populated by ``Persona.on_close`` with handles to whatever side-effect
    # rows the conversation produced (e.g. ``{"dispute_ticket_id": 1284}``).
    # Empty dict for personas that produce no persistent output (e.g. future
    # general Q&A bot).
    output_refs = models.JSONField(default=dict)

    created_at = models.DateTimeField(auto_now_add=True)
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["user", "persona_key", "is_closed"]),
            models.Index(fields=["persona_key", "created_at"]),
        ]

    def __str__(self) -> str:
        return f"<Conversation #{self.pk} {self.persona_key}>"


class Message(models.Model):
    """One turn in a conversation. Append-only audit trail.

    The full text is stored unredacted — admin needs to see what the user
    actually wrote to adjudicate a dispute. Redaction happens at the LLM
    boundary (``content_safety.redact_input``), not at persistence.
    """

    ROLE_USER = "USER"
    ROLE_BOT = "BOT"
    ROLE_SYSTEM = "SYSTEM"
    ROLE_CHOICES = [
        (ROLE_USER, "User"),
        (ROLE_BOT, "Bot"),
        (ROLE_SYSTEM, "System"),
    ]

    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name="messages",
    )
    role = models.CharField(max_length=8, choices=ROLE_CHOICES)
    text = models.TextField(blank=True)

    # Parsed structured-output JSON from the LLM (e.g. ``phase_complete``,
    # ``fields_captured``). Empty dict for USER messages and for BOT
    # messages where the LLM didn't return structured output.
    structured = models.JSONField(default=dict, blank=True)

    # Captured at write time. Lets us replay/audit which phase a message
    # belonged to even if the conversation has since advanced.
    phase = models.CharField(max_length=32, blank=True)

    # Detected language of THIS message (the bot will be instructed to
    # respond in the same language). Empty when not yet detected.
    lang = models.CharField(max_length=8, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        indexes = [models.Index(fields=["conversation", "created_at"])]

    def __str__(self) -> str:
        return f"<Message #{self.pk} {self.role} in conv #{self.conversation_id}>"


class Attachment(models.Model):
    """A file uploaded inside a conversation.

    EXIF/metadata stripping happens on first save (see ``_strip_metadata``).
    Tests that need to bypass the strip set ``self._skip_strip = True``
    before calling save.
    """

    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name="attachments",
    )
    # Linked to the BOT message that requested it, or the USER message that
    # uploaded it. Nullable because attachments can be uploaded before the
    # next turn message exists.
    message = models.ForeignKey(
        Message,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="attachments",
    )
    file = models.FileField(upload_to="chatbot/%Y/%m/")
    mime_type = models.CharField(max_length=64)
    size_bytes = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["conversation", "created_at"])]

    def save(self, *args, **kwargs):
        # Strip EXIF only on first save — re-saving an existing row (e.g.
        # to update the ``message`` FK) must not re-process the file.
        if self._state.adding and not getattr(self, "_skip_strip", False):
            self._strip_metadata()
        super().save(*args, **kwargs)

    def _strip_metadata(self) -> None:
        """Re-encode image without EXIF. Best-effort: non-image files and
        Pillow parse failures pass through unchanged — refusing the upload
        would be worse UX than storing a file with intact metadata, and
        we still won't expose it to the LLM (file bytes never leave the
        bucket toward Gemini in v1)."""
        try:
            from PIL import Image
            from django.core.files.base import ContentFile

            img = Image.open(self.file)
            buf = BytesIO()
            fmt = img.format or "JPEG"
            # Convert mode if format demands it (e.g. RGBA → RGB for JPEG)
            if fmt == "JPEG" and img.mode in ("RGBA", "P"):
                img = img.convert("RGB")
            img.save(buf, format=fmt)
            self.file = ContentFile(buf.getvalue(), name=self.file.name)
        except Exception:
            # Logged by services/quota.py-style structured logger once the
            # chatbot logger lands in task 4. For v1 scaffold, swallow.
            return


class DailyLlmCallQuota(models.Model):
    """Per-user daily LLM call counter, shared across all personas.

    A single shared budget is intentional for v1: when general-bot ships
    and is chatty, we may carve persona-specific sub-budgets, but right
    now over-design would add a join for every quota check.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="daily_llm_quotas",
    )
    date = models.DateField()
    count = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = [("user", "date")]
        indexes = [models.Index(fields=["user", "date"])]

    def __str__(self) -> str:
        return f"<DailyLlmCallQuota user={self.user_id} date={self.date} n={self.count}>"

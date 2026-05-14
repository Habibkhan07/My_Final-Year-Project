"""Factories for chatbot framework models.

Defaults create an OPEN dispute conversation; tests targeting other
personas pass ``persona_key`` and a context dict appropriate to that
persona. ``Attachment`` uses a small Pillow-generated JPEG so the
EXIF-strip pass in ``Attachment.save`` exercises its image branch.
"""
import factory
from django.utils import timezone

from chatbot.models import (
    Attachment,
    Conversation,
    DailyLlmCallQuota,
    Message,
)


class ConversationFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Conversation

    user = factory.SubFactory("tests.factories.accounts.UserFactory")
    persona_key = "dispute"
    context = factory.LazyFunction(lambda: {"booking_id": 0})
    state = factory.LazyFunction(
        lambda: {"phase": "UNDERSTAND", "captured_fields": {}}
    )
    turn_count = 0
    is_closed = False
    output_refs = factory.LazyFunction(dict)


class MessageFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Message

    conversation = factory.SubFactory(ConversationFactory)
    role = Message.ROLE_USER
    text = "Hi"
    phase = "UNDERSTAND"
    lang = "en"


class AttachmentFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Attachment

    conversation = factory.SubFactory(ConversationFactory)
    # Factory-boy generates a small valid JPEG; EXIF strip pass in
    # Attachment.save() will exercise the Pillow branch on insert.
    file = factory.django.ImageField(width=64, height=64, format="JPEG")
    mime_type = "image/jpeg"
    size_bytes = 1024


class DailyLlmCallQuotaFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = DailyLlmCallQuota

    user = factory.SubFactory("tests.factories.accounts.UserFactory")
    date = factory.LazyFunction(lambda: timezone.localdate())
    count = 0

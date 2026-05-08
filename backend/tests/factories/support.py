"""Factories for support-ticket and booking-attachment models.

Lives in its own file because these models are conceptually distinct from
the bookings-lifecycle factories (different write-path, different test
audiences). Importable as ``tests.factories.support.SupportTicketFactory``.
"""

import factory

from bookings.models import BookingAttachment, SupportTicket, TicketEvidence


class SupportTicketFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = SupportTicket

    booking = factory.SubFactory('tests.factories.bookings.JobBookingCompletedFactory')
    opened_by = factory.SubFactory('tests.factories.accounts.UserFactory')
    dispute_intake_method = SupportTicket.INTAKE_FORM
    initial_reason = "Tech didn't fix the leak properly."
    status = SupportTicket.STATUS_OPEN


class TicketEvidenceFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TicketEvidence

    ticket = factory.SubFactory(SupportTicketFactory)
    uploaded_by = factory.SubFactory('tests.factories.accounts.UserFactory')
    image = factory.django.ImageField(width=100, height=100)
    caption = ''


class BookingAttachmentFactory(factory.django.DjangoModelFactory):
    """Schema-only this sprint — included so test_models can exercise the
    DB constraint without going through the (non-existent) admin UI.
    """
    class Meta:
        model = BookingAttachment

    booking = factory.SubFactory('tests.factories.bookings.JobBookingFactory')
    uploaded_by = factory.SubFactory('tests.factories.accounts.UserFactory')
    kind = BookingAttachment.KIND_OTHER
    image = factory.django.ImageField(width=100, height=100)
    caption = ''

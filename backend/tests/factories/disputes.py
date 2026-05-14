"""Factories for the disputes domain app.

Only one model lives here — ``RefundIntent``. The dispute ticket itself
is ``bookings.SupportTicket`` (see ``tests.factories.support``); this
factory wires a refund intent onto a fresh ticket by default.
"""
import factory

from disputes.models import RefundIntent


class RefundIntentFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = RefundIntent

    ticket = factory.SubFactory("tests.factories.support.SupportTicketFactory")
    bank_name = "HBL"
    account_title = "Test Account"
    iban = "PK36HABB0011223344556677"

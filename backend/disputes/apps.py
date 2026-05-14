from django.apps import AppConfig


class DisputesConfig(AppConfig):
    """Customer-vs-technician dispute tickets + refund payout intents.

    Pure domain module — ``DisputeTicket`` and ``RefundIntent`` know nothing
    about LLMs. The chatbot's ``dispute`` persona is what produces tickets
    here, via ``disputes.services.ticket_creation``. RefundIntent rows hold
    bank PII and are restricted to the ``finance_admin`` group in admin.
    """

    name = "disputes"
    default_auto_field = "django.db.models.BigAutoField"

from django.apps import AppConfig

#Comment in app.py
class ChatbotConfig(AppConfig):
    """Pluggable LLM-chat framework.

    Hosts the persona registry. Each persona (currently only ``dispute``) is
    a Python package under ``chatbot.personas/`` that implements the Persona
    Protocol declared in ``chatbot.services.ports``. New personas
    (e.g. ``general``, ``onboarding``) are folder-adds — no edits here.

    The LLM is reached via a single adapter (``chatbot.adapters``) chosen by
    the ``LLM_ADAPTER`` setting, decoupling personas from the model vendor.
    """
    name = "chatbot"
    default_auto_field = "django.db.models.BigAutoField"

    def ready(self):
        # Register shipped personas. Each persona's package owns its
        # plugin record; we register them here (not via per-package
        # AppConfigs) because personas are Python packages — not Django
        # apps — and ChatbotConfig is where the registry lives.
        #
        # Adding a v1.1 persona = one new import + one register() call.
        # No edits to chatbot.core or chatbot.services.
        from chatbot.personas import register
        from chatbot.personas.dispute.persona import DisputePersona
        from chatbot.personas.general.persona import GeneralHelpPersona

        register(DisputePersona())
        register(GeneralHelpPersona())


# This is a comment



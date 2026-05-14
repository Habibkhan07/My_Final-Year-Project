"""LLM adapter factory.

The ``LLM_ADAPTER`` setting picks the concrete adapter. Swap-without-refactor
is the whole point of this seam — personas talk to the ``ConversationalAgent``
Protocol (declared in ``chatbot.services.ports``), never to a vendor SDK.
"""
from __future__ import annotations

from django.conf import settings


class UnknownLlmAdapter(Exception):
    """Raised when settings.LLM_ADAPTER names an adapter we don't ship."""


def get_default_agent():
    """Return the configured ``ConversationalAgent`` instance.

    Lazy-imports the concrete adapter so importing this module never
    pulls a vendor SDK into memory — keeps tests that inject a fake
    agent free of unrelated SDK boot cost.
    """
    key = getattr(settings, "LLM_ADAPTER", "gemini")
    if key == "gemini":
        # Real GeminiAgent lands in task 7. Until then, calling this
        # without injecting a fake will fail loud.
        from chatbot.adapters.gemini import GeminiAgent  # noqa: F401
        return GeminiAgent(
            model_name=settings.GEMINI_MODEL,
            api_key=settings.GEMINI_API_KEY,
        )
    raise UnknownLlmAdapter(key)
